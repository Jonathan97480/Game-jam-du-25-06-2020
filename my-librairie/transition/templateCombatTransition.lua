-- my-librairie/transition/templateCombatTransition.lua
-- CombatTransition Template — multi-ennemis, transitions de scène,
-- premier draft géré avec overlay_start (plus de overlay_deckdraft)

-- ============== Require paresseux (anti-cycles) ==============
--[[ local function SM() return rawget(_G, "scene") or require("my-librairie/sceneManager") end
local function AM() return rawget(_G, "actorManager") or require("my-librairie/actorManager") end
local function EN() return rawget(_G, "Enemies") or require("my-librairie/ActorScripts/Enemy/Enemies") end
local function HERO() return rawget(_G, "Hero") or require("my-librairie/ActorScripts/player/Hero") end
local function AI() return rawget(_G, "AI") or require("my-librairie/ai/controller") end
local function CARD() return require("my-librairie/card-librairie/card") end ]]


local SceneManager = rawget(_G, "scene") or require("my-librairie/sceneManager")
local Card         = require("my-librairie/card-librairie/card")
local Hero         = rawget(_G, "Hero") or require("my-librairie/ActorScripts/player/Hero")
local AI           = rawget(_G, "AI") or require("my-librairie/ai/controller")
local AM           = require("my-librairie/actorManager")               -- liste des ennemis vivants
local EnemiesMod   = require("my-librairie/ActorScripts/Enemy/Enemies") -- pour compat: Enemies.curentEnemy


-- Persistance simple pour flags globaux (draft du premier combat)
local GameFlags = rawget(_G, "GameFlags") or {}; rawset(_G, "GameFlags", GameFlags)


-- --------------------------
-- Config par défaut (overlays, timings)
-- --------------------------
local DefaultConfig = {
    overlays           = {
        reward     = "scene.overlay_start.overlay_start",
        initiative = "scene.overlay_initiative.overlay_initiative",
        gameover   = "scene.overlay_gameover.overlay_gameover",

    },
    reward             = { count = 3 },
    enemyTurn          = { minTime = 1.0, timeout = 6.0, endTransition = 0.8 },
    preferVictoryOnTie = true
}

-- --------------------------
-- Utils
-- --------------------------
local function logT(...)
    local gf = rawget(_G, 'globalFunction'); local parts = {}
    for i = 1, select('#', ...) do parts[i] = tostring(select(i, ...)) end
    local msg = "[CombatFlow] " .. table.concat(parts, " ")
    if gf and gf.log and gf.log.info then gf.log.info(msg) else print(msg) end
end

local function clampDt(dt) return (dt > 0.05) and 0.05 or dt end

local function setTour(tag)
    if _G.Tour ~= tag then
        _G.Tour = tag; logT("Tour ->", tag)
    end
end

local function refillPower(actor, label)
    if not (actor and actor.state) then return end
    local pmax = actor.state.powerMax or actor.state.power or 3
    actor.state.power = pmax
    if label == "player" and rawget(_G, "hud") and hud.updateLabel then
        hud.updateLabel('energy_text', tostring(pmax))
    end
end

local function ensurePlayerDeckMax10()
    if not (Card and Card.getDeckByName) then return end
    local deck = Card.getDeckByName("HeroDeck"); if not deck or not deck.cards then return end
    while #deck.cards > 10 do table.remove(deck.cards) end
end

local function safeSwitchWithTransition(target, params, tScript)
    local ok = pcall(function() SceneManager:switchWithTransition(target, params, { script = tScript }) end)
    if not ok then SceneManager:switch(target, params) end
end

-- --------------------------
-- Classe CombatFlow
-- --------------------------
local CombatFlow = {}; CombatFlow.__index = CombatFlow

function CombatFlow.new(cfg)
    local self                = setmetatable({}, CombatFlow)
    self.cfg                  = cfg or DefaultConfig
    self.state                = "boot"
    self.timer                = 0
    self.round                = 0

    -- Ordonnancement multi-ennemis
    self.enemyOrder           = {} -- liste d’instances ennemies vivantes (à remplir à chaque round)
    self.enemyIndex           = 0  -- index courant dans enemyOrder
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

