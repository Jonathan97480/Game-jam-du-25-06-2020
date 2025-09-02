-- Scene exemple pour démonstration du système multilingue
local sceneExampleMultilingual = {
    name = "scene_example_multilingual"
}

function sceneExampleMultilingual:load()
    print("Scène multilingue chargée")
end

function sceneExampleMultilingual:enter()
    -- Vider le HUD
    if _G.hud then
        _G.hud.clear()
    end

    -- Récupérer la fonction de traduction globale
    local t = _G.t or function(key) return key end

    -- Interface en français (langue par défaut)
    local titleText = t("ui.menu.title")               -- "Menu Principal"
    local playButtonText = t("ui.button.play")         -- "Jouer"
    local settingsButtonText = t("ui.button.settings") -- "Paramètres"
    local quitButtonText = t("ui.button.quit")         -- "Quitter"

    -- Messages dynamiques avec variables
    local playerName = "Héros"
    local currentLevel = 5
    local welcomeMessage = t("messages.welcome", { name = playerName, level = currentLevel })
    -- "Bienvenue Héros ! Niveau: 5"

    -- Description de carte avec formatage spécialisé
    local cardName = t("cards.fireball.name")               -- "Boule de feu"
    local cardDescription = t("cards.fireball.description") -- "Inflige 3 dégâts de feu à l'ennemi ciblé"

    -- Ajout HUD avec traductions
    if _G.hud then
        -- Titre principal
        _G.hud.addLabel("title", {
            layer = "props",
            x = 400,
            y = 50,
            text = titleText,
            font = 36,
            color = { 1, 1, 1 }
        })

        -- Message de bienvenue
        _G.hud.addLabel("welcome", {
            layer = "props",
            x = 400,
            y = 120,
            text = welcomeMessage,
            font = 20,
            color = { 0.8, 0.8, 1 }
        })

        -- Boutons principaux
        _G.hud.addButton("btn_play", {
            layer = "button",
            x = 350,
            y = 200,
            w = 100,
            h = 40,
            text = playButtonText,
            callback = function()
                print("Bouton jouer cliqué - " .. playButtonText)
            end
        })

        _G.hud.addButton("btn_settings", {
            layer = "button",
            x = 350,
            y = 250,
            w = 100,
            h = 40,
            text = settingsButtonText,
            callback = function()
                print("Bouton paramètres cliqué - " .. settingsButtonText)
            end
        })

        _G.hud.addButton("btn_quit", {
            layer = "button",
            x = 350,
            y = 300,
            w = 100,
            h = 40,
            text = quitButtonText,
            callback = function()
                print("Bouton quitter cliqué - " .. quitButtonText)
            end
        })

        -- Bouton changement de langue
        _G.hud.addButton("btn_lang_fr", {
            layer = "button",
            x = 50,
            y = 400,
            w = 80,
            h = 30,
            text = "Français",
            callback = function()
                if _G.LocalizationManager then
                    _G.LocalizationManager:setLanguage("fr")
                    -- Recharger la scène pour appliquer les traductions
                    self:refreshTranslations()
                end
            end
        })

        _G.hud.addButton("btn_lang_en", {
            layer = "button",
            x = 140,
            y = 400,
            w = 80,
            h = 30,
            text = "English",
            callback = function()
                if _G.LocalizationManager then
                    _G.LocalizationManager:setLanguage("en")
                    -- Recharger la scène pour appliquer les traductions
                    self:refreshTranslations()
                end
            end
        })

        -- Exemple de carte traduite
        _G.hud.addLabel("card_name", {
            layer = "card",
            x = 600,
            y = 200,
            text = cardName,
            font = 24,
            color = { 1, 0.8, 0.2 }
        })

        _G.hud.addLabel("card_desc", {
            layer = "card",
            x = 600,
            y = 230,
            text = cardDescription,
            font = 14,
            color = { 0.9, 0.9, 0.9 }
        })

        -- Informations sur la langue actuelle
        local currentLang = _G.LocalizationManager and _G.LocalizationManager:getCurrentLanguage() or "fr"
        local langInfo = "Langue actuelle: " .. (currentLang == "fr" and "Français" or "English")
        _G.hud.addLabel("lang_info", {
            layer = "decor",
            x = 50,
            y = 50,
            text = langInfo,
            font = 16,
            color = { 0.7, 0.7, 0.7 }
        })
    end
end

function sceneExampleMultilingual:refreshTranslations()
    -- Méthode pour recharger les traductions après changement de langue
    if _G.hud then
        _G.hud.clear()
    end
    self:enter() -- Recharger la scène avec nouvelles traductions
end

function sceneExampleMultilingual:update(dt)
    -- Mise à jour de la scène
end

function sceneExampleMultilingual:draw()
    -- Fond simple
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Scène de démonstration système multilingue", 10, love.graphics.getHeight() - 60)
    love.graphics.print("Utilisez les boutons 'Français' et 'English' pour changer de langue", 10,
        love.graphics.getHeight() - 40)
    love.graphics.print("Appuyez sur ECHAP pour retourner au menu", 10, love.graphics.getHeight() - 20)
end

function sceneExampleMultilingual:keypressed(key)
    if key == "escape" then
        -- Retour au menu
        if _G.scene then
            _G.scene:switch("scene/menu/menu")
        end
    end
end

function sceneExampleMultilingual:leave()
    -- Nettoyage
    if _G.hud then
        _G.hud.clear()
    end
end

function sceneExampleMultilingual:unload()
    print("Scène multilingue déchargée")
end

return sceneExampleMultilingual
