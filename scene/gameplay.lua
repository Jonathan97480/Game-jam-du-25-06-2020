-- scene/gameplay.lua

local gameplay = {}

local DEBUG_GAMEPLAY = true
local function log(...) if DEBUG_GAMEPLAY then print(...) end end
local function logf(fmt, ...) if DEBUG_GAMEPLAY then print(string.format(fmt, ...)) end end
local function safecall(where, fn, ...)
    if type(fn) ~= "function" then
        if DEBUG_GAMEPLAY then print(("[safe] %s: fn=nil"):format(where)) end
        return nil
    end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        if DEBUG_GAMEPLAY then print(("[safe] %s: ERREUR -> %s"):format(where, tostring(a))) end
        return nil
    end
    return a, b, c, d
end

-- Tour global piloté par le Transition Manager
Tour                          = Tour or "transition"
local lastTour                = ""
local watchdogEnemyHold       = 0
local WATCHDOG_LIMIT          = 2.0

-- Modules
local Transition              = require("my-librairie/transition/manager")
local cardsPlayer             = require("ressources/cards_data_player")
Hero                          = require("my-librairie/ActorScripts/player/Hero")
Enemies                       = require("my-librairie/ActorScripts/Enemy/Enemies")
local AI                      = require("my-librairie/ai/controller")
local CardsIA                 = require("ressources/cardsIA")
local actor                   = _G.actorManager or require("my-librairie/actorManager")

-- Règles de pioche
local HAND_MAX                = 5
local DRAW_MODE               = "fill"
local DRAW_PER_TURN           = 1

-- Flag : pioche en attente (ex: panneau ouvert)
gameplay._pendingDrawThisTurn = false

-- --------- Utils ---------
local function refillPowerForHero()
    local maxp = (Hero and Hero.actor and Hero.actor.state and (Hero.actor.state.powerMax or 8)) or 8
    if Hero and Hero.actor and Hero.actor.state then
        Hero.actor.state.power = maxp
        logf("[power] Hero power reset -> %d", maxp)
    end
end

local function refillPowerForEnemy()
    if Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state then
        local emax = Enemies.curentEnemy.state.powerMax or Enemies.curentEnemy.state.power or 3
        Enemies.curentEnemy.state.power = emax
        logf("[power] Enemy power reset -> %d", emax)
    end
end

