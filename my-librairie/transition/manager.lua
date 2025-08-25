-- my-librairie/transition/manager.lua
-- Flow combat + overlays + rewards + game over

local Transition              = {}

-- ==== Dépendances ====
local SceneManager            = rawget(_G, "scene") or require("my-librairie/sceneManager")
local Card                    = require("my-librairie/card-librairie/card")
local Enemies                 = rawget(_G, "Enemies") or require("my-librairie/ActorScripts/Enemy/Enemies")
local Hero                    = rawget(_G, "Hero") or require("my-librairie/ActorScripts/player/Hero")
local AI                      = rawget(_G, "AI") or require("my-librairie/ai/controller")

-- ==== Constantes ====
local MIN_ENEMY_TURN_TIME     = 1.2
local ENEMY_TURN_TIMEOUT      = 5
local END_TURN_TRANSITION_T   = 1.20
local ANNOUNCE_MIN_TIME       = 10.0
local PREFER_VICTORY_ON_TIE   = true -- victoire si mort simultanée

-- ==== État ====
Transition.state              = "boot"
Transition.timer              = 0
Transition._nextTurn          = nil
Transition._flags             = { startOverlayDone = false, announceDone = false, rewardChoiceDone = false }
Transition._reward            = { options = nil, chosenIndex = nil }
Transition._rngSeeded         = false
Transition._initiative        = nil
Transition._gameoverShown     = false
Transition._victoryTriggered  = false -- <<< NEW: évite de rappeler onEnemyDied en boucle

-- Suivi IA
Transition._aiStartedThisTurn = false
Transition._enemyStartPow     = nil
Transition._enemyPrevPow      = nil
Transition._lastEnemyActionT  = 0
Transition._enemyPlays        = 0
Transition._enemyMaxPlays     = 0
Transition._heroPrevLife      = nil

-- ==== Utils ====
local function dprint(...) print("[transition]   ", ...) end
--[[
    Fonction utilitaire pour initialiser le générateur de nombres aléatoires
]]
local function _seedRng()
    if Transition._rngSeeded then return end
    local t = (love.timer and love.timer.getTime and love.timer.getTime()) or os.time()
    if love.math and love.math.setRandomSeed then love.math.setRandomSeed(t) end
    math.randomseed(t); Transition._rngSeeded = true
end
--[[
    Met à jour le tour actuel dans la variable globale _G.Tour
    @param tag Le nouveau tag de tour
    @return Le tag si changé, nil sinon
]]
local function _setTour(tag)
    if _G.Tour ~= tag then
        print("[transition]    Tour -> " .. tostring(tag));
        _G.Tour = tag
        return tag
    end
    return nil
end
--[[
    Gère l'entrée dans un nouvel état de transition
    @param state Le nouvel état de transition
    @return Les informations sur la transition { state = state, Timer = Transition.timer }
]]
local function _enter(state)
    Transition.state = state;
    Transition.timer = 0;
    dprint("->\t" .. state)
    return {
        state = state,
        Timer = Transition.timer
    }
end
--[[
    Gère le remplissage de la puissance d'un acteur
    @param acteur L'acteur à remplir

]]
local function _refillPowerForActor(acteur)
    if not (acteur and acteur.state) then return end

    local maxp = acteur.state.powerMax or acteur.state.power or 3

    acteur.state.power = maxp

    -- Mise à jour de l'affichage de l'énergie sur l'interface HUD pour le joueur
    if acteur == (Hero and Hero.actor) then
        if hud and type(hud.updateLabel) == "function" then
            hud.updateLabel('energy_text', tostring(acteur.state.power))
        elseif hud and hud.object and hud.object.energie and hud.object.energie.value then
            hud.object.energie.value.text = tostring(acteur.state.power)
        end
    end
end

--[[
    Gère le remplissage de la puissance du joueur
]]
local function _refillPowerBoth()
    if Hero and Hero.actor then _refillPowerForActor(Hero.actor) end
end

