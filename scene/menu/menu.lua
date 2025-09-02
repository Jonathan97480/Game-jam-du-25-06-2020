-- scene/menu.lua

-- Accès aux globales centralisées (chargées via my-librairie/globals.lua)
local screen         = _G.screen
local scene          = _G.scene
local globalFunction = _G.globalFunction

-- helper de log local : utilise globalFunction.log.info si présent, sinon print
local function _log(...)
    if globalFunction and globalFunction.log and globalFunction.log.info then
        globalFunction.log.info(...)
    else
        print(...)
    end
end

local menu        = {}
menu.illustration = {}

-- Custom transition script for the menu scene (slide + fade)
menu.transition   = {
    durationOut = 0.4,
    durationIn  = 0.45,
    maskInput   = true,
    easingOut   = function(x) return x ^ 3 end,
    easingIn    = function(x) return 1 - (1 - x) ^ 3 end,
    drawOut     = function(p, ctx)
        local w, h = ctx.w, ctx.h
        love.graphics.push("all")
        love.graphics.translate(-p * w * 0.4, 0)
        love.graphics.pop()
        love.graphics.setColor(0, 0, 0, p * 0.6)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end,
    drawIn      = function(p, ctx)
        local w, h = ctx.w, ctx.h
        love.graphics.push("all")
        love.graphics.translate((1 - p) * w * 0.3, 0)
        love.graphics.pop()
        love.graphics.setColor(0, 0, 0, (1 - p) * 0.4)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end,
}

local res         = require("my-librairie.managers.resource_cache")

--[[ Arrière-plan & titre ]]
menu.illustration.background = {
    img = res.image('img/Menu/BackGround.jpg'),
    vector2 = { x = 0, y = 0 }
}

