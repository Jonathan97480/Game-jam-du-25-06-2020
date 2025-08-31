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
    -- prefer an explicit, safe require for the global helpers instead of reading _G
    local _globalFunction = _safeRequire("my-librairie.globalFunction") or _safeRequire("my-librairie/globalFunction")
    if _globalFunction and _globalFunction.log and _globalFunction.log.info then
        _globalFunction.log.info("[hud_gameplay] load called")
    else
        print("[hud_gameplay] load called")
    end
    -- Create a grouped panel with children so the scene can clear it in one call.
    local pw = (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
    local ph = (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
    -- prepare dynamic values for initial labels
    local H = Hero or _safeRequire("my-librairie/entities/player/Hero")
    local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
    local CardLocal = Card or _safeRequire("my-librairie/card-librairie/card")
    local deckCount = tostring(#(CardLocal and CardLocal.deck or {}))
    local graveCount = tostring(#(CardLocal and CardLocal.graveyard or {}))

    local bottom_path = rawget(_G, "HUD_BOTTOM_BG_PATH") or 'img/hud/footer-bare.jpg'

    hud.setPanel('game_panel', 0, 0, pw, ph, {
        layer = 'background',
        children = {
            { id = 'end_turn',        type = 'button', opts = { img = 'img/hud/Button-fin-de-tour.png', x = 1283, y = 1019, layer = 'button', text = 'End of Tours', tx = 1310, ty = 1035, onClick = safeEndTurn } },
            { id = 'energy_icon',     type = 'image',  opts = { img = 'img/hud/nombre de coup.png', x = 127, y = 745, layer = 'props' } },
            { id = 'energy_text',     type = 'label',  opts = { text = tostring(val), x = 158, y = 768, layer = 'props' } },
            { id = 'deck_icon',       type = 'image',  opts = { img = 'img/hud/nombre de carte.png', x = 127, y = 827, layer = 'props' } },
            { id = 'deck_count',      type = 'label',  opts = { text = deckCount, x = 130, y = 830, layer = 'props' } },
            { id = 'grave_icon',      type = 'image',  opts = { img = 'img/hud/Carte-simetiere.png', x = 127, y = 916, layer = 'props' } },
            { id = 'graveyard_count', type = 'label',  opts = { text = graveCount, x = 180, y = 975, layer = 'props' } },
            {
                id = 'settings_btn',
                type = 'button',
                opts = {
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
                }
            },
            -- footer background as a child of the game panel (anchored to bottom)
            { id = 'footer_bg', type = 'image', opts = { img = bottom_path, x = 0, y = ph - 80, w = 3000, h = 128, layer = 'background' } },
        }
    }, { type = 'container', color = nil })


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
end

return hud_gameplay