--[[
    assure que le deck du joueur ne dépasse pas une certaine taille et renvoi le surplue dans le deck global
    @param maxN La taille maximale du deck du joueur
]]
local function _ensurePlayerDeckMax(maxN)
    if not (Card and Card.deck) then return end

    local limite = tonumber(maxN or 10) or 10

    --récupération des decks du joueur et global
    local deckPlayer = Card.getDeckByName("HeroDeck") or {}
    local deckGlobal = Card.getDeckByName("GlobalDeck") or {}

    -- Vérification de la limite de la taille du deck du joueur
    if #deckPlayer <= limite then return end
    -- Mélange des cartes du joueur
    Card.shuffleDeck("HeroDeck");

    -- Déplacement des cartes excédentaires vers le deck global
    while #deckPlayer > limite do
        table.insert(deckGlobal, table.remove(deckPlayer))
    end

    dprint(string.format("[player.deck] limité à %d%s", limite, deckGlobal and (", global:" .. #deckGlobal) or ""))
end

-- ==== API ====
function Transition.load()
    _seedRng()

    -- Initialisation des flags de transition
    Transition._flags.startOverlayDone = false
    Transition._flags.announceDone = false
    Transition._flags.rewardChoiceDone = false

    -- Réinitialisation des récompenses
    Transition._reward.options = nil
    Transition._reward.chosenIndex = nil

    -- Réinitialisation des états de transition
    Transition._nextTurn = nil
    Transition._initiative = nil
    Transition._gameoverShown = false
    Transition._victoryTriggered = false -- <<< reset
    Transition._aiStartedThisTurn = false

    -- Changement d'état de transition
    _enter("setup_run")
end

--[[
    Force le passage à l'état de transition à "player_turn"
]]
function Transition.canDeal()
    return Transition.state == "player_turn"
end

function Transition.update(dt)
    -- Validation du paramètre dt
    if type(dt) ~= "number" or dt <= 0 then
        dprint("[update] dt invalide:", dt);
        return
    end
    if (Card == nil) then
        dprint("[update] Card est nil");
        return
    end
    -- Validation de l'état de Hero
    if type(Hero) ~= "table" or type(Hero.actor) ~= "table" or type(Hero.actor.state) ~= "table" then
        dprint("[update] le type de Hero ou Hero.actor ou Hero.actor.state est invalide");
        return
    end

    -- validation de l'état de Enemy
    if type(Enemies) ~= "table" or type(Enemies.curentEnemy) ~= "table" or type(Enemies.curentEnemy.state) ~= "table" then
        dprint("[update] le type de Enemies ou Enemies.curentEnemy ou Enemies.curentEnemy.state est invalide");
        return
    end

    -- Mise à jour du timer
    Transition.timer = (Transition.timer or 0) + dt

    -- ==== Mort / fin de combat (corrigé) ====

    -- vérification de la mort des acteurs
    local heroDead   = Hero.actor.state.dead or (Hero.actor.state.life or 0) <= 0
    local enemyDead  = Enemies.curentEnemy.state.dead or (Enemies.curentEnemy.state.life or 0) <= 0




    -- Victoire : ne déclenche qu'une seule fois
    if enemyDead and not Transition._victoryTriggered
        and (PREFER_VICTORY_ON_TIE or not heroDead)
        and Transition.state ~= "victory_check"
        and Transition.state ~= "reward_choice"
        and Transition.state ~= "advance_enemy"
        and Transition.state ~= "game_over"
    then
        Transition._victoryTriggered = true
        _setTour("transition")
        Transition.onEnemyDied()
        return
    end

    -- Défaite
    if heroDead and not Transition._gameoverShown then
        _setTour("transition")
        Transition.onHeroDied()
        return
    end
    -- ==== Fin correctif ====

    -- Aligne Tour
    local STATE = Transition.state or "boot"

    --[[
        Fonction qui détermine le tour voulu en fonction de l'état actuel
        @return string Le tour voulu
    ]]
    local function _tourWanted()
        if STATE == "player_turn" then return "player" end
        if STATE == "enemy_turn" then return "Enemy" end
        if STATE == "end_turn_transition" then return "transition" end
        return "transition"
    end
    -- Définition du tour actuel
    _setTour(_tourWanted())

    -- (FSM) = MACHINE A ETATS
    if STATE == "setup_run" then
        -- Préparation du deck du joueur
        Card.shuffleDeck("HeroDeck")
        -- on verifie que le deck du joueur ne dépasse pas la taille maximale autorisée en début de partie
        _ensurePlayerDeckMax(10);
        -- Remplissage de la puissance du joueur
        _refillPowerForActor(Hero.actor)

        -- on affiche l'overlay de début de tour
        SceneManager:push("scene/overlay_start"); dprint("[overlay] push overlay_start")

        -- on change d'état
        _enter("deal_start_hand")
    elseif STATE == "deal_start_hand" then
        -- on verifie que l'overlay de début de tour est terminé
        if Transition._flags.startOverlayDone then
            -- reset du flag
            Transition._flags.startOverlayDone = false
            -- on demande à SceneManager de retirer de la pile de rendu overlay start vue quil est en premier
            -- dans la pile le pop retire le premier élément de la pile
            if SceneManager and SceneManager.pop then SceneManager:pop() end
            -- on change d'état
            _enter("initiative_flip")
        end
    elseif STATE == "initiative_flip" then
        -- on verifie que _initiative existe dans la table Transition
        if not Transition._initiative then
            -- Allow forced initiative for testing via global FORCE_INITIATIVE ("player" or "Enemy")
            -- or via Transition._forcedInitiative set at runtime.
            local forced = rawget(_G, "FORCE_INITIATIVE") or Transition._forcedInitiative
            if type(forced) == "string" then
                local f = forced:lower()
                if f == "player" then
                    Transition._initiative = "player"
                elseif f == "enemy" then
                    Transition._initiative = "Enemy"
                end
                if Transition._initiative then
                    dprint("[initiative] forced gagnant = " .. Transition._initiative)
                end
            end
            -- Fallback to original random behaviour
            if not Transition._initiative then
                Transition._initiative = (math.random() < 0.5) and "player" or "Enemy"
            end
            dprint("[initiative] gagnant = " .. Transition._initiative)
            -- on affiche l'overlay d'annonce de l'initiative
            SceneManager:push("scene/overlay_initiative"); dprint("[overlay] push overlay_initiative")
            -- on change d'état
            _enter("announce_initiative")
        end
    elseif STATE == "announce_initiative" then
        --on verifie si le jouer a demandé de fermer overlay dinitiative ou que le temps maximum daffichage est écoulé
        if Transition._flags.announceDone or Transition.timer >= ANNOUNCE_MIN_TIME then
            -- reset du flag
            Transition._flags.announceDone = false
            -- on retire l'overlay d'annonce de l'initiative
            SceneManager:pop()
            --on verifie si ces le jouer qui commence
            if Transition._initiative == "player" then
                -- on set tour pour dire que ces le tour du jouer
                _setTour("player");
                -- on charge les point d'énergie du joueur
                _refillPowerForActor(Hero.actor)
                -- on entre dans le tour du joueur
                _enter("player_turn")
            else
                --si ces l'ennemi qui commence
                -- on set tour pour dire que ces le tour de l'ennemi
                _setTour("Enemy");
                -- on definie les variables pour le tour de l'ennemi
                Transition._aiStartedThisTurn = false
                Transition._enemyPlays, Transition._lastEnemyActionT = 0, 0

                -- on sauvegarde la vie du héros avant le tour de l'ennemi
                Transition._heroPrevLife = (Hero and Hero.actor and Hero.actor.state and Hero.actor.state.life) or nil
                -- on change d'état
                _enter("enemy_turn")
            end
        end
    elseif STATE == "player_turn" then
        -- si le prochain tour est celui de l'ennemi
        if Transition._nextTurn == "Enemy" then
            -- on definie comme quoi le tour va passer en transition ce qui anonce un changement de tour
            _setTour("transition");
            --on change d'état
            _enter("end_turn_transition")
        end
    elseif STATE == "enemy_turn" then
        -- si l'ennemi a pas commencé son tour
        if not Transition._aiStartedThisTurn then
            -- on dit qu'il a commencé son tour
            Transition._aiStartedThisTurn = true
            -- on defini le nombre de dernier coup de l'ennemi a 0
            Transition._lastEnemyActionT  = 0
            -- on defini le nombre maximum de coup de l'ennemi
            -- pmax/pow pouvaient être non définis (ancienne variable). On calcule depuis l'ennemi ou valeur par défaut
            local pmax_val                = (Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state and Enemies.curentEnemy.state.powerMax) or
                6
            local pow_val                 = (Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state and Enemies.curentEnemy.state.power) or
                pmax_val
            Transition._enemyMaxPlays     = math.max(2, math.ceil((tonumber(pmax_val) or 6) / 2))

            dprint(string.format("[enemy] startTurn (power=%d, maxPlays=%d)", tonumber(pow_val) or 0,
                Transition._enemyMaxPlays))

            -- on lance le tour de l'énemy dans la machie a état de l'ia
            if AI.startTurn then pcall(function() AI:startTurn(Enemies.curentEnemy) end) end
        end


        local busy = false -- on definit que l'ia est pas  occupée

        if AI then
            -- on verifie si l'ia est occupée si oui on definie busy a true
            if AI.busy == true or AI.running == true then busy = true end
            if AI.queue and type(AI.queue) == "table" and #AI.queue > 0 then busy = true end
        end

        local wantsDone = false -- on definit que l'ia veut pas finir son tour
        --on verifi si l'ia a terminer sont tour
        if AI and AI.isTurnDone then
            local ok, r = pcall(function() return AI:isTurnDone() end);
            --si oui on definit que l'ia veut finir son tour
            wantsDone = ok and r or false
        end

        -- heuristique de fin de tour
        local idleFor = Transition.timer - (Transition._lastEnemyActionT or 0)
        -- on verifie si l'ennemi a joue
        if Transition._enemyPlays >= Transition._enemyMaxPlays and idleFor >= 0.35 then
            --si oui on definit que l'ia veut finir son tour
            wantsDone = true;
            dprint("[enemy] fin (plafond de coups atteint)")
        end


        local done = false -- on definit que le tour est pas fini
        -- on verifie si le tour doit se terminer
        if (Transition.timer >= MIN_ENEMY_TURN_TIME) and wantsDone and not busy then
            -- si oui on definit que le tour est fini
            done = true;
            dprint("[enemy] fin (isTurnDone/heuristique && !busy)")
            -- si le timer est écoulé
        elseif Transition.timer >= ENEMY_TURN_TIMEOUT then
            -- si le timer est écoulé on definit que le tour est fini pour l'ennemi
            done = true;
            dprint("[enemy] timeout -> fin forcée")
        end
        -- si le tour est fini
        if done then
            -- on di que le prochain tour est celui du joueur
            Transition._nextTurn = "player"
            -- on met à jour le tour pour anoncer un changement de tour
            _setTour("transition");
            -- on change l'état
            _enter("end_turn_transition")
            -- on di que l'ia a pas commencé son tour (rezet var)
            Transition._aiStartedThisTurn = false
        end
    elseif STATE == "end_turn_transition" then
        -- on verifie si le timer de transition est écoulé pour changer de tour
        if Transition.timer >= END_TURN_TRANSITION_T then
            -- si le prochain tour est celui de l'énemie
            if Transition._nextTurn == "Enemy" then
                -- on met à jour le tour pour dire que ces le tour de l'énemie
                _setTour("Enemy");
                --on dit que l'ia commence son tour
                Transition._aiStartedThisTurn = true
                --on dit que l'ennemi n'a pas encore joué
                Transition._enemyPlays        = 0
                Transition._lastEnemyActionT  = 0
                -- on recupère la vie courante du héros
                Transition._heroPrevLife      = (Hero and Hero.actor and Hero.actor.state and Hero.actor.state.life) or
                    nil
                -- on définie le nombre d'action maximum de l'ennemi
                local pmax                    = (Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state and Enemies.curentEnemy.state.powerMax) or
                6
                pmax                          = tonumber(pmax) or 6
                Transition._enemyMaxPlays     = math.max(2, math.ceil(pmax / 2))

                dprint(string.format("[enemy] startTurn (maxPlays=%d)", Transition._enemyMaxPlays))

                if AI and AI.startTurn and Enemies and Enemies.curentEnemy then
                    -- on lance le tour de l'énemy dans la machie a état de l'ia
                    pcall(function() AI:startTurn(Enemies.curentEnemy) end)
                end
                -- on change l'état
                _enter("enemy_turn")
            else
                -- si cest au jouer de jouer
                -- on met à jour le tour pour dire que ces le tour du jouer
                _setTour("player");
                -- on remplit l'énergie du joueur
                _refillPowerForActor(Hero and Hero.actor)
                -- on change l'état
                _enter("player_turn")
            end
            -- on remet la variable de changement de tour a nil
            Transition._nextTurn = nil
        end
    elseif STATE == "victory_check" then
        -- Prépare 3 récompenses et affiche l’overlay
        -- on vide les options de récompense
        Transition._reward.options = {}
        -- on charge le deck global et le deck du joueur
        local deckGlobal = (Card and Card.getDeckByName("deckGlobal")) or {}
        local playerDeck = (Card and Card.getDeckByName("HeroDeck")) or {}

        -- on crée le pool de cartes
        local pool = (Card and deckGlobal) or (Card and playerDeck) or {}

        -- on récupère le nombre de cartes dans la pool
        local n = math.max(1, #pool.cards)
        -- on choisit 3 cartes aléatoires dans la pool
        for i = 1, 3 do
            local pick = pool.cards[math.random(n)]; if pick then
                Transition._reward.options[i] = table.clone(pick)
            end
        end
        -- on affiche l'overlay de récompense
        SceneManager:push("scene/overlay_reward")
        -- on change d'état
        _enter("reward_choice")
    elseif S == "reward_choice" then
        -- on verifie si le jouer a fait son choix de récompense
        if Transition._flags.rewardChoiceDone and Transition._reward.chosenIndex then
            -- reset du flag
            Transition._flags.rewardChoiceDone = false
            -- on récupère l'index du choix
            local index = Transition._reward.chosenIndex
            -- on récupère la carte choisie
            local chosen = Transition._reward.options and Transition._reward.options[index]

            if chosen and Card and Card.deck then
                -- on récupère le deck du joueur
                local playerDeck = Card.getDeckByName("HeroDeck")
                -- on ajoute la carte choisie au deck du joueur
                table.insert(playerDeck.cards, table.clone(chosen))
                -- on mélange le deck du joueur
                if Card.shuffleDeck then Card.shuffleDeck("Hero") end

                dprint("reward -> +1 carte: " .. (chosen.name or "Carte"))
            end
            -- on vide les options de récompense
            Transition._reward.options = nil
            Transition._reward.chosenIndex = nil

            -- on quitte l'overlay de récompense
            SceneManager:pop()
            -- on change d'état
            _enter("advance_enemy")
        end
    elseif STATE == "advance_enemy" then
        -- on change d'énemy
        if Enemies and (Enemies.next or Enemies.load) then if Enemies.next then Enemies.next() else Enemies.load() end end
        -- on re charge les point de puissance du joueur
        _refillPowerBoth()
        -- on verifie si il ya des carte dans la main du joueur
        if Card and Card.hand.cards and #Card.hand.cards > 0 then
            -- on récupère le deck du joueur
            local playerDeck = Card.getDeckByName("HeroDeck")

            -- on remet les cartes de la main du joueur dans le deck du joueur
            for i = #Card.hand.cards, 1, -1 do
                table.insert(playerDeck.cards,
                    table.remove(Card.hand, i))
            end

            -- on récupere la carte du cimetier pour les remttre dans le deck du joueur
            if Card and Card.graveyard and #Card.graveyard.cards > 0 then
                for i = #Card.graveyard.cards, 1, -1 do
                    table.insert(playerDeck.cards, table.remove(Card.graveyard.cards, i))
                end
            end
        end

        -- on tire 5 cartes du deck du joueur pour le metre dans sa main
        if Card and Card.tirage then Card.tirage(5, true, 'HeroDeck') end

        -- on rezet les flags de transition
        Transition._initiative = nil
        Transition._victoryTriggered = false -- <<< prêt pour le prochain combat

        -- on change d'état
        _enter("initiative_flip")
    elseif STATE == "game_over" then
        -- attente overlay
    end
end

function Transition.draw() end

-- ==== Commandes ====
--[[
    Commandes de transition fait une requette de fin de tour
]]
function Transition.requestEndTurn()
    dprint("[transition] [endTurn] demande (state=" ..
        tostring(Transition.state) .. ", Tour=" .. tostring(_G.Tour) .. ")")
    -- si ces au tour du joueur
    if Transition.state == "player_turn" or _G.Tour == "player" then
        --on definie le prochain tour que ce sera l'énemy
        Transition._nextTurn = "Enemy"
        --on passe en mode transition
        _setTour("transition");
        -- on entre dans l'état de transition
        _enter("end_turn_transition")

        dprint("[transition] [endTurn] OK")
        return true
    end
    print("[transition] [endTurn] ignorée"); return false
end

--[[
    Gestion de la mort de l'ennemi
]]
function Transition.onEnemyDied()
    dprint("enemy died -> victory_check");
    -- on entre dans l'état de victoire
    _enter("victory_check")
end

--[[
    Gestion de la mort du héros
]]
function Transition.onHeroDied()
    -- si on est deja en transition de gameOver on return
    if Transition._gameoverShown then return end

    dprint("hero died -> game_over"); Transition._gameoverShown = true
    -- on affiche l'overlay de gameOver
    SceneManager:push("scene/overlay_gameover")
    -- on change d'état
    _enter("game_over")
end

-- Overlays
--[[
    ci appelait demande l'overlay de début de ce fermet
]]
function Transition.continueFromStartOverlay()
    dprint("[overlay_start] continue");
    Transition._flags.startOverlayDone = true
end

--[[
    ci appelait demande l'overlay d'initiative ce fermet
]]
function Transition.ackInitiativeOverlay()
    dprint("[overlay_initiative] acknowledged");
    Transition._flags.announceDone = true
end

-- Récompenses
--[[
    Renvoi les options de récompense (3 cartes aléatoires du deck global)
    @return table Liste des options de récompense
]]
function Transition.getRewardOptions()
    if (Transition._reward.options == nil or #Transition._reward.options == 0) then
        Transition._reward.options = {}
        Card = Card or require("my-librairie/card-librairie/card")
        if not Card or not Card.deckGlobal then
            dprint("[transition] [reward] pas de deck global, pas de récompenses")
            return Transition._reward.options
        end
        local pool = Card.deckGlobal
        local n = math.max(1, #pool)
        for i = 1, 3 do
            local pick = pool[math.random(n)];
            if pick then
                Transition._reward.options[i] = table.clone(pick)
            end
        end
    end
    return Transition._reward.options or {}
end

--[[
    Sélectionne une récompense
    @param index L'index de la récompense à sélectionner
]]
function Transition.rewardSelect(index)
    Transition._reward.chosenIndex = tonumber(index);
    Transition._flags.rewardChoiceDone = true
end

-- Game Over actions
--[[
    Redémarre le jeu
    ]]
function Transition.cmdRestart()
    if SceneManager and SceneManager.pop then SceneManager:pop() end;
    if SceneManager and SceneManager.switch then SceneManager:switch("scene/gameplay") end
end

--[[
    Retourne au menu principal
]]
function Transition.cmdBackToMenu()
    if SceneManager and SceneManager.pop then SceneManager:pop() end;
    if SceneManager and SceneManager.switch then SceneManager:switch("scene/menu") end
end

--[[ Debug / test helpers
    Usage:
      rawset(_G, "FORCE_INITIATIVE", "player")  -- or "Enemy"
      Transition.setForcedInitiative("player")
      Transition.clearForcedInitiative()

    These helpers are non-intrusive: if no forced value is set the normal
    random behaviour remains.
]]
function Transition.setForcedInitiative(val)
    if type(val) ~= "string" then return false end
    local f = val:lower()
    if f == "player" then
        Transition._forcedInitiative = "player"
        return true
    elseif f == "enemy" then
        Transition._forcedInitiative = "Enemy"
        return true
    end
    return false
end

function Transition.clearForcedInitiative()
    Transition._forcedInitiative = nil
end

-- Alias anti multi-require
do
    local M = Transition
    package.loaded["my-librairie.transition.manager"] = M
    package.loaded["my-librairie/transition/manager"] = M
    rawset(_G, "Transition", M)
end

return Transition
