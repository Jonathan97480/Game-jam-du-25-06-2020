-- my-librairie/transition/templateCombatTransition.lua
-- CombatTransition Template — multi-ennemis, transitions de scène,
-- premier draft géré avec overlay_start (plus d'overlay_deckdraft)

--- Gestion du flux de combat (FSM) : overlays, round, ordre des ennemis, fin de combat.
-- Exporte un singleton utilisable directement (Transition) et permet aussi `new(cfg)`.
-- @module my-librairie.transition.templateCombatTransition

----------------------------------------------------------------------
-- Require sécurisé via _safeRequire centralisée
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Dépendances globales (tolère l'absence, via _safeRequire centralisée)
----------------------------------------------------------------------
local SceneManager = rawget(_G, "scene") or _G._safeRequire("my-librairie/core/sceneManager")
local Card         = rawget(_G, "Card") or _G._safeRequire("my-librairie/card-librairie/card")
local Hero         = rawget(_G, "Hero") or _G._safeRequire("my-librairie/entities/player/Hero")
local AI           = rawget(_G, "AI") or
    _G._safeRequire("my-librairie/ai/controller") -- Gestionnaire d'acteurs (ennemis vivants)
local EnemiesMod   = _G.Enemies or _G._safeRequire("my-librairie.entities.Enemy.Enemies")

-- Persistance simple pour flags globaux (draft du premier combat)
local GameFlags    = rawget(_G, "GameFlags") or {}
rawset(_G, "GameFlags", GameFlags)

----------------------------------------------------------------------
-- Configuration par défaut (overlays, timings IA, tie-break)
----------------------------------------------------------------------
local DefaultConfig = {
    overlays           = {
        reward     = "scene.overlay_start.overlay_start",
        initiative = "scene.overlay_initiative.overlay_initiative",
        gameover   = "scene.overlay_gameover.overlay_gameover",
    },
    reward             = { count = 3 },
    enemyTurn          = { minTime = 1.0, timeout = 6.0, endTransition = 0.8 },
    preferVictoryOnTie = true,
}

----------------------------------------------------------------------
-- Utilitaires / Logs
----------------------------------------------------------------------
local function logT(...)
    local gf = rawget(_G, 'globalFunction')
    local parts = {}
    for i = 1, select('#', ...) do parts[i] = tostring(select(i, ...)) end
    local msg = "[CombatFlow] " .. table.concat(parts, " ")
    if gf and gf.log and gf.log.info then gf.log.info(msg) else print(msg) end
end

--- Met à jour le tag de tour global s'il change.
-- @tparam string tag "player" | "Enemy" | "transition"
local function setTour(tag)
    if _G.Tour ~= tag then
        _G.Tour = tag
        logT("Tour ->", tag)
    end
end

--- Re-remplit la ressource "power" d'un acteur à son maximum.
-- @tparam table actor Instance avec champ `state`
-- @tparam string label "player" pour mettre à jour un éventuel HUD
local function refillPower(actor, label)
    if not (actor and actor.state) then return end
    local pmax = actor.state.powerMax or actor.state.power or 3
    actor.state.power = pmax
    if label == "player" and rawget(_G, "hud") and hud.updateLabel then
        hud.updateLabel('energy_text', tostring(pmax))
    end
end

--- Restreint le deck du joueur à 10 cartes max (sécurité).
local function ensurePlayerDeckMax10()
    if not (Card and Card.getDeckByName) then return end
    local deck = Card.getDeckByName("HeroDeck"); if not deck or not deck.cards then return end
    while #deck.cards > 10 do table.remove(deck.cards) end
end

--- Bascule de scène avec transition visuelle si possible, sinon bascule simple.
-- @tparam string target
-- @tparam[opt] table params
-- @tparam[opt] any tScript Script de transition
local function safeSwitchWithTransition(target, params, tScript)
    if not SceneManager then return end
    local ok = pcall(function() SceneManager:switchWithTransition(target, params, { script = tScript }) end)
    if not ok and SceneManager.switch then SceneManager:switch(target, params) end
end

----------------------------------------------------------------------
-- Helpers combat (extraits pour éviter de recréer des closures chaque frame)
----------------------------------------------------------------------
--- Retourne la liste des ennemis vivants.
local function livingEnemies()
    local list = {}
    if EnemiesMod and EnemiesMod.listeEnemies then
        for _, e in ipairs(EnemiesMod.listeEnemies) do
            local alive = (e and e.state and not e.state.dead and (e.state.life or 1) > 0)
            if alive then table.insert(list, e) end
        end
    end
    return list
end

--- Définit l'ennemi courant pour compatibilité (Enemies.curentEnemy).
local function setCurrentEnemy(e)
    if EnemiesMod then
        EnemiesMod.curentEnemy = e
    end
end

----------------------------------------------------------------------
-- Classe / FSM CombatFlow
----------------------------------------------------------------------
local CombatFlow = {}
CombatFlow.__index = CombatFlow

--- Crée un gestionnaire de combat.
-- @tparam[opt] table cfg Configuration (facultative)
-- @treturn CombatFlow
function CombatFlow.new(cfg)
    local self                = setmetatable({}, CombatFlow)
    self.cfg                  = cfg or DefaultConfig
    self.state                = "boot"
    self.timer                = 0
    self.round                = 0

    -- Ordonnancement multi-ennemis
    self.enemyOrder           = {} -- liste d’instances ennemies vivantes
    self.enemyIndex           = 0
    self.enemyStarted         = false
    self.enemyMaxSteps        = 0
    self.enemyActionStartT    = 0

    -- Récompenses
    self.rewardOptions        = nil
    self.rewardChosenIndex    = nil

    -- Flags overlays
    self.flagStartOverlayDone = false
    self.flagInitiativeShown  = false
    self.flagRewardDone       = false

    -- Victoire / défaite
    self.victoryTriggered     = false
    self.gameoverShown        = false

    return self
end

-- Singleton global pour que changeState puisse y accéder
local Singleton = nil

--- Force un changement d'état FSM (avec log).
-- @tparam string _state
local function changeState(_state)
    if type(_state) ~= "string" then
        logT("Invalid state : le state passé n'est pas une chaîne:", type(_state)); return
    end
    logT("State ->", _state)
    if Singleton then Singleton.state = _state end
end

----------------------------------------------------------------------
-- API explicite
----------------------------------------------------------------------

--- Démarre un affrontement (à appeler quand la scène gameplay se lance).
function CombatFlow:startEncounter()
    changeState("boot")

    self.timer, self.round = 0, 0
    self.enemyOrder, self.enemyIndex, self.enemyStarted = {}, 0, false
    self.victoryTriggered, self.gameoverShown = false, false
    self.rewardOptions, self.rewardChosenIndex = nil, nil
    self.flagStartOverlayDone, self.flagInitiativeShown, self.flagRewardDone = false, false, false

    -- Toujours afficher overlay_start au début de chaque combat
    logT("startEncounter -> push overlay_start")
    if SceneManager and SceneManager.push then
        SceneManager:push("scene.overlay_start.overlay_start")
        changeState("overlay_start")
    end
    self.timer = 0
end

--- Appelé par l’overlay de draft : `selectedCards = {10 cartes}`.
-- Remplace le contenu de HeroDeck par la sélection (clonée), puis borne à 10.
-- @tparam table selectedCards
function CombatFlow:finalizeFirstDraftSelection(selectedCards)
    local picks = type(selectedCards) == "table" and selectedCards or {}
    if Card and Card.getDeckByName then
        local hero = Card.getDeckByName("HeroDeck")
        if hero and hero.cards then
            hero.cards = {}
            for _, c in ipairs(picks) do table.insert(hero.cards, table.clone(c)) end
        end
    end
    ensurePlayerDeckMax10()
    GameFlags.initial_draft_completed = true
    if SceneManager and SceneManager.pop then SceneManager:pop() end
    changeState("setup_round")
    self.timer = 0
end

--- Boucle logique (FSM).
-- @tparam number dt Delta time
function CombatFlow:updateEncounter(dt)
    -- Normalisation du dt
    if type(dt) ~= "number" or dt == nil then
        if _G.globalFunction and _G.globalFunction.clampDt then
            dt = _G.globalFunction.clampDt(dt)
        else
            dt = 0.016
        end
    end
    if dt <= 0 then dt = 0.016 end

    self.timer        = self.timer + dt

    -- Raccourcis config
    local cfg         = self.cfg or DefaultConfig
    local eMin        = (cfg.enemyTurn and cfg.enemyTurn.minTime) or 1.0
    local eTO         = (cfg.enemyTurn and cfg.enemyTurn.timeout) or 6.0
    local eEndT       = (cfg.enemyTurn and cfg.enemyTurn.endTransition) or 0.8
    local preferOnTie = (cfg.preferVictoryOnTie ~= false)

    -- Statut héros mort ?
    local heroDead    = Hero and Hero.actor and Hero.actor.state and
        (Hero.actor.state.dead or (Hero.actor.state.life or 0) <= 0)

    -- ===== FSM =====
    if self.state == "overlay_start" then
        if self.flagStartOverlayDone then
            logT("Transition overlay_start -> overlay_initiative")
            -- Nettoyage de pile (pop overlays au sommet)
            if SceneManager and SceneManager.pop then
                local stackSize = (SceneManager.list and #SceneManager.list) or 0
                logT("Nettoyage overlays, stack size:", stackSize)
                while SceneManager.list and #SceneManager.list > 1 do
                    local topScene = SceneManager.list[#SceneManager.list]
                    if topScene and topScene.name and not topScene.name:find("overlay") then
                        break
                    end
                    logT("Pop overlay:", tostring(topScene and topScene.name or "unknown"))
                    SceneManager:pop()
                end
            else
                logT("WARN: SceneManager.pop indisponible")
            end

            -- Push overlay initiative
            if SceneManager and SceneManager.push then
                SceneManager:push("scene.overlay_initiative.overlay_initiative")
            else
                logT("WARN: SceneManager.push indisponible")
            end

            changeState("overlay_initiative")
            self.timer = 0
            logT("overlay_start -> overlay_initiative OK")
        end
        return
    elseif self.state == "overlay_initiative" then
        if self.flagInitiativeShown then
            logT("Initiative confirmée -> setup_round")
            if SceneManager and SceneManager.pop then
                SceneManager:pop()
            end
            changeState("setup_round")
            self.timer = 0
        end
        return
    elseif self.state == "setup_round" then
        self.round = (self.round or 0) + 1
        setTour("transition")

        -- Mélange & énergies
        if Card and Card.shuffleDeck then Card.shuffleDeck("HeroDeck") end
        ensurePlayerDeckMax10()
        if Hero and Hero.actor then refillPower(Hero.actor, "player") end

        -- Ordre des ennemis vivants
        self.enemyOrder        = livingEnemies()
        self.enemyIndex        = 0
        self.enemyStarted      = false
        self.enemyMaxSteps     = 0
        self.enemyActionStartT = 0

        changeState("enemies_round_start")
    elseif self.state == "enemies_round_start" then
        self.enemyOrder   = livingEnemies()
        self.enemyIndex   = 1
        self.enemyStarted = false
        setTour("Enemy")
        self.state = (#self.enemyOrder == 0) and "victory_check" or "enemy_turn"
        self.timer = 0

        local enemy = self.enemyOrder[self.enemyIndex]
        if (not AI or not AI.load) then
            AI = rawget(_G, "AI") or safe_require("my-librairie/ai/controller")
        end
        if AI and AI.load then pcall(function() AI.load(enemy) end) end
    elseif self.state == "enemy_turn" then
        local enemy = self.enemyOrder[self.enemyIndex]

        -- Ennemi invalide ou mort -> suivant
        if not enemy or (enemy.state and (enemy.state.dead or (enemy.state.life or 0) <= 0)) then
            self.enemyIndex   = self.enemyIndex + 1
            self.enemyStarted = false
            if self.enemyIndex > #self.enemyOrder then
                changeState("player_turn")
                if Hero and Hero.actor then refillPower(Hero.actor, "player") end
                return
            else
                return
            end
        end

        -- Début du tour ennemi
        if not self.enemyStarted then
            self.enemyStarted      = true
            self.enemyActionStartT = self.timer
            self.enemyMaxSteps     = math.max(2, math.ceil(((enemy.state and enemy.state.powerMax) or 6) / 2))
            setCurrentEnemy(enemy)
            if AI and AI.startTurn then pcall(function() AI:startTurn(enemy) end) end
            logT(string.format("Enemy turn start (idx=%d/%d, power=%s)",
                self.enemyIndex, #self.enemyOrder, tostring(enemy.state and enemy.state.power)))
        end

        -- Busy ?
        local busy = false
        if AI then
            if AI.busy == true or AI.running == true then busy = true end
            if AI.queue and type(AI.queue) == "table" and #AI.queue > 0 then busy = true end
        end

        -- L’IA déclare la fin ?
        local wantsDone = false
        if AI and AI.isTurnDone then
            local ok, r = pcall(function() return AI:isTurnDone() end)
            wantsDone = ok and r or false
        end

        -- Conditions de fin
        local elapsed = self.timer - self.enemyActionStartT
        local done = false
        if (elapsed >= eMin) and wantsDone and not busy then
            done = true
        elseif elapsed >= eTO then
            done = true; logT("Enemy turn timeout")
        end

        if done then
            changeState("enemy_turn_transition")
            self.timer = 0
            return
        end
    elseif self.state == "enemy_turn_transition" then
        if self.timer >= eEndT then
            self.enemyIndex   = self.enemyIndex + 1
            self.enemyStarted = false
            if self.enemyIndex > #self.enemyOrder then
                changeState("player_turn")
                self.timer = 0
                setTour("player")
                if Hero and Hero.actor then refillPower(Hero.actor, "player") end
            else
                changeState("enemy_turn")
                self.timer = 0
            end
        end
    elseif self.state == "player_turn" then
        -- Le joueur joue (fin via playerEndTurn()).
        if heroDead then
            self:onPlayerDefeated(); return
        end
    elseif self.state == "victory_check" then
        if #livingEnemies() == 0 and (preferOnTie or not heroDead) then
            -- Préparer récompenses + overlay
            self.rewardOptions = {}
            local pool = (Card and Card.deckGlobal)
                or (Card and Card.getDeckByName and Card.getDeckByName("HeroDeck"))
                or { cards = {} }
            local cards = pool.cards or pool
            local n = math.max(1, #cards)
            for i = 1, ((cfg.reward and cfg.reward.count) or 3) do
                local pick = cards[math.random(n)]
                if pick then self.rewardOptions[i] = table.clone(pick) end
            end
            if cfg.overlays and cfg.overlays.reward and SceneManager and SceneManager.push then
                SceneManager:push(cfg.overlays.reward)
            end
            changeState("reward_choice")
            self.timer = 0
        else
            changeState("setup_round")
            self.timer = 0
        end
    elseif self.state == "reward_choice" then
        if self.flagRewardDone and self.rewardChosenIndex then
            self.flagRewardDone = false
            local chosen = self.rewardOptions and self.rewardOptions[self.rewardChosenIndex]
            if chosen and Card and Card.getDeckByName then
                local deck = Card.getDeckByName("HeroDeck")
                if deck and deck.cards then
                    table.insert(deck.cards, table.clone(chosen))
                    if Card.shuffleDeck then Card.shuffleDeck("HeroDeck") end
                    logT("reward -> +1 carte: " .. (chosen.name or "Carte"))
                end
            end
            self.rewardOptions, self.rewardChosenIndex = nil, nil
            if SceneManager and SceneManager.pop then SceneManager:pop() end

            -- Finir le combat proprement après récompense (évite la boucle infinie)
            logT("Combat terminé après récompense, retour au menu/monde")
            changeState("combat_completed")
            self.timer = 0
        end
    elseif self.state == "combat_completed" then
        logT("Combat completed, exiting to main menu")
        if SceneManager and SceneManager.gotoScene then
            SceneManager:gotoScene("scene.menu.menu")
        elseif SceneManager and SceneManager.pop then
            SceneManager:pop()
        end
        return
    elseif self.state == "game_over" then
        -- Attente overlay Game Over
        return
    end
end

--- Rendu (facultatif pour éléments propres au flow).
function CombatFlow:drawEncounter() end

--- Le joueur clique “Fin du tour”.
-- @treturn boolean ok True si accepté
function CombatFlow:playerEndTurn()
    if self.state ~= "player_turn" then return false end
    setTour("transition")
    changeState("enemies_round_start")
    setTour("Enemy") -- FIX: cohérence avec le reste du code ("Enemy" et pas "enemy")
    self.timer = 0
    return true
end

--- Un ennemi quelconque est mort (hook optionnel).
function CombatFlow:onAnyEnemyDefeated()
    -- Le check sera fait naturellement à la transition de phase.
end

--- Le joueur est mort → game over.
function CombatFlow:onPlayerDefeated()
    if self.gameoverShown then return end
    self.gameoverShown = true
    if self.cfg and self.cfg.overlays and self.cfg.overlays.gameover and SceneManager and SceneManager.push then
        SceneManager:push(self.cfg.overlays.gameover)
    end
    changeState("game_over")
    self.timer = 0
    setTour("transition")
end

--- Bouton/validation dans l’overlay de début de combat.
function CombatFlow:confirmStartOverlay()
    -- Ne pas toucher à GameFlags.initial_draft_completed ici.
    self.flagStartOverlayDone = true
    logT("confirmStartOverlay -> flagStartOverlayDone=true (transition vers initiative)")
end

--- Bouton/validation dans l’overlay d’initiative.
function CombatFlow:confirmInitiativeOverlay()
    logT("confirmInitiativeOverlay() -> flagInitiativeShown=true")
    self.flagInitiativeShown = true
end

--- Renvoie la liste courante de choix de récompense.
-- @treturn table rewardOptions
function CombatFlow:getRewardChoices()
    return self.rewardOptions or {}
end

--- Choisit une récompense par index (1..n).
-- @tparam number i Index de la carte choisie
function CombatFlow:chooseRewardByIndex(i)
    self.rewardChosenIndex = tonumber(i)
    self.flagRewardDone = true
end

----------------------------------------------------------------------
-- Intégration / compat main.lua & overlays
----------------------------------------------------------------------

--- Vrai si les inputs doivent être masqués (pendant certains overlays).
-- overlay_initiative a besoin d'update, donc n'est pas masqué ici.
function CombatFlow:maskInput()
    return self.state == "overlay_start"
        or self.state == "reward_choice"
end

--- Le système de transition est-il actif ?
function CombatFlow:isActive()
    return true
end

--- Autoriser la distribution de cartes (si aucun overlay bloquant).
function CombatFlow:canDeal()
    return not self:maskInput()
end

--- Redémarrer le combat avec transition visuelle.
function CombatFlow:restartEncounterWithTransition()
    if SceneManager and SceneManager.pop then SceneManager:pop() end
    safeSwitchWithTransition("scene.gameplay.gameplay", nil, nil)
end

--- Retourner au menu avec transition visuelle.
function CombatFlow:returnToMenuWithTransition()
    if SceneManager and SceneManager.pop then SceneManager:pop() end
    safeSwitchWithTransition("scene.menu.menu", nil, nil)
end

----------------------------------------------------------------------
-- Export / Singleton + alias de compatibilité
----------------------------------------------------------------------
Singleton                                         = CombatFlow.new(DefaultConfig)

-- Aliases (anciens noms → nouveaux) pour compatibilité avec le reste du projet
Singleton.load                                    = function(self) return Singleton:startEncounter() end
Singleton.update                                  = function(self, dt) return Singleton:updateEncounter(dt) end
Singleton.draw                                    = function(self) return Singleton:drawEncounter() end
Singleton.requestEndTurn                          = function(self) return Singleton:playerEndTurn() end
Singleton.onEnemyDied                             = function(self) return Singleton:onAnyEnemyDefeated() end
Singleton.onHeroDied                              = function(self) return Singleton:onPlayerDefeated() end
Singleton.continueFromStartOverlay                = function(self) return Singleton:confirmStartOverlay() end
Singleton.ackInitiativeOverlay                    = function(self) return Singleton:confirmInitiativeOverlay() end
Singleton.announceContinue                        = function(self) return Singleton:confirmInitiativeOverlay() end
Singleton.getRewardOptions                        = function(self) return Singleton:getRewardChoices() end
Singleton.rewardSelect                            = function(self, i) return Singleton:chooseRewardByIndex(i) end
Singleton.cmdRestart                              = function(self) return Singleton:restartEncounterWithTransition() end
Singleton.cmdBackToMenu                           = function(self) return Singleton:returnToMenuWithTransition() end
Singleton.completeFirstDraft                      = function(self, cards)
    return Singleton:finalizeFirstDraftSelection(
        cards)
end

-- Module exporté : singleton par défaut + constructeur
local M                                           = setmetatable({
    new                      = function(cfg) return CombatFlow.new(cfg) end,
    -- Interfaces consommées par main.lua
    maskInput                = function() return Singleton:maskInput() end,
    isActive                 = function() return Singleton:isActive() end,
    canDeal                  = function() return Singleton:canDeal() end,
    -- Callback overlay initiative
    confirmInitiativeOverlay = function() return Singleton:confirmInitiativeOverlay() end,
}, { __index = Singleton })

-- Noms chargeables (compat)
package.loaded["my-librairie.transition.manager"] = M
package.loaded["my-librairie/transition/manager"] = M
rawset(_G, "Transition", M)

return M
