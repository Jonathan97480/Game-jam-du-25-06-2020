local hud_gameplay = require("scene.gameplay.HUD.hud_gameplay")


-- Diagnostic: write a small marker when this module is required so we can
-- distinguish "require failed" vs "module loaded but crashed later".
pcall(function()
    local f = io.open("gameLogs/gameplay_entry.log", "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - required scene.gameplay.gameplay\n")
        f:close()
    end
end)
-- scene/gameplay.lua

local gameplay = {}
gameplay.config = require("scene.gameplay.config")

local DEBUG_GAMEPLAY = true
local function _to_text(...)
    local t = {}
    for i = 1, select('#', ...) do t[i] = tostring(select(i, ...)) end; return table.concat(t, ' ')
end
local function log(...)
    if not DEBUG_GAMEPLAY then return end
    local gf = rawget(_G, 'globalFunction')
    local txt = _to_text(...)
    if gf and gf.log and gf.log.info then
        gf.log.info(txt)
    else
        print(txt)
    end
end

local function logf(fmt, ...)
    if not DEBUG_GAMEPLAY then return end
    local gf = rawget(_G, 'globalFunction')
    local txt = string.format(fmt, ...)
    if gf and gf.log and gf.log.info then
        gf.log.info(txt)
    else
        print(txt)
    end
end

local function safecall(where, fn, ...)
    if type(fn) ~= "function" then
        if DEBUG_GAMEPLAY then logf("[safe] %s: fn=nil", where) end
        return nil
    end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        if DEBUG_GAMEPLAY then logf("[safe] %s: ERREUR -> %s", where, tostring(a)) end
        return nil
    end
    return a, b, c, d
end