menu.illustration.title = {
    img = res.image('img/Menu/Titre.png'),
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

                -- Vérification des globales
                if not scene then
                    _log("[menu] ERREUR: scene global n'est pas disponible")
                    return
                end

                if not scene.switchWithTransition then
                    _log("[menu] ERREUR: scene.switchWithTransition n'existe pas")
                    return
                end

                -- Tentative de chargement des différents chemins possibles pour gameplay
                local gameplayPaths = {
                    "scene.gameplay.gameplay",
                    "scene/gameplay/gameplay",
                    "scene.gameplay",
                    "scene/gameplay"
                }

                local gameplayLoaded = false
                for _, path in ipairs(gameplayPaths) do
                    local ok, gameplayScene = pcall(require, path)
                    if ok and gameplayScene then
                        _log("[menu] Gameplay trouvé avec le chemin: " .. path)
                        local switchOk, result = pcall(function()
                            return scene:switchWithTransition(path, {})
                        end)
                        if switchOk then
                            _log("[menu] Switch réussi vers: " .. path)
                            gameplayLoaded = true
                            break
                        else
                            _log("[menu] Échec du switch vers " .. path .. ": " .. tostring(result))
                        end
                    else
                        _log("[menu] Impossible de charger: " .. path .. " (" .. tostring(gameplayScene) .. ")")
                    end
                end

                if not gameplayLoaded then
                    _log("[menu] ERREUR: Impossible de charger la scène de gameplay")
                    _log("[menu] Vérifiez que scene/gameplay/gameplay.lua existe et fonctionne")
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

    multilingual = {
        texte = 'Multilingual Demo',
        width = 320,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (3 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[menu] Multilingual Demo cliqué → switch vers example_multilingual")

            if not scene then
                _log("[menu] ERREUR: scene global n'est pas disponible")
                return
            end

            -- Chargement de la scène de démonstration multilingue
            local ok, result = pcall(function()
                return scene:switch("scene.example_multilingual")
            end)

            if not ok then
                -- Essayer avec le chemin alternatif
                local ok2, result2 = pcall(function()
                    return scene:switch("scene/example_multilingual")
                end)

                if not ok2 then
                    _log("[menu] ERREUR: Impossible de charger la scène multilingue")
                    _log("[menu] Erreur 1: " .. tostring(result))
                    _log("[menu] Erreur 2: " .. tostring(result2))
                else
                    _log("[menu] Scène multilingue chargée avec succès (chemin 2)")
                end
            else
                _log("[menu] Scène multilingue chargée avec succès (chemin 1)")
            end
        end
    },

    save_demo = {
        texte = 'Save System Demo',
        width = 320,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (4 * 80) },
        color = {
            curent = { 1, 1, 1 },
            hover  = { 0, 1, 0 },
            normal = { 1, 1, 1 },
            click  = { 1, 0, 0 },
        },
        action = function(_)
            _log("[menu] Save System Demo cliqué → switch vers demo_save")

            if not scene then
                _log("[menu] ERREUR: scene global n'est pas disponible")
                return
            end

            -- Chargement de la scène de démonstration sauvegarde
            local ok, result = pcall(function()
                return scene:switch("scene.demo_save.demo_save")
            end)

            if not ok then
                -- Essayer avec le chemin alternatif
                local ok2, result2 = pcall(function()
                    return scene:switch("scene/demo_save/demo_save")
                end)

                if not ok2 then
                    _log("[menu] ERREUR: Impossible de charger la scène de démonstration sauvegarde")
                    _log("[menu] Erreur 1: " .. tostring(result))
                    _log("[menu] Erreur 2: " .. tostring(result2))
                else
                    _log("[menu] Scène démonstration sauvegarde chargée avec succès (chemin 2)")
                end
            else
                _log("[menu] Scène démonstration sauvegarde chargée avec succès (chemin 1)")
            end
        end
    },

    quit = {
        texte = 'Quit',
        width = 180,
        height = 60,
        vector2 = { x = 60, y = screen.gameReso.height / 2 + (5 * 80) },
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
        love.graphics.setFont(res.font(60))
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
    -- Utiliser les globales pour l'input si disponible
    local gf = _G.globalFunction
    local mx, my = 0, 0

    -- Récupération de la position de la souris
    -- Priorité à inputInterface (module centralisé pour l'input)
    local okI, iface = pcall(require, "my-librairie/inputInterface")
    if okI and iface and iface.getCursor then
        local c = iface.getCursor()
        mx, my = (c and c.x) or 0, (c and c.y) or 0
    else
        -- fallback to _G.cursor if present (compatibilité)
        if _G.cursor and type(_G.cursor) == "table" and type(_G.cursor.get) == "function" then
            local x, y = _G.cursor.get()
            mx, my = x, y
        else
            -- try globalFunction.mouse.hover as a last resort
            if gf and gf.mouse and gf.mouse.hover then
                local hx, hy = gf.mouse.hover()
                if type(hx) == 'number' and type(hy) == 'number' then
                    mx, my = hx, hy
                else
                    mx, my = 0, 0
                end
            else
                mx, my = 0, 0
            end
        end
    end

    -- Détection du clic avec globalFunction en priorité
    local isClickNow = false
    if gf and gf.mouse and gf.mouse.click then
        isClickNow = gf.mouse.click() == true -- Force boolean conversion
    else
        -- Fallback sur inputManager
        local input_ok, input = pcall(require, "my-librairie/inputManager")
        if input_ok and input and input.justPressed then
            isClickNow = input.justPressed()
        else
            -- Dernier fallback
            local okI, iface = pcall(require, "my-librairie/inputInterface")
            if okI and iface and iface.justPressedAction then
                isClickNow = iface.justPressedAction()
            end
        end
    end
    print(mx, my)
    for _, value in pairs(menu.button) do
        local inside = (mx >= value.vector2.x) and (mx <= value.vector2.x + value.width) and (my >= value.vector2.y) and
            (my <= value.vector2.y + value.height)
        if inside then
            if isClickNow and not isclick then
                isclick = true
                value.color.curent = value.color.click
                -- Logs de debug pour voir si le clic est détecté
                _log("[menu] Clic détecté sur bouton: " .. (value.cmd or value.texte or "inconnu"))
                -- transmettre le bouton courant à la fonction d'action
                if value.action then
                    value.action(value)
                else
                    _log("[menu] ERREUR: bouton sans fonction action")
                end
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