local function aiTurnIsOver()
    if not AI then return true, "AI=nil" end
    if AI.updateReturn == true or AI.updateReturn == "done" then return true, "updateReturn" end
    local checks = { "isFinish", "isFinished", "isTurnFinished", "done", "finished", "turnEnded", "canEndTurn" }
    for _, fn in ipairs(checks) do
        if type(AI[fn]) == "function" then
            local ok, res = pcall(AI[fn], AI); if ok and res then return true, fn end
        elseif type(AI[fn]) == "boolean" and AI[fn] then
            return true, fn
        end
    end
    if (AI.queue and #AI.queue == 0) and (AI.busy == false or AI.running == false) then
        return true, "queue-empty"
    end
    if Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state and Enemies.curentEnemy.state.dead then
        return true, "enemy-dead"
    end
    return false, "working"
end

-- --------- Pioche de début de tour joueur (déclenchée à l'entrée de tour ou plus tard si overlay fermé) ---------
local function drawAtStartOfPlayerTurn()
    if not Card or not Card.tirage then return end

    -- Si un overlay bloque, on marque juste l'intention et on sort (on re-tentera plus tard)
    if Transition and Transition.canDeal and not Transition.canDeal() then
        if not gameplay.__overlayBlockWarned then
            print("[draw] bloqué: transition/overlay (pioche reportée)")
            gameplay.__overlayBlockWarned = true
        end
        gameplay._pendingDrawThisTurn = true
        return
    end
    gameplay.__overlayBlockWarned = false

    local hand = (Card.handList and Card.handList()) or Card.hand or {}
    local drawCount
    if DRAW_MODE == "fill" then
        drawCount = math.max(0, HAND_MAX - #hand)
    else
        drawCount = DRAW_PER_TURN
    end

    if drawCount > 0 then
        print(("[draw] début de tour joueur → tirage %d (hand=%d → cible=%d)"):format(drawCount, #hand, HAND_MAX))
        Card.tirage(drawCount, true, 'HeroDeck')
    else
        print(("[draw] main déjà pleine (hand=%d / max=%d)"):format(#hand, HAND_MAX))
    end

    -- Pioche effectuée (ou inutile) → plus rien en attente
    gameplay._pendingDrawThisTurn = false
end

-- --------- Hooks de changement de tour ---------
local function onTurnChanged(newTour, prevTour)
    logf("[turn] %s -> %s", tostring(prevTour), tostring(newTour))

    -- Réinitialise les interactions cartes à chaque changement
    if Card and Card.resetInteractions then
        safecall("Card.resetInteractions", function() return Card.resetInteractions("turn-change") end)
    end

    if newTour == "player" then
        if actor and actor.tickEffects and Hero and Hero.actor then
            safecall("tickEffects(Hero)", function() return actor.tickEffects(Hero.actor) end)
        end
        refillPowerForHero()
        -- on tente tout de suite
        gameplay._pendingDrawThisTurn = false
        drawAtStartOfPlayerTurn()
        -- si bloqué par overlay, _pendingDrawThisTurn repasse à true
        watchdogEnemyHold = 0
    elseif newTour == "Enemy" then
        if actor and actor.tickEffects and Enemies and Enemies.curentEnemy then
            safecall("tickEffects(Enemy)", function() return actor.tickEffects(Enemies.curentEnemy) end)
        end
        refillPowerForEnemy()

        watchdogEnemyHold = 0
    elseif newTour == "transition" then
        log("[transition] entrée dans 'transition'")
    end
end

-- ========================
--        LIFECYCLE
-- ========================
function gameplay.load()
    log("[gameplay.load]")
    local heroDeck = Card.createDeck('HeroDeck')
    local enemyDeck = Card.createDeck('EnemyDeck')
    -- Acteurs / Effets
    safecall("Hero.load", function() return Hero and Hero.load and Hero.load() end)
    safecall("Enemies.load", function() return Enemies and Enemies.load and Enemies.load() end)
    safecall("effect.load", function() return effect and effect.load and effect.load() end)

    -- Decks
    if Card then
        log("[cards] load joueur")
        safecall("Card.loadCards(player)", function() return Card.loadCards(cardsPlayer, "Hero", "globalDeck") end)
        log("[cards] load IA")
        safecall("Card.loadCards(ai)", function() return Card.loadCards(cardsPlayer, "Enemy", "EnemyDeck") end)
    end

    if Card and Card.shuffleDeck then
        safecall("Card.shuffleDeck(Hero)", function() return Card.shuffleDeck("globalDeck") end)
        safecall("Card.shuffleDeck(Enemy)", function() return Card.shuffleDeck("EnemyDeck") end)
    end
    if Card and Card.MoveCardNumberCardDeckToDeck then
        safecall("Card.ensureMaxPlayerDeck(10)",
            function() return Card.MoveCardNumberCardDeckToDeck('globalDeck', 'HeroDeck', 10) end)
    end

    -- IA / Transition manager
    safecall("AI.load", function() return AI and AI.load and AI.load() end)
    safecall("Transition.load", function() return Transition and Transition.load and Transition.load() end)

    if heroDeck and enemyDeck and Card.hand and Card.graveyard then
        logf("[card] tailles -> player:%d  ai:%d  hand:%d  grave:%d",
            #heroDeck.cards, #enemyDeck.cards, #Card.hand.cards, #Card.graveyard.cards)
    end
end

function gameplay:update(dt)
    hud.update(dt)
    -- Transition manager (dot-call, dt numérique)
    safecall("Transition.update", function() return Transition.update and Transition.update(dt) end)

    -- Re-tirer une seule fois quand l’overlay se ferme (pendant le tour joueur)
    if Tour == "player" and gameplay._pendingDrawThisTurn and Transition and Transition.canDeal and Transition.canDeal() then
        drawAtStartOfPlayerTurn()
    end

    -- Détection entrée de tour
    if lastTour ~= Tour then
        onTurnChanged(Tour, lastTour)
        lastTour = Tour
    end

    -- Boucle par tour
    if Tour == "player" and Hero and Hero.actor and Hero.actor.state and not Hero.actor.state.dead then
        safecall("Card.hover", function() return Card and Card.hover and Card.hover(dt) end)
        safecall("Card.action.update",
            function() return Card and Card.action and Card.action.update and Card.action.update(dt) end)
        safecall("Card.update", function() return Card and Card.update and Card.update(dt) end)

        -- Ennemi mort durant le tour joueur → demander transition/récompense
        if Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state then
            local e = Enemies.curentEnemy.state
            if e.dead or (e.life or 0) <= 0 then
                log("[enemy] ennemi mort → demande fin de tour/récompense")
                if Transition and Transition.requestEndTurn then
                    safecall("Transition.requestEndTurn", function() return Transition.requestEndTurn() end)
                else
                    Tour = "transition"
                end
            end
        end
    elseif Tour == "Enemy" then
        safecall("AI.update", function() return AI and AI.update and AI:update(dt) end)

        --[[ safecall("Enemies.update", function() return Enemies and Enemies.update and Enemies.update(dt) end) ]]

        local done, reason = aiTurnIsOver()
        if done then
            watchdogEnemyHold = watchdogEnemyHold + dt
            if watchdogEnemyHold > WATCHDOG_LIMIT then
                logf("[watchdog] IA semble finie (raison=%s) → forcer fin de tour", tostring(reason))
                if Transition and Transition.requestEndTurn then
                    safecall("Transition.requestEndTurn", function() return Transition.requestEndTurn() end)
                else
                    Tour = "transition"
                end
                watchdogEnemyHold = 0
            else
                logf("[ai] fin possible (raison=%s) → attente %.2fs/%.2fs",
                    tostring(reason), watchdogEnemyHold, WATCHDOG_LIMIT)
            end
        else
            if watchdogEnemyHold ~= 0 then log("[ai] activité détectée, reset watchdog") end
            watchdogEnemyHold = 0
        end
    elseif Tour == "transition" then
        -- Pas de fallback ici : Transition Manager décide du passage.
        -- On autorise un hover visuel léger si tu veux
        safecall("Card.hover(transient)", function() return Card and Card.hover and Card.hover(dt) end)
    end
end

function gameplay.draw()
    safecall("Hero.draw", function() return Hero and Hero.draw and Hero.draw() end)
    safecall("Enemies.draw", function() return Enemies and Enemies.draw and Enemies.draw() end)
    safecall("Card.drawHand", function() return Card and Card.drawHand and Card.drawHand() end)

    safecall("AI.draw", function() return AI and AI.draw and AI.draw() end)
end

function gameplay.endTurn()
    local ok = false
    if Transition and Transition.requestEndTurn then
        ok = Transition.requestEndTurn()
    end
    print(ok and "[hud] fin de tour: OK" or "[hud] fin de tour: ignorée")
end

function gameplay.rezetGame()
    log("[reset] gameplay.rezetGame")
    if not Card then return end

    -- renvoie la main dans le deck
    for i = #Card.hand, 1, -1 do
        table.insert(Card.deck, table.remove(Card.hand, i))
    end

    -- remonte le cimetière si dispo
    if Card.func and Card.func.graveyardToMove then
        safecall("graveyardToMove(all→deck)", function() return Card.func.graveyardToMove("all", Card.deck) end)
    end

    -- reset acteurs
    if Enemies then
        Enemies.curentEnemy = {}
        safecall("Enemies.load", function() return Enemies.load and Enemies.load() end)
    end
    safecall("Hero.rezet", function() return Hero and Hero.rezet and Hero.rezet() end)

    Tour, lastTour, watchdogEnemyHold = "transition", "", 0
    safecall("Transition.load", function() return Transition and Transition.load and Transition.load() end)
end

return gameplay