local function AutoSPawnEnemy()
    local AM = actor or (_G.actorManager or require("my-librairie/actorManager"))
    if AM and AM.clearEnemies and AM.spawnEnemy then
        AM:clearEnemies()
        local cfg = (params and params.config) or gameplay.config or SceneConfig or {}
        local ec = cfg.enemies or {}

        if ec.spawns and type(ec.spawns) == 'table' and #ec.spawns > 0 then
            for _, s in ipairs(ec.spawns) do
                if s and s.type then
                    pcall(function() AM:spawnEnemy(s.type, { x = s.x, y = s.y }) end)
                end
            end
        else
            -- mode aléatoire / round robin
            local count = tonumber(ec.count) or 0
            local pool  = ec.pool or {}
            for i = 1, count do
                if #pool > 0 then
                    local t = pool[((i - 1) % #pool) + 1]
                    local x = 520 + (i - 1) * 64
                    local y = 360
                    pcall(function() AM:spawnEnemy(t, { x = x, y = y }) end)
                end
            end
        end
    end
end

-- Tour global piloté par le Transition Manager
Tour                    = Tour or "transition"
local lastTour          = ""
local watchdogEnemyHold = 0
local WATCHDOG_LIMIT    = 2.0

-- Modules
local Transition        = nil
local function getTransition()
    if Transition then return Transition end
    local ok, err = pcall(function() Transition = require("my-librairie/transition/templateCombatTransition") end)
    if not ok then
        logf("[Transition] ERREUR -> %s", tostring(err))
        Transition = nil
    end
    return Transition
end
local cardsPlayer = require("ressources/cards_data_player")
Hero              = require("my-librairie/ActorScripts/player/Hero")
Enemies           = require("my-librairie/ActorScripts/Enemy/Enemies")
local AI          = require("my-librairie/ai/controller")
local CardsIA     = require("ressources/cardsIA")
local actor       = _G.actorManager or require("my-librairie/actorManager")
local res         = require("my-librairie.resource_cache")

-- try to load scene-specific config (safe require)
local SceneConfig = nil
do
    local ok, cfg = pcall(require, 'scene.gameplay.config')
    if ok and type(cfg) == 'table' then
        SceneConfig = cfg
        -- write a small diagnostic so we can confirm at runtime
        pcall(function()
            local f = io.open("gameLogs/gameplay_config.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - loaded scene/gameplay/config.lua\n")
                f:close()
            end
        end)
    end
end

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
            -- wrap the call in a closure to ensure pcall receives a function
            local ok, res = pcall(function() return AI[fn](AI) end)
            if ok and res then return true, fn end
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
            log("[draw] bloqué: transition/overlay (pioche reportée)")
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
        logf("[draw] début de tour joueur → tirage %d (hand=%d → cible=%d)", drawCount, #hand, HAND_MAX)
        Card.tirage(drawCount, true, 'HeroDeck')
    else
        logf("[draw] main déjà pleine (hand=%d / max=%d)", #hand, HAND_MAX)
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
function gameplay.load(self, params)
    --Spawn enemies

    AutoSPawnEnemy()


    if hud_gameplay and hud_gameplay.load then hud_gameplay.load() end
    log("[gameplay.load]")
    -- attach scene config to module for runtime access
    gameplay.config = SceneConfig
    local heroDeck = Card.createDeck('HeroDeck')
    local enemyDeck = Card.createDeck('EnemyDeck')
    log("[debug] gameplay.load -> heroDeck=", tostring(heroDeck and heroDeck.name or nil), " enemyDeck=",
        tostring(enemyDeck and enemyDeck.name or nil))
    -- Acteurs / Effets
    safecall("Hero.load", function() return Hero and Hero.load and Hero.load() end)
    safecall("Enemies.load", function() return Enemies and Enemies.load and Enemies.load() end)
    safecall("effect.load", function() return effect and effect.load and effect.load() end)

    -- Auto-spawn enemies from scene config (params or gameplay.config)
    local AM = actor or (_G.actorManager or require("my-librairie/actorManager"))
    if AM and AM.clearEnemies and AM.spawnEnemy then
        AM:clearEnemies()
        local cfg = (params and params.config) or gameplay.config or SceneConfig or {}
        local ec = cfg.enemies or {}

        if ec.spawns and type(ec.spawns) == 'table' and #ec.spawns > 0 then
            for _, s in ipairs(ec.spawns) do
                if s and s.type then pcall(function() AM:spawnEnemy(s.type, { x = s.x, y = s.y }) end) end
            end
        else
            local count = tonumber(ec.count) or 0
            local pool  = ec.pool or {}
            if count > 0 and #pool == 0 then
                print("[warn] enemy config: count>0 but pool empty")
            end
            for i = 1, count do
                if #pool > 0 then
                    local t = pool[((i - 1) % #pool) + 1]
                    local x = 520 + (i - 1) * 64
                    local y = 360
                    pcall(function() AM:spawnEnemy(t, { x = x, y = y }) end)
                end
            end
        end
    end

    -- Decks
    if Card then
        log("[cards] load joueur")
        safecall("Card.loadCards(player)", function() return Card.loadCards(cardsPlayer, "Hero", "globalDeck") end)
        -- diagnostic: after loadCards, print deck sizes
        local gd = Card.getDeckByName and Card.getDeckByName('globalDeck')
        log("[debug] after loadCards -> globalDeck size=", gd and #gd.cards or 0)
        log("[cards] load IA")
        safecall("Card.loadCards(ai)", function() return Card.loadCards(CardsIA, "Enemy", "EnemyDeck") end)
        local ed = Card.getDeckByName and Card.getDeckByName('EnemyDeck')
        log("[debug] after loadCards IA -> EnemyDeck size=", ed and #ed.cards or 0)
    end

    if Card and Card.shuffleDeck then
        safecall("Card.shuffleDeck(Hero)", function() return Card.shuffleDeck("globalDeck") end)
        safecall("Card.shuffleDeck(Enemy)", function() return Card.shuffleDeck("EnemyDeck") end)
    end
    if Card and Card.MoveCardNumberCardDeckToDeck then
        safecall("Card.ensureMaxPlayerDeck(10)",
            function()
                log("[debug] before MoveCardNumberCardDeckToDeck -> globalDeck=",
                    (Card.getDeckByName and Card.getDeckByName('globalDeck')) and
                    #(Card.getDeckByName('globalDeck').cards) or 0,
                    " HeroDeck=",
                    (Card.getDeckByName and Card.getDeckByName('HeroDeck')) and #(Card.getDeckByName('HeroDeck').cards) or
                    0)
                local ok = Card.MoveCardNumberCardDeckToDeck('globalDeck', 'HeroDeck', 10)
                log("[debug] after MoveCardNumberCardDeckToDeck -> globalDeck=",
                    (Card.getDeckByName and Card.getDeckByName('globalDeck')) and
                    #(Card.getDeckByName('globalDeck').cards) or 0,
                    " HeroDeck=",
                    (Card.getDeckByName and Card.getDeckByName('HeroDeck')) and #(Card.getDeckByName('HeroDeck').cards) or
                    0,
                    " ok=", tostring(ok))
                return ok
            end)
    end

    -- Protection contre la dépendance circulaire
    if Transition == nil then Transition = getTransition() end
    if Transition and Transition.requestEndTurn then
        safecall("Transition.requestEndTurn", function() return Transition.requestEndTurn() end)
    end

    -- IA / Transition manager
    safecall("AI.load", function() return AI and AI.load and AI.load() end)
    safecall("Transition.load", function()
        if Transition == nil then Transition = getTransition() end
        -- diagnostic: log whether Transition was instantiated and GameFlags value
        pcall(function()
            local f = io.open("gameLogs/transition_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                    " - gameplay.load -> Transition present=" ..
                    tostring(Transition ~= nil) ..
                    " GameFlags.first_draft_done=" .. tostring((rawget(_G, 'GameFlags') or {}).first_draft_done) .. "\n")
                f:close()
            end
        end)
        return Transition and Transition.load and Transition:load()
    end)

    -- footer image for gameplay HUD (draw only on gameplay)
    if res and res.image then
        gameplay._footer = res.image('img/hud/footer-bare.jpg')
    end

    if heroDeck and enemyDeck and Card.hand and Card.graveyard then
        logf("[card] tailles -> player:%d  ai:%d  hand:%d  grave:%d",
            #heroDeck.cards, #enemyDeck.cards, #Card.hand.cards, #Card.graveyard.cards)
    end

    -- push HUD overlay only when entering gameplay
    do
        local hud_module = nil
        local try_names = { "scene.hud_overlay.hud_overlay", "scene/hud_overlay/hud_overlay", "scene.hud_overlay",
            "scene/hud_overlay" }
        local require_errors = {}
        for _, name in ipairs(try_names) do
            local ok, mod_or_err = pcall(require, name)
            if ok and mod_or_err then
                hud_module = mod_or_err
                break
            else
                table.insert(require_errors, string.format("require('%s') -> %s", tostring(name), tostring(mod_or_err)))
            end
        end
        if hud_module and scene and scene.add then
            local inst = scene:add(hud_module)
            -- scene:add does not call load(); ensure HUD is initialized now
            if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
        else
            -- fallback: let sceneManager resolve the module string (it tries many variants)
            if scene and scene.add then
                local inst = scene:add("scene.hud_overlay.hud_overlay") or scene:add("scene/hud_overlay/hud_overlay")
                if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
                -- if still missing, persist require_errors for diagnosis
                if not inst then
                    pcall(function()
                        local f = io.open("gameLogs/hud_presence.log", "a")
                        if f then
                            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - initial require attempts:\n")
                            for _, e in ipairs(require_errors) do f:write(e .. "\n") end
                            f:close()
                        end
                    end)
                end
            end
        end
    end

    -- dump current scene stack for debug
    pcall(function()
        local f = io.open("gameLogs/scene_list.log", "w")
        if f then
            if scene and scene.get then
                local lst = scene:get()
                f:write("scene stack dump:\n")
                for i = 1, #lst do f:write(tostring(i) .. ": " .. tostring(lst[i].name or lst[i].id or "unnamed") .. "\n") end
            else
                f:write("scene manager not available\n")
            end
            f:close()
        end
    end)

    -- Ensure HUD overlay is present: if missing, try to add it and log the action
    pcall(function()
        local present = false
        if scene and scene.get then
            for i, sc in ipairs(scene:get()) do
                if sc and (sc.name == 'hud_overlay' or sc.id == 'hud_overlay') then
                    present = true; break
                end
            end
        end
        local f = io.open("gameLogs/hud_presence.log", "a")
        if f then
            if present then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay already present\n")
            else
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay missing -> attempting to add\n")
                local hud_module = nil
                local try_names = { "scene.hud_overlay.hud_overlay", "scene/hud_overlay/hud_overlay", "scene.hud_overlay",
                    "scene/hud_overlay" }
                for _, name in ipairs(try_names) do
                    local ok2, mod2 = pcall(require, name)
                    if ok2 and mod2 then
                        hud_module = mod2; break
                    end
                end
                if hud_module and scene and scene.add then
                    local inst2 = scene:add(hud_module)
                    if inst2 and type(inst2.load) == 'function' then pcall(inst2.load, inst2) end
                    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay added fallback\n")
                else
                    -- try letting sceneManager resolve the module by string
                    if scene and scene.add then
                        local inst2 = scene:add("scene.hud_overlay.hud_overlay") or
                            scene:add("scene/hud_overlay/hud_overlay")
                        if inst2 then
                            if inst2 and type(inst2.load) == 'function' then pcall(inst2.load, inst2) end
                            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay added via sceneManager fallback\n")
                        else
                            -- Write detailed require diagnostics to the log for investigation
                            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay require/add failed\n")
                            f:write("Tried names:\n")
                            local try_names = { "scene.hud_overlay.hud_overlay", "scene/hud_overlay/hud_overlay",
                                "scene.hud_overlay", "scene/hud_overlay" }
                            for _, name in ipairs(try_names) do
                                local ok2, mod2 = pcall(require, name)
                                f:write(string.format("require('%s') -> ok=%s result=%s\n", tostring(name), tostring(ok2),
                                    tostring(mod2)))
                            end
                        end
                    else
                        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay require/add failed\n")
                    end
                end
            end
            f:close()
        end
    end)

    -- NOTE: debug auto-draw removed to ensure overlay_start shows the player's full deck
end

function gameplay:update(dt)
    if hud_gameplay and hud_gameplay.update then hud_gameplay.update(dt) end
    hud.update(dt)
    -- Transition manager (dot-call, dt numérique)
    if Transition == nil then Transition = getTransition() end
    if Transition then Transition:update(dt) end

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
    -- Ensure per-scene HUD is drawn (background + elements). Use protected calls so missing HUD
    -- modules won't crash the game; we'll try per-scene hud_gameplay first, then the generic hud.
    safecall("hud_gameplay.draw", function()
        return hud_gameplay and hud_gameplay.draw and hud_gameplay.draw()
    end)

    safecall("HUD.drawBackground", function()
        local ok, hudm = pcall(require, "my-librairie.hud.hud")
        if ok and hudm and hudm.drawBackground then return hudm.drawBackground() end
        return nil
    end)

    safecall("HUD.draw", function()
        local ok, hudm = pcall(require, "my-librairie.hud.hud")
        if ok and hudm and hudm.draw then return hudm.draw() end
        return nil
    end)

    -- footer drawing is now handled by HUD (bottom_bar_bg)
end

function gameplay.endTurn()
    local ok = false
    if Transition and Transition.requestEndTurn then
        ok = Transition.requestEndTurn()
    end
    log((ok and "[hud] fin de tour: OK") or "[hud] fin de tour: ignorée")
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
    safecall("Transition.load", function() return Transition and Transition.load and Transition:load() end)
end

return gameplay
