-- scene/menu.lua

-- Fallbacks robustes (si les globals ne sont pas encore posés)
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
local scene  = rawget(_G, "scene") or require("my-librairie/sceneManager")

-- helper de log local : utilise globalFunction.log.info si présent, sinon print
local function _log(...)
    if rawget(_G, 'globalFunction') and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

local menu        = {}
menu.illustration = {}

--[[ Arrière-plan & titre ]]
menu.illustration.background = {
    img = love.graphics.newImage('img/Menu/BackGround.jpg'),
    vector2 = { x = 0, y = 0 }
}

menu.illustration.title = {
    img = love.graphics.newImage('img/Menu/Titre.png'),
    vector2 = {
        x = screen.gameReso.width / 2,
        y = screen.gameReso.height / 0.5
    }
}

-- Footer (barre en bas)
-- footer removed from menu; drawn only in gameplay

-- Boutons
menu.button = {

    play = {
        cmd = 'play',
        texte = 'Play',
        width = 180,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (1 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        --[[
    Fonction : action
    Rôle : Lance la scène de gameplay via le gestionnaire.
    Paramètres : (aucun)
    Retour : aucune valeur (nil).
    ]]
        action = function(btn)
            -- btn correspond au bouton cliqué (transmis depuis menu.hover)
            if btn and btn.cmd == 'play' then
                _log("[menu] Play cliqué → switch vers gameplay")
                -- Utiliser scene:switch pour demander au sceneManager de charger la scène
                local okSwitch, tgt = pcall(function() return scene:switch("scene.gameplay") end)
                if not okSwitch or not tgt then
                    _log("[menu] scene:switch('scene.gameplay') a échoué, tentative alternative")
                    local okSwitch2, tgt2 = pcall(function() return scene:switch("scene/gameplay") end)
                    if not okSwitch2 or not tgt2 then
                        _log("[menu] impossible de switcher vers gameplay : aucune require/switch n'a fonctionné")
                    end
                end
            end
        end

    },

    credit = {
        texte = 'Credit',
        width = 240,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (2 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            -- Si tu as une scène credits, décommente la ligne suivante :
            -- scene:switch("scene.credits")
            print("[menu] TODO: scène 'credits' non configurée.")
        end
    },

    quit = {
        texte = 'Quit',
        width = 180,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (3 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            love.window.close()
        end
    }
}

-- REQUIRE (si besoin, ajoute ici d'autres modules locaux au menu)

-- VARIABLE
local isclick = false

--[[
Fonction : menu.load
Rôle : Prépare l’écran de menu (pas de pré-chargement du gameplay ici).
Paramètres : (aucun)
Retour : nil
]]
function menu.load()
    -- rien de spécial pour l’instant
end

--[[
Fonction : menu.update
Rôle : Gestion du hover/click sur les boutons.
Paramètres :
  - dt : nombre
Retour : nil
]]
function menu.update(dt)
    menu.hover()
end

--[[
Fonction : menu.draw
Rôle : Affiche le menu.
Paramètres : (aucun)
Retour : nil
]]
function menu.draw()
    love.graphics.draw(menu.illustration.background.img, 0, 0)
    -- footer: centré en bas
    if menu.illustration.footer and menu.illustration.footer.img then
        local f = menu.illustration.footer.img
        local fh = (type(f.getHeight) == 'function' and f:getHeight()) or 0
        love.graphics.draw(f, 0, screen.gameReso.height - fh)
    end
    love.graphics.draw(menu.illustration.title.img, menu.illustration.title.vector2.x, menu.illustration.title.vector2.y)

    for _, value in pairs(menu.button) do
        love.graphics.setColor(value.color.curent)
        love.graphics.setNewFont(60)
        love.graphics.print(value.texte, value.vector2.x, value.vector2.y)
    end
    love.graphics.setColor(1, 1, 1)
end

--[[
Fonction : menu.hover
Rôle : Survol & clic gauche pour déclencher l’action du bouton.
Paramètres : (aucun)
Retour : nil
]]
function menu.hover()
    local input_ok, input = pcall(require, "my-librairie/inputManager")
    local okc, cursor = pcall(require, "my-librairie/cursor")
    local mx, my = 0, 0
    if okc and cursor and cursor.get then mx, my = cursor.get() end
    -- detecter un "just pressed" (appui) plutôt que l'état pressed/held pour éviter
    -- les problèmes de timing dus à l'ordre d'update
    local isClickNow = false
    if input_ok and input and input.justPressed then
        isClickNow = input.justPressed()
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.justPressedAction then isClickNow = iface.justPressedAction() end
    end
    for _, value in pairs(menu.button) do
        local inside = (mx >= value.vector2.x) and (mx <= value.vector2.x + value.width) and (my >= value.vector2.y) and
            (my <= value.vector2.y + value.height)
        if inside then
            if isClickNow and not isclick then
                isclick = true
                value.color.curent = value.color.click
                -- transmettre le bouton courant à la fonction d'action
                value.action(value)
                break
            else
                value.color.curent = value.color.hover
                isclick = false
            end
            break
        elseif isclick then
            isclick = false
            break
        else
            value.color.curent = value.color.normal
        end
    end
end

return menu