-- --------------------------
-- API EXPLICITE
-- --------------------------

-- Démarre un affrontement (appeler quand la scène gameplay se lance)
function CombatFlow:startEncounter()
    self.state = "boot"; self.timer = 0; self.round = 0
    self.enemyOrder, self.enemyIndex, self.enemyStarted = {}, 0, false
    self.victoryTriggered, self.gameoverShown = false, false
    self.rewardOptions, self.rewardChosenIndex = nil, nil
    self.flagStartOverlayDone, self.flagInitiativeShown, self.flagRewardDone = false, false, false

    -- Draft unique au tout premier combat
    if not GameFlags.first_draft_done then
        self.state = "first_draft"; self.timer = 0
        if self.cfg.overlays.reward then
            SceneManager:push(self.cfg.overlays.reward); logT("Overlay reward")
        else
            ensurePlayerDeckMax10(); GameFlags.first_draft_done = true
            self.state = "setup_round"; self.timer = 0
        end
        return
    end

    -- Pas de draft: setup direct
    self.state = "setup_round"; self.timer = 0
end

-- Appelé par l’overlay de draft : selectedCards = {10 cartes}
function CombatFlow:finalizeFirstDraftSelection(selectedCards)
    local picks = type(selectedCards) == "table" and selectedCards or {}
    if Card and Card.getDeckByName then
        local hero = Card.getDeckByName("HeroDeck"); if hero and hero.cards then
            hero.cards = {}; for _, c in ipairs(picks) do table.insert(hero.cards, table.clone(c)) end
        end
    end
    ensurePlayerDeckMax10()
    GameFlags.first_draft_done = true
    if SceneManager.pop then SceneManager:pop() end
    self.state = "setup_round"; self.timer = 0
end

