--- Module de gestion de la scène de gameplay.
-- Ce module orchestre le cycle de tour, la pioche, l’IA ennemie, le HUD et la transition combat.
-- @module scene.gameplay.gameplay

local hud_gameplay_ok, hud_gameplay = pcall(require, "scene.gameplay.HUD.hud_gameplay")
if not hud_gameplay_ok then
    print("[ERROR] Failed to load hud_gameplay:", hud_gameplay)
    hud_gameplay = nil
else
    print("[SUCCESS] hud_gameplay loaded successfully")
end

----------------------------------------------------------------------
-- Autres dépendances de gameplay
----------------------------------------------------------------------
local cardsPlayer = require("ressources/cards_data_player")
local Hero        = _G.Hero or require("my-librairie/entities/player/Hero")
local Enemies     = _G.Enemies or require("my-librairie.entities.Enemy.Enemies")
local AI          = require("my-librairie/ai/controller")
local actor       = _G.actorManager or require("my-librairie/managers/actorManager")
local res         = require("my-librairie.managers.resource_cache")

----------------------------------------------------------------------
-- Diagnostics initiaux (permet de distinguer un require qui échoue d’un crash plus tard)
----------------------------------------------------------------------
pcall(function()
    local f = io.open("gameLogs/gameplay_entry.log", "a")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - required scene.gameplay.gameplay\n")
        f:close()
    end
end)

----------------------------------------------------------------------
-- Déclarations / dépendances
----------------------------------------------------------------------
local gameplay = {}

-- Transition combat (safe require si _G.TransitionCombat absent)
local TransitionCombat = _G.TransitionCombat or _safeRequire("my-librairie/transitions/templateCombatTransition")

-- Configuration de scène
gameplay.config = require("scene.gameplay.config")

-- Débogage local
local DEBUG_GAMEPLAY = true

-- Utilitaires log
local function _to_text(...)
    local t = {}
    for i = 1, select('#', ...) do
        t[i] = tostring(select(i, ...))
    end
    return table.concat(t, ' ')
end

--- Log simple (info).
-- N’écrit que si DEBUG_GAMEPLAY=true. Utilise globalFunction.log.info si dispo, sinon print.
-- @tparam any ... Liste de valeurs à concaténer et afficher
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

--- Log formaté façon printf.
-- @tparam string fmt Format string
-- @tparam any ... Arguments de format
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

--- Appel protégé d’une fonction.
-- @tparam string where Contexte (pour les logs)
-- @tparam[opt] function fn Fonction à appeler
-- @tparam any ... Arguments passés à la fonction
-- @return a,b,c,d Retours de la fonction si OK, sinon nil
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

----------------------------------------------------------------------
-- Spawning ennemis (auto)
----------------------------------------------------------------------

