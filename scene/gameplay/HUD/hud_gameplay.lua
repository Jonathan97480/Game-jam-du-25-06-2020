local hud_gameplay = {}
local hud = require("my-librairie/hud/hud")

local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if ok then return mod end
    return nil
end

-- debug: removed early dump (moved after panel creation so we capture created elements)

-- Prefer explicit requires instead of globals
local sceneManager = _safeRequire("my-librairie/core/sceneManager")
local Hero = _G.Hero or _safeRequire("my-librairie/entities/player/Hero")
local Card = _safeRequire("my-librairie/card-librairie/card")
local responsive = _G.screen or _safeRequire("my-librairie/utils/responsive")

local AM = _safeRequire("my-librairie/managers/actorManager") or rawget(_G, 'actorManager')
local TransitionCombat = _safeRequire("my-librairie/transitions/templateCombatTransition")
local function countByType()
    local bag = {}
    for _, e in ipairs(AM and AM.enemies or {}) do
        if e and e.type then bag[e.type] = (bag[e.type] or 0) + 1 end
    end
    return bag
end

function hud_gameplay.draw()
    local y = 20
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(("Ennemis: %d"):format(#(AM and AM.enemies or {})), 20, y)
    y = y + 16
    for t, n in pairs(countByType()) do
        love.graphics.print(("- " .. tostring(t) .. ": " .. tostring(n)), 20, y)
        y = y + 16
    end
    love.graphics.setColor(1, 1, 1)
end

local function safeEndTurn()
    print("🔥 safeEndTurn() APPELÉE !")

    -- Log pour confirmer l'appel
    pcall(function()
        local f = io.open("gameLogs/hud_clicks.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - 🔥 safeEndTurn() DÉBUT EXÉCUTION\n")
            f:close()
        end
    end)

    print("fin de tour demander")
    -- Prefer the Transition manager first (central end-turn flow)


    if TransitionCombat and type(TransitionCombat.requestEndTurn) == 'function' then
        pcall(function()
            local f = io.open("gameLogs/hud_clicks.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - safeEndTurn -> calling Transition.requestEndTurn (primary)\n"); f
                    :close()
            end
        end)
        pcall(TransitionCombat.requestEndTurn)
        return
    end

    -- Then try scene top().endTurn (scene-local handler)
    if sceneManager and type(sceneManager.top) == 'function' then
        local ok, top = pcall(function() return sceneManager:top() end)
        if ok and top and type(top.endTurn) == 'function' then
            pcall(function()
                local f = io.open("gameLogs/hud_clicks.log", "a")
                if f then
                    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - safeEndTurn -> calling top.endTurn (fallback)\n"); f
                        :close()
                end
            end)
            pcall(top.endTurn, top)
            return
        end
    end

    -- Finally fallback to requiring the gameplay module directly
    local _gameplay = _safeRequire("scene.gameplay.gameplay")
    if _gameplay and type(_gameplay.endTurn) == 'function' then
        pcall(function()
            local f = io.open("gameLogs/hud_clicks.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - safeEndTurn -> calling gameplay.endTurn (last fallback)\n"); f
                    :close()
            end
        end)
        pcall(_gameplay.endTurn, _gameplay)
        return
    end
end

function hud_gameplay.load()
    -- Force l'écriture d'un log même en cas d'erreur
    pcall(function()
        local f = io.open("gameLogs/hud_load_debug.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - [hud_gameplay.load] DÉBUT\n")
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud module: " .. tostring(hud) .. "\n")
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - hud.addButton: " .. tostring(hud.addButton) .. "\n")
            f:close()
        end
    end)

    -- prefer an explicit, safe require for the global helpers instead of reading _G
    local _globalFunction = _safeRequire("my-librairie.globalFunction") or _safeRequire("my-librairie/globalFunction")
    if _globalFunction and _globalFunction.log and _globalFunction.log.info then
        _globalFunction.log.info("[hud_gameplay] load called")
    else
        print("[hud_gameplay] load called")
        pcall(function()
            local f = io.open("gameLogs/hud_load_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - [hud_gameplay.load] globalFunction not available\n")
                f:close()
            end
        end)
    end

    -- Create a grouped panel with children so the scene can clear it in one call.
    local pw = (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
    local ph = (responsive and responsive.gameReso and responsive.gameReso.height) or 1080

    pcall(function()
        local f = io.open("gameLogs/hud_load_debug.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - [hud_gameplay.load] Avant hud.setPanel\n")
            f:close()
        end
    end)

    -- prepare dynamic values for initial labels
    local H = Hero or _safeRequire("my-librairie/entities/player/Hero")
    local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
    local CardLocal = Card or _safeRequire("my-librairie/card-librairie/card")
    local deckCount = tostring(#(CardLocal and CardLocal.deck or {}))
    local graveCount = tostring(#(CardLocal and CardLocal.graveyard or {}))

    local bottom_path = rawget(_G, "HUD_BOTTOM_BG_PATH") or 'img/hud/footer-bare.jpg'

    local success, err = pcall(function()
        -- Log avant création bouton
        pcall(function()
            local f = io.open("gameLogs/hud_load_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - Création bouton end_turn...\n")
                f:close()
            end
        end)

        -- Créer les éléments HUD directement sans panel englobant pour éviter le voile

        hud.addButton('end_turn', {
            img = 'img/hud/Button-fin-de-tour.png', -- Réactivé l'image du bouton
            x = 1400,                               -- Position horizontale (côté droit)
            y = 1000,                               -- Position Y vers le bas de l'écran (footer)
            w = 200,                                -- Largeur pour détection facile
            h = 100,                                -- Hauteur pour détection facile
            layer = 'button',
            text = 'FIN DE TOUR',                   -- Texte de secours si image ne charge pas
            bgColor = { 0.8, 0.8, 0.8, 1 },         -- Couleur normale
            hoverColor = { 0.9, 0.9, 0.9, 1 },      -- Couleur survol
            clickColor = { 0.7, 0.7, 0.7, 1 },      -- Couleur clic
            disabledColor = { 0.4, 0.4, 0.4, 0.5 }, -- Couleur désactivé
            textColor = { 1, 1, 1, 1 },             -- Couleur texte
            onClick = function()
                -- Vérifier si c'est le tour du joueur
                if _G.Tour ~= "player" then
                    print("⚠️ Ce n'est pas votre tour ! Tour actuel: " .. tostring(_G.Tour))
                    pcall(function()
                        local f = io.open("gameLogs/end_turn_clicks.log", "a")
                        if f then
                            f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                            " - ⚠️ Clic ignoré - pas le tour du joueur (tour: " .. tostring(_G.Tour) .. ")\n")
                            f:close()
                        end
                    end)
                    return -- Ignorer le clic
                end

                print("🔥🔥🔥 BOUTON END_TURN CLIQUÉ - SUCCESS !")
                pcall(function()
                    local f = io.open("gameLogs/end_turn_clicks.log", "a")
                    if f then
                        f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - 🔥🔥🔥 BOUTON END_TURN CLIQUÉ - SUCCESS !\n")
                        f:close()
                    end
                end)
                safeEndTurn()
            end
        })

        -- Debug: Log après création des boutons pour vérifier qu'ils existent
        pcall(function()
            local f = io.open("gameLogs/hud_creation_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - Boutons créés: test_button et end_turn\n")
                f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                    " - hud.getElement test_button: " ..
                    tostring(hud.getElement and hud.getElement('test_button')) .. "\n")
                f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                    " - hud.getElement end_turn: " .. tostring(hud.getElement and hud.getElement('end_turn')) .. "\n")
                f:close()
            end
        end)

        -- Log après création bouton
        pcall(function()
            local f = io.open("gameLogs/hud_load_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - Bouton end_turn créé avec succès\n")
                f:close()
            end
        end)

        hud.addImage('energy_icon', {
            img = 'img/hud/nombre de coup.png',
            x = 127,
            y = 745,
            layer = 'props'
        })

        hud.addLabel('energy_text', {
            text = tostring(val),
            x = 158,
            y = 768,
            layer = 'props'
        })

        hud.addImage('deck_icon', {
            img = 'img/hud/nombre de carte.png',
            x = 127,
            y = 827,
            layer = 'props'
        })

        hud.addLabel('deck_count', {
            text = deckCount,
            x = 130,
            y = 830,
            layer = 'props'
        })

        hud.addImage('grave_icon', {
            img = 'img/hud/Carte-simetiere.png',
            x = 127,
            y = 916,
            layer = 'props'
        })

        hud.addLabel('graveyard_count', {
            text = graveCount,
            x = 180,
            y = 975,
            layer = 'props'
        })

        hud.addButton('settings_btn', {
            img = 'img/hud/Button-Menu.png',
            x = 1854,
            y = 1024,
            layer = 'button',
            text = '',
            w = 64,
            h = 64,
            onClick = function()
                if sceneManager and sceneManager.switch and type(sceneManager.switch) == 'function' then
                    pcall(function()
                        sceneManager:switch('scene.menu.menu')
                    end)
                end
            end
        })

        -- Footer background restauré pour le bouton fin de tour
        hud.addImage('footer_bg', {
            img = bottom_path,
            x = 0,
            y = ph - 80,
            w = 3000,
            h = 128,
            layer = 'background'
        })
    end)

    pcall(function()
        local f = io.open("gameLogs/hud_load_debug.log", "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                " - [hud_gameplay.load] Après hud.setPanel - success=" .. tostring(success) .. "\n")
            if not success then
                f:write(os.date("%Y-%m-%d %H:%M:%S") .. " - [hud_gameplay.load] Erreur: " .. tostring(err) .. "\n")
            end
            f:close()
        end
    end)


    -- ensure icons and labels remain above the footer visually by placing them in props/button layers
    -- deck/grave icons and labels and energy already defined below; we ensure they exist and are children of the panel
    -- Post-creation debug dump: write current layers to a log so we can inspect what was actually created
    pcall(function()
        local f = io.open("gameLogs/layers_dump.log", "w")
        if f then
            f:write("layers dump after hud.setPanel:\n")
            if hud and hud._getLayers then
                local all = hud._getLayers()
                for lname, lst in pairs(all) do
                    f:write(string.format("LAYER %s -> count=%d\n", tostring(lname), #lst or 0))
                    for i = 1, (#lst or 0) do f:write("  " .. tostring(lst[i]) .. "\n") end
                end
            else
                f:write("hud._getLayers not available\n")
            end
            f:close()
        end
    end)
end

function hud_gameplay.update(dt)
    local H = Hero or _safeRequire("my-librairie/entities/player/Hero")
    local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
    hud.setText('energy_text', tostring(val))
    local CardLocal = Card or _safeRequire("my-librairie/card-librairie/card")
    hud.setText('deck_count', tostring(#(CardLocal and CardLocal.deck or {})))
    hud.setText('graveyard_count', tostring(#(CardLocal and CardLocal.graveyard or {})))

    -- Mettre à jour l'état visuel du bouton fin de tour selon le tour actuel
    local endTurnButton = hud and hud.get and hud.get('end_turn')
    if endTurnButton then
        local isPlayerTurn = (_G.Tour == "player")

        -- Mise à jour du texte selon l'état
        if isPlayerTurn then
            endTurnButton.text = "FIN DE TOUR"
            -- Couleurs normales (définies lors de la création)
            endTurnButton._isDisabled = false
        else
            local tourText = _G.Tour or "unknown"
            if tourText == "Enemy" then
                endTurnButton.text = "TOUR ENNEMI"
            elseif tourText == "transition" then
                endTurnButton.text = "TRANSITION..."
            else
                endTurnButton.text = "ATTENDEZ..."
            end
            -- Couleurs désactivées
            endTurnButton._isDisabled = true
        end

        -- Appliquer les couleurs selon l'état
        if endTurnButton._isDisabled then
            endTurnButton.bgColor = endTurnButton.disabledColor or { 0.4, 0.4, 0.4, 0.5 }
            endTurnButton.textColor = { 0.6, 0.6, 0.6, 1 }
        else
            endTurnButton.bgColor = { 0.8, 0.8, 0.8, 1 }
            endTurnButton.textColor = { 1, 1, 1, 1 }
        end
    end
end

return hud_gameplay
