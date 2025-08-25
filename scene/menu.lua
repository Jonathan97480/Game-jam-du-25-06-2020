-- scene/menu.lua

-- Fallbacks robustes (si les globals ne sont pas encore posés)
local screen      = rawget(_G, "screen") or require("my-librairie/responsive")
local scene       = rawget(_G, "scene") or require("my-librairie/sceneManager")

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

-- Boutons
menu.button = {

    play = {
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
        action = function()
            print("[menu] Play cliqué → switch vers gameplay")
            local ok, mod = pcall(require, "scene.gameplay")
            if not ok or not mod then
                print("[menu] require('scene.gameplay') a échoué :", tostring(mod))
                ok, mod = pcall(require, "scene/gameplay")
                if not ok or not mod then
                    print("[menu] require('scene/gameplay') a aussi échoué :", tostring(mod))
                    return
                end
            end
            scene:switch(mod) -- on passe la table directement
            scene:push("scene/hud_overlay")
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
        action = function()
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
        action = function()
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
    local isDown = false
    if input_ok and input and input.state then
        local s = input.state(); isDown = (s == 'pressed' or s == 'held')
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then isDown = iface.isActionDown() end
    end
    for _, value in pairs(menu.button) do
        local inside = (mx >= value.vector2.x) and (mx <= value.vector2.x + value.width) and (my >= value.vector2.y) and
            (my <= value.vector2.y + value.height)
        if inside then
            if isDown and not isclick then
                isclick = true
                value.color.curent = value.color.click
                value.action()
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