--- Fait apparaître les ennemis en fonction de la configuration de scène.
-- Utilise soit des points de spawn explicites, soit un round-robin simple.
local function auto_spawn_enemies()
    if not (actor and actor.clearEnemies and actor.spawnEnemy) then return end

    actor:clearEnemies()

    local cfg = (params and params.config) or gameplay.config or SceneConfig or {}
    local enemy_cfg = cfg.enemies or {}

    -- Spawns explicites
    if enemy_cfg.spawns and type(enemy_cfg.spawns) == 'table' and #enemy_cfg.spawns > 0 then
        for _, spawn in ipairs(enemy_cfg.spawns) do
            if spawn and spawn.type then
                pcall(function() actor:spawnEnemy(spawn, enemy_cfg.poolEnemies, enemy_cfg.options) end)
            end
        end
        return
    end

    -- Mode round-robin / aléatoire simple
    local count = tonumber(enemy_cfg.count) or 0
    local pool  = enemy_cfg.pool or {}
    for i = 1, count do
        if #pool > 0 then
            local t = pool[((i - 1) % #pool) + 1]
            local x = 520 + (i - 1) * 64
            local y = 360
            pcall(function() actor:spawnEnemy(t, { x = x, y = y }) end)
        end
    end
end

----------------------------------------------------------------------
-- États globaux (pilote de tour via Transition Manager)
----------------------------------------------------------------------

Tour                 = Tour or "transition"
local last_tour      = ""
local watchdog_enemy = 0
local WATCHDOG_LIMIT = 2.0



-- Chargement optionnel d’une config scène (safe)
local SceneConfig = nil
do
    local ok, cfg = pcall(require, 'scene.gameplay.config')
    if ok and type(cfg) == 'table' then
        SceneConfig = cfg
        pcall(function()
            local f = io.open("gameLogs/gameplay_config.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - loaded scene/gameplay/config.lua\n")
                f:close()
            end
        end)
    end
end

----------------------------------------------------------------------
-- Règles de pioche
----------------------------------------------------------------------
local HAND_MAX                = 5
local DRAW_MODE               = "fill" -- "fill" pour remplir jusqu’à HAND_MAX, sinon tirage fixe
local DRAW_PER_TURN           = 1

-- Flag : tirage en attente (ex: overlay/transition bloque la distribution)
gameplay._pendingDrawThisTurn = false

----------------------------------------------------------------------
-- Utilitaires gameplay (énergie, IA)
----------------------------------------------------------------------

--- Réinitialise la puissance du héros à son maximum.
local function refill_power_hero()
    local maxp = (Hero and Hero.actor and Hero.actor.state and (Hero.actor.state.powerMax or 8)) or 8
    if Hero and Hero.actor and Hero.actor.state then
        Hero.actor.state.power = maxp
        logf("[power] Hero power reset -> %d", maxp)
    end
end

--- Réinitialise la puissance de l’ennemi courant à son maximum.
local function refill_power_enemy()
    if Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state then
        local emax = Enemies.curentEnemy.state.powerMax or Enemies.curentEnemy.state.power or 3
        Enemies.curentEnemy.state.power = emax
        logf("[power] Enemy power reset -> %d", emax)
    end
end

--- Détermine si le tour IA est terminé (robuste à différentes implémentations d’AI).
-- @treturn bool done Vrai si l’IA a terminé
-- @treturn string reason Indice/raison pour diagnostic
local function ai_turn_is_over()
    if not AI then return true, "AI=nil" end
    if AI.updateReturn == true or AI.updateReturn == "done" then return true, "updateReturn" end

    local checks = { "isFinish", "isFinished", "isTurnFinished", "done", "finished", "turnEnded", "canEndTurn" }
    for _, fn in ipairs(checks) do
        if type(AI[fn]) == "function" then
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

----------------------------------------------------------------------
-- Pioche au début du tour joueur (différée si overlay bloque)
----------------------------------------------------------------------

--- Déclenche la pioche de début de tour joueur selon la config de tirage.
local function draw_start_of_player_turn()
    if not Card or not Card.tirage then return end

    -- Si transition/overlay bloque, on mémorise l’intention et on reviendra plus tard
    if TransitionCombat and TransitionCombat.canDeal and not TransitionCombat.canDeal() then
        if not gameplay.__overlayBlockWarned then
            log("[draw] bloqué: transition/overlay (pioche reportée)")
            gameplay.__overlayBlockWarned = true
        end
        gameplay._pendingDrawThisTurn = true
        return
    end
    gameplay.__overlayBlockWarned = false

    local hand = (Card.handList and Card.handList()) or Card.hand or {}
    local draw_count
    if DRAW_MODE == "fill" then
        draw_count = math.max(0, HAND_MAX - #hand)
    else
        draw_count = DRAW_PER_TURN
    end

    if draw_count > 0 then
        logf("[draw] début de tour joueur → tirage %d (hand=%d → cible=%d)", draw_count, #hand, HAND_MAX)
        Card.tirage(draw_count, true, 'HeroDeck')
    else
        logf("[draw] main déjà pleine (hand=%d / max=%d)", #hand, HAND_MAX)
    end

    gameplay._pendingDrawThisTurn = false
end

----------------------------------------------------------------------
-- Gestion des transitions de tour
----------------------------------------------------------------------

--- Callback interne déclenché à chaque changement de tour.
-- @tparam string new_tour Nouveau tour ("player" | "Enemy" | "transition")
-- @tparam string prev_tour Ancien tour
local function on_turn_changed(new_tour, prev_tour)
    logf("[turn] %s -> %s", tostring(prev_tour), tostring(new_tour))

    -- Reset interactions de cartes
    if Card and Card.resetInteractions then
        safecall("Card.resetInteractions", function() return Card.resetInteractions("turn-change") end)
    end

    if new_tour == "player" then
        if actor and actor.tickEffects and Hero and Hero.actor then
            safecall("tickEffects(Hero)", function() return actor.tickEffects(Hero.actor) end)
        end
        refill_power_hero()
        gameplay._pendingDrawThisTurn = false
        draw_start_of_player_turn()
        watchdog_enemy = 0
    elseif new_tour == "Enemy" then
        if actor and actor.tickEffects and Enemies and Enemies.curentEnemy then
            safecall("tickEffects(Enemy)", function() return actor.tickEffects(Enemies.curentEnemy) end)
        end
        refill_power_enemy()
        watchdog_enemy = 0
    elseif new_tour == "transition" then
        log("[transition] entrée dans 'transition'")
    end
end

----------------------------------------------------------------------
-- Cycle de vie : load / update / draw
----------------------------------------------------------------------

--- Charge la scène de gameplay (acteurs, decks, HUD, transitions).
-- @tparam table self Référence scène
-- @tparam[opt] table params Paramètres d’initialisation
function gameplay.load(self, params)
    -- Apparition des ennemis
    auto_spawn_enemies()

    -- Expose la config de scène
    gameplay.config  = SceneConfig

    -- Decks de base
    local hero_deck  = Card and Card.createDeck and Card.createDeck('HeroDeck')
    local enemy_deck = Card and Card.createDeck and Card.createDeck('EnemyDeck')
    log("[debug] gameplay.load -> heroDeck=", tostring(hero_deck and hero_deck.name or nil),
        " enemyDeck=", tostring(enemy_deck and enemy_deck.name or nil))

    -- Acteurs / Effets
    safecall("Hero.load", function() return Hero and Hero.load and Hero.load() end)
    safecall("Enemies.load", function() return Enemies and Enemies.load and Enemies.load() end)
    safecall("effect.load", function() return effect and effect.load and effect.load() end)

    -- Chargement des cartes joueur
    if Card then
        log("[cards] load joueur")
        safecall("Card.loadCards(player)", function() return Card.loadCards(cardsPlayer, "Hero", "globalDeck") end)
        local gd = Card.getDeckByName and Card.getDeckByName('globalDeck')
        log("[debug] after loadCards -> globalDeck size=", gd and #gd.cards or 0)
    end

    -- Mélanges & distribution initiale vers HeroDeck
    if Card and Card.shuffleDeck then
        safecall("Card.shuffleDeck(Hero)", function() return Card.shuffleDeck("globalDeck") end)
        safecall("Card.shuffleDeck(Enemy)", function() return Card.shuffleDeck("EnemyDeck") end)
    end
    if Card and Card.MoveCardNumberCardDeckToDeck then
        safecall("Card.ensureMaxPlayerDeck(10)", function()
            log("[debug] before MoveCardNumberCardDeckToDeck -> globalDeck=",
                (Card.getDeckByName and Card.getDeckByName('globalDeck')) and
                #(Card.getDeckByName('globalDeck').cards) or 0,
                " HeroDeck=",
                (Card.getDeckByName and Card.getDeckByName('HeroDeck')) and
                #(Card.getDeckByName('HeroDeck').cards) or 0)
            local ok = Card.MoveCardNumberCardDeckToDeck('globalDeck', 'HeroDeck', 10)
            log("[debug] after MoveCardNumberCardDeckToDeck -> globalDeck=",
                (Card.getDeckByName and Card.getDeckByName('globalDeck')) and
                #(Card.getDeckByName('globalDeck').cards) or 0,
                " HeroDeck=",
                (Card.getDeckByName and Card.getDeckByName('HeroDeck')) and
                #(Card.getDeckByName('HeroDeck').cards) or 0,
                " ok=", tostring(ok))
            return ok
        end)
    end

    -- Demande de fin de tour initiale si TransitionCombat la supporte (sécurise l’état)
    if TransitionCombat and TransitionCombat.requestEndTurn then
        safecall("Transition.requestEndTurn", function() return TransitionCombat.requestEndTurn() end)
    end

    -- Transition manager (instanciation/chargement)
    safecall("Transition.load", function()
        pcall(function()
            local f = io.open("gameLogs/transition_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                    " - gameplay.load -> Transition present=" ..
                    tostring(TransitionCombat ~= nil) ..
                    " GameFlags.initial_draft_completed=" ..
                    tostring((rawget(_G, 'GameFlags') or {}).initial_draft_completed) .. "\n")
                f:close()
            end
        end)
        return TransitionCombat and TransitionCombat.load and TransitionCombat:load()
    end)

    -- Ressources HUD (footer uniquement en gameplay)
    if res and res.image then
        gameplay._footer = res.image('img/hud/footer-bare.jpg')
    end

    if hero_deck and enemy_deck and Card and Card.hand and Card.graveyard then
        logf("[card] tailles -> player:%d  ai:%d  hand:%d  grave:%d",
            #hero_deck.cards, #enemy_deck.cards, #Card.hand.cards, #Card.graveyard.cards)
    end

    ------------------------------------------------------------------
    -- push HUD overlay only when entering gameplay (STRICT PATH)
    ------------------------------------------------------------------
    do
        local hud_module
        local ok, mod_or_err = pcall(require, "scene/hud_overlay/hud_overlay")
        if ok and mod_or_err then
            hud_module = mod_or_err
        end

        if hud_module and scene and scene.add then
            local inst = scene:add(hud_module)
            if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
        else
            -- dernier recours: add via la même chaîne exacte
            if scene and scene.add then
                local inst = scene:add("scene/hud_overlay/hud_overlay")
                if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
            end
        end

        log("[DEBUG] hud_gameplay check: " .. tostring(hud_gameplay ~= nil))
        if hud_gameplay then
            log("[DEBUG] hud_gameplay.load check: " .. tostring(hud_gameplay.load ~= nil))
            if hud_gameplay.load then
                log("[DEBUG] Calling hud_gameplay.load()")
                hud_gameplay.load()
                log("[DEBUG] hud_gameplay.load() completed")
            else
                log("[DEBUG] hud_gameplay.load is nil!")
            end
        else
            log("[DEBUG] hud_gameplay is nil!")
        end
        log("[gameplay.load]")
    end

    -- Dump pile des scènes pour debug
    pcall(function()
        local f = io.open("gameLogs/scene_list.log", "w")
        if f then
            if scene and scene.get then
                local lst = scene:get()
                f:write("scene stack dump:\n")
                for i = 1, #lst do
                    f:write(tostring(i) .. ": " .. tostring(lst[i].name or lst[i].id or "unnamed") .. "\n")
                end
            else
                f:write("scene manager not available\n")
            end
            f:close()
        end
    end)

    ------------------------------------------------------------------
    -- Ensure HUD overlay is present (STRICT PATH)
    ------------------------------------------------------------------
    pcall(function()
        local present = false
        if scene and scene.get then
            for _, sc in ipairs(scene:get()) do
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
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay missing -> adding (strict path)\n")

                local ok, hud_module = pcall(require, "scene/hud_overlay/hud_overlay")
                if ok and hud_module and scene and scene.add then
                    local inst = scene:add(hud_module) or scene:add("scene/hud_overlay/hud_overlay")
                    if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
                    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay added\n")
                else
                    if scene and scene.add then
                        local inst = scene:add("scene/hud_overlay/hud_overlay")
                        if inst and type(inst.load) == 'function' then pcall(inst.load, inst) end
                        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud_overlay add via string attempted\n")
                    end
                end
            end
            f:close()
        end
    end)
end

--- Mise à jour par frame de la scène gameplay.
-- @tparam number dt Delta time
function gameplay:update(dt)
    if hud_gameplay and hud_gameplay.update then hud_gameplay.update(dt) end

    -- Ciblage de cartes
    local CardTargetSelection = rawget(_G, "CardTargetSelection")
    if CardTargetSelection and CardTargetSelection.update then
        CardTargetSelection.update(dt)
    end

    -- Transition manager
    if TransitionCombat then TransitionCombat:update(dt) end

    -- Pioche différée si l’overlay vient de se libérer
    if Tour == "player" and gameplay._pendingDrawThisTurn and TransitionCombat and TransitionCombat.canDeal and TransitionCombat.canDeal() then
        draw_start_of_player_turn()
    end

    -- Détection changement de tour
    if last_tour ~= Tour then
        on_turn_changed(Tour, last_tour)
        last_tour = Tour
    end

    -- Boucle par tour
    if Tour == "player" and Hero and Hero.actor and Hero.actor.state and not Hero.actor.state.dead then
        safecall("Card.hover", function() return Card and Card.hover and Card.hover(dt) end)
        safecall("Card.action.update",
            function() return Card and Card.action and Card.action.update and Card.action.update(dt) end)
        safecall("Card.update", function() return Card and Card.update and Card.update(dt) end)

        -- Ennemi mort → transition / récompense
        if Enemies and Enemies.curentEnemy and Enemies.curentEnemy.state then
            local e = Enemies.curentEnemy.state
            if e.dead or (e.life or 0) <= 0 then
                log("[enemy] ennemi mort → demande fin de tour/récompense")
                if TransitionCombat and TransitionCombat.requestEndTurn then
                    safecall("TransitionCombat.requestEndTurn", function() return TransitionCombat.requestEndTurn() end)
                else
                    Tour = "transition"
                end
            end
        end
    elseif Tour == "Enemy" then
        safecall("AI.update", function() return AI and AI.update and AI:update(dt) end)

        local done, reason = ai_turn_is_over()
        if done then
            watchdog_enemy = watchdog_enemy + dt
            if watchdog_enemy > WATCHDOG_LIMIT then
                logf("[watchdog] IA semble finie (raison=%s) → forcer fin de tour", tostring(reason))
                if TransitionCombat and TransitionCombat.requestEndTurn then
                    safecall("TransitionCombat.requestEndTurn", function() return TransitionCombat.requestEndTurn() end)
                else
                    Tour = "transition"
                end
                watchdog_enemy = 0
            else
                logf("[ai] fin possible (raison=%s) → attente %.2fs/%.2fs",
                    tostring(reason), watchdog_enemy, WATCHDOG_LIMIT)
            end
        else
            if watchdog_enemy ~= 0 then log("[ai] activité détectée, reset watchdog") end
            watchdog_enemy = 0
        end
    elseif Tour == "transition" then
        -- Transition Manager pilote le passage de tour ; on peut laisser un hover visuel léger
        safecall("Card.hover(transient)", function() return Card and Card.hover and Card.hover(dt) end)
    end
end

--- Dessin de la scène gameplay.
function gameplay.draw()
    safecall("Hero.draw", function() return Hero and Hero.draw and Hero.draw() end)
    safecall("Enemies.draw", function() return Enemies and Enemies.draw and Enemies.draw() end)
    safecall("Card.drawHand", function() return Card and Card.drawHand and Card.drawHand() end)
    safecall("AI.draw", function() return AI and AI.draw and AI.draw() end)
    safecall("hud_gameplay.draw", function() return hud_gameplay and hud_gameplay.draw and hud_gameplay.draw() end)
    -- Le footer est géré côté HUD (bottom_bar_bg)
end

--- Demande de fin de tour (relayée au Transition Manager).
function gameplay.endTurn()
    local ok = false
    if TransitionCombat and TransitionCombat.requestEndTurn then
        ok = TransitionCombat.requestEndTurn()
    end
    log((ok and "[hud] fin de tour: OK") or "[hud] fin de tour: ignorée")
end

--- Réinitialise complètement la partie (deck, cimetière, acteurs, transition).
function gameplay.resetGame()
    log("[reset] gameplay.resetGame")
    if not Card then return end

    -- Remet la main dans le deck
    for i = #Card.hand, 1, -1 do
        table.insert(Card.deck, table.remove(Card.hand, i))
    end

    -- Remonte le cimetière si dispo
    if Card.func and Card.func.graveyardToMove then
        safecall("graveyardToMove(all→deck)", function() return Card.func.graveyardToMove("all", Card.deck) end)
    end

    -- Reset acteurs
    if Enemies then
        Enemies.curentEnemy = {}
        safecall("Enemies.load", function() return Enemies.load and Enemies.load() end)
    end
    safecall("Hero.rezet", function() return Hero and Hero.rezet and Hero.rezet() end) -- conserve l’API existante

    Tour, last_tour, watchdog_enemy = "transition", "", 0
    safecall("Transition.load",
        function() return TransitionCombat and TransitionCombat.load and TransitionCombat:load() end)
end

----------------------------------------------------------------------
-- Événements souris (ciblage)
----------------------------------------------------------------------

--- Gestion du clic souris côté gameplay (redirigé vers le système de ciblage).
-- @tparam table self Contexte
-- @tparam number x
-- @tparam number y
-- @tparam integer button
-- @treturn boolean handled True si géré par le système de ciblage
function gameplay.mousepressed(self, x, y, button)
    local CardTargetSelection = rawget(_G, "CardTargetSelection")
    logf("[gameplay] mousepressed: CardTargetSelection=%s, handleMouseClick=%s",
        tostring(CardTargetSelection),
        tostring(CardTargetSelection and CardTargetSelection.handleMouseClick))

    if CardTargetSelection and CardTargetSelection.handleMouseClick then
        logf("[gameplay] Appel handleMouseClick(%d,%d,%d)", x, y, button)
        local handled = CardTargetSelection.handleMouseClick(x, y, button)
        logf("[gameplay] handleMouseClick retourné: %s", tostring(handled))
        if handled then
            logf("[gameplay] Clic géré par système de ciblage: (%d,%d) button=%d", x, y, button)
            return true
        end
    end

    -- Si le clic n'est pas géré par le système de cartes, essayer le HUD
    local hud = rawget(_G, "hud")
    logf("[gameplay] DEBUG: hud=%s", tostring(hud))
    if hud then
        logf("[gameplay] DEBUG: hud.hover=%s", tostring(hud.hover))
    end
    if hud and hud.hover then
        logf("[gameplay] Transmission du clic au HUD: (%d,%d) button=%d", x, y, button)
        logf("[gameplay] DEBUG: Avant appel hud.hover(click, %d, %d)", x, y)
        local hudHandled = hud.hover("click", x, y)
        logf("[gameplay] DEBUG: Après appel hud.hover, résultat: %s", tostring(hudHandled))
        logf("[gameplay] HUD a géré le clic: %s", tostring(hudHandled))
        if hudHandled then
            return true
        end
    else
        logf("[gameplay] ERREUR: HUD non disponible ou hud.hover manquant")
    end

    return false
end

return gameplay