-- Boucle logique
function CombatFlow:updateEncounter(dt)
    dt = clampDt(dt); if dt <= 0 then return end
    self.timer        = self.timer + dt

    -- Raccourcis config
    local cfg         = self.cfg or DefaultConfig
    local eMin        = (cfg.enemyTurn and cfg.enemyTurn.minTime) or 1.0
    local eTO         = (cfg.enemyTurn and cfg.enemyTurn.timeout) or 6.0
    local eEndT       = (cfg.enemyTurn and cfg.enemyTurn.endTransition) or 0.8
    local preferOnTie = (cfg.preferVictoryOnTie ~= false)

    -- Aides
    local function livingEnemies()
        local list = {}
        for _, e in ipairs(EnemiesMod.listeEnemies or {}) do
            local alive = (e and e.state and not e.state.dead and (e.state.life or 1) > 0)
            if alive then table.insert(list, e) end
        end
        return list
    end

    local function setCurrentEnemy(e)
        -- Pour compatibilité avec code existant qui lit Enemies.curentEnemy
        EnemiesMod.curentEnemy = e
    end

    local heroDead = Hero and Hero.actor and (Hero.actor.state.dead or (Hero.actor.state.life or 0) <= 0)

    -- ===== FSM =====
    if self.state == "first_draft" then
        -- On attend finalizeFirstDraftSelection depuis l’overlay
        return
    elseif self.state == "setup_round" then
        self.round = (self.round or 0) + 1
        setTour("transition")

        -- Mélange & énergies
        if Card.shuffleDeck then Card.shuffleDeck("HeroDeck") end
        ensurePlayerDeckMax10()
        refillPower(Hero.actor, "player")

        -- Init ordre des ennemis vivants pour ce round
        self.enemyOrder = livingEnemies()
        self.enemyIndex = 0
        self.enemyStarted = false
        self.enemyMaxSteps = 0
        self.enemyActionStartT = 0
        --TODO GERAIT LINITIATIVE
        self.state = "enemies_round_start"; self.timer = 0
    elseif self.state == "enemies_round_start" then
        -- Tous les ennemis vivants vont jouer, un par un
        self.enemyOrder = livingEnemies()
        self.enemyIndex = 1
        self.enemyStarted = false
        setTour("Enemy")
        self.state = (#self.enemyOrder == 0) and "victory_check" or "enemy_turn"; self.timer = 0
    elseif self.state == "enemy_turn" then
        local enemy = self.enemyOrder[self.enemyIndex]
        if not enemy or (enemy.state and (enemy.state.dead or (enemy.state.life or 0) <= 0)) then
            -- Ennemi invalide ou mort → suivant
            self.enemyIndex = self.enemyIndex + 1
            self.enemyStarted = false
            if self.enemyIndex > #self.enemyOrder then
                -- Fin du tour de tous les ennemis → joueur
                self.state = "player_turn"; self.timer = 0; setTour("player"); refillPower(Hero.actor, "player")
                return
            else
                -- Continuer sur le prochain ennemi
                return
            end
        end

        -- Lancer le tour de l’ennemi courant
        if not self.enemyStarted then
            self.enemyStarted = true
            self.enemyActionStartT = self.timer
            self.enemyMaxSteps = math.max(2, math.ceil(((enemy.state and enemy.state.powerMax) or 6) / 2))
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

        -- Terminé ?
        local wantsDone = false
        if AI and AI.isTurnDone then
            local ok, r = pcall(function() return AI:isTurnDone() end); wantsDone = ok and r or false
        end

        -- Timeout minimal
        local elapsed = self.timer - self.enemyActionStartT
        local done = false
        if (elapsed >= eMin) and wantsDone and not busy then
            done = true
        elseif elapsed >= eTO then
            done = true; logT("Enemy turn timeout")
        end

        if done then
            -- Passer à l’ennemi suivant (petite transition optionnelle)
            self.state = "enemy_turn_transition"; self.timer = 0; return
        end
    elseif self.state == "enemy_turn_transition" then
        if self.timer >= eEndT then
            self.enemyIndex = self.enemyIndex + 1
            self.enemyStarted = false
            if self.enemyIndex > #self.enemyOrder then
                self.state = "player_turn"; self.timer = 0; setTour("player"); refillPower(Hero.actor, "player")
            else
                self.state = "enemy_turn"; self.timer = 0
            end
        end
    elseif self.state == "player_turn" then
        -- Le joueur joue. Quand il termine (bouton Fin de tour), on repasse aux ennemis.
        if heroDead then
            self:onPlayerDefeated(); return
        end
        -- Rien à faire ici, on attend playerEndTurn()
    elseif self.state == "victory_check" then
        -- Tous les ennemis morts ? victoire
        if #livingEnemies() == 0 and (preferOnTie or not heroDead) then
            -- Préparer les récompenses & overlay
            self.rewardOptions = {}
            local pool = (Card and Card.deckGlobal) or (Card.getDeckByName and Card.getDeckByName("HeroDeck")) or
                { cards = {} }
            local cards = pool.cards or pool
            local n = math.max(1, #cards)
            for i = 1, (cfg.reward.count or 3) do
                local pick = cards[math.random(n)]; if pick then self.rewardOptions[i] = table.clone(pick) end
            end
            if cfg.overlays.reward then SceneManager:push(cfg.overlays.reward) end
            self.state = "reward_choice"; self.timer = 0
        else
            -- Sinon, nouveau round
            self.state = "setup_round"; self.timer = 0
        end
    elseif self.state == "reward_choice" then
        if self.flagRewardDone and self.rewardChosenIndex then
            self.flagRewardDone = false
            local chosen = self.rewardOptions and self.rewardOptions[self.rewardChosenIndex]
            if chosen and Card and Card.getDeckByName then
                local deck = Card.getDeckByName("HeroDeck"); if deck and deck.cards then
                    table.insert(deck.cards, table.clone(chosen))
                    if Card.shuffleDeck then Card.shuffleDeck("HeroDeck") end
                    logT("reward -> +1 carte: " .. (chosen.name or "Carte"))
                end
            end
            self.rewardOptions, self.rewardChosenIndex = nil, nil
            if SceneManager.pop then SceneManager:pop() end
            -- Nouveau round après récompense
            self.state = "setup_round"; self.timer = 0
        end
    elseif self.state == "game_over" then
        -- On attend l’overlay Game Over (bouton → menu par exemple)
        return
    end
end

-- Rendu (si tu veux afficher des éléments spécifiques au flow)
function CombatFlow:drawEncounter() end

-- Le joueur a cliqué “Fin du tour”
function CombatFlow:playerEndTurn()
    if self.state ~= "player_turn" then return false end
    setTour("transition")
    self.state = "enemies_round_start"; self.timer = 0
    return true
end

-- Un ennemi quelconque est mort (peut être appelé par Enemies/AM si tu as un hook)
function CombatFlow:onAnyEnemyDefeated()
    -- On ne saute pas directement : le check se fait à la transition de phase
end

-- Le joueur est mort
function CombatFlow:onPlayerDefeated()
    if self.gameoverShown then return end
    self.gameoverShown = true
    if self.cfg.overlays.gameover then SceneManager:push(self.cfg.overlays.gameover) end
    self.state = "game_over"; self.timer = 0; setTour("transition")
end

-- Overlays : boutons “continuer/OK”
function CombatFlow:confirmStartOverlay()
    GameFlags.first_draft_done = true
    self.flagStartOverlayDone = true
    SceneManager:pop()
    setTour("setup_round")
    self.state = "setup_round"; self.timer = 0
end

function CombatFlow:confirmInitiativeOverlay() self.flagInitiativeShown = true end

function CombatFlow:getRewardChoices() return self.rewardOptions or {} end

function CombatFlow:chooseRewardByIndex(i)
    self.rewardChosenIndex = tonumber(i); self.flagRewardDone = true
end

-- Navigation de scènes avec transition visuelle (fade/slide) :
function CombatFlow:restartEncounterWithTransition()
    if SceneManager.pop then SceneManager:pop() end
    safeSwitchWithTransition("scene.gameplay.gameplay", nil, nil)
end

function CombatFlow:returnToMenuWithTransition()
    if SceneManager.pop then SceneManager:pop() end
    safeSwitchWithTransition("scene.menu.menu", nil, nil)
end

-- --------------------------
-- Export / Singleton + Aliases compat
-- --------------------------
local Singleton                                   = CombatFlow.new(DefaultConfig)

-- Aliases (anciens noms → nouveaux) pour ne rien casser :
Singleton.load                                    = function(self) return self:startEncounter() end
Singleton.update                                  = function(self, dt) return self:updateEncounter(dt) end
Singleton.draw                                    = function(self) return self:drawEncounter() end
Singleton.requestEndTurn                          = function(self) return self:playerEndTurn() end
Singleton.onEnemyDied                             = function(self) return self:onAnyEnemyDefeated() end
Singleton.onHeroDied                              = function(self) return self:onPlayerDefeated() end
Singleton.continueFromStartOverlay                = function(self) return self:confirmStartOverlay() end
Singleton.ackInitiativeOverlay                    = function(self) return self:confirmInitiativeOverlay() end
Singleton.getRewardOptions                        = function(self) return self:getRewardChoices() end
Singleton.rewardSelect                            = function(self, i) return self:chooseRewardByIndex(i) end
Singleton.cmdRestart                              = function(self) return self:restartEncounterWithTransition() end
Singleton.cmdBackToMenu                           = function(self) return self:returnToMenuWithTransition() end
Singleton.completeFirstDraft                      = function(self, cards) return self:finalizeFirstDraftSelection(cards) end

local M                                           = setmetatable({
    new = function(cfg) return CombatFlow.new(cfg) end
}, { __index = Singleton })

-- noms chargeables
package.loaded["my-librairie.transition.manager"] = M
package.loaded["my-librairie/transition/manager"] = M
rawset(_G, "Transition", M)

return M
