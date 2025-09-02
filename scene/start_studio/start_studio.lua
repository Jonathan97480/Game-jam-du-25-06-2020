-- ============================================================================
-- SCÈNE START STUDIO - Logo d'introduction du studio
-- ============================================================================
-- Scène d'introduction affichant le logo du studio pendant 3-5 secondes
-- avec possibilité de skip et transition automatique vers le menu principal

local start_studio = {
    name = "start_studio",

    -- Configuration timing - DURÉE FINALE
    DISPLAY_DURATION = 3.0,  -- 3 secondes d'affichage
    FADE_IN_DURATION = 0.5,  -- Fade in rapide
    FADE_OUT_DURATION = 0.5, -- Fade out rapide

    -- Variables d'état
    timer = 0,
    phase = "fade_in", -- "fade_in", "display", "fade_out", "transition"
    alpha = 0,
    logo = nil,
    skipRequested = false,

    -- Cache audio si disponible
    startupSound = nil,
}

-- Chargement des ressources
function start_studio:load()
    local gf = _G.globalFunction
    if gf and gf.log then
        gf.log.info("🎬 Chargement scène Start Studio")
    end

    -- Chargement du logo studio
    local logoPath = "img/logoStudio/Sans titre-1.png"
    if love.filesystem.getInfo(logoPath) then
        self.logo = love.graphics.newImage(logoPath)
        if gf and gf.log then
            gf.log.info("✅ Logo studio chargé: " .. logoPath)
        end
    else
        if gf and gf.log then
            gf.log.warn("⚠️ Logo studio non trouvé: " .. logoPath)
        end
        -- Pas de logo trouvé, on utilisera un fallback texte
        self.logo = nil
    end

    -- Tentative de chargement du son de démarrage (optionnel)
    local soundPath = "audio/startup.ogg"
    if love.filesystem.getInfo(soundPath) then
        self.startupSound = love.audio.newSource(soundPath, "static")
        if gf and gf.log then
            gf.log.info("🔊 Son de démarrage chargé")
        end
    end

    -- Initialisation état
    self.timer = 0
    self.phase = "fade_in"
    self.alpha = 0
    self.skipRequested = false
end

-- Entrée dans la scène
function start_studio:enter(previous)
    local gf = _G.globalFunction
    if gf and gf.log then
        gf.log.info("🎬 Entrée scène Start Studio (depuis: " .. tostring(previous) .. ")")
    end

    -- Jouer le son de démarrage si disponible
    if self.startupSound then
        love.audio.play(self.startupSound)
    end

    -- Clear du HUD pour écran propre
    if _G.hud and _G.hud.clear then
        _G.hud.clear()
    end
end

-- Mise à jour logique
function start_studio:update(dt)
    local gf = _G.globalFunction

    -- Protection dt
    if gf and gf.clampDt then
        dt = gf.clampDt(dt)
    end

    -- Gestion du skip
    if self.skipRequested and self.phase ~= "transition" then
        self:startTransition()
        return
    end

    self.timer = self.timer + dt

    -- Machine à états pour les phases
    if self.phase == "fade_in" then
        -- Fade in progressif
        self.alpha = math.min(1, self.timer / self.FADE_IN_DURATION)

        if self.timer >= self.FADE_IN_DURATION then
            self.phase = "display"
            self.timer = 0
            self.alpha = 1
        end
    elseif self.phase == "display" then
        -- Affichage statique du logo
        if self.timer >= self.DISPLAY_DURATION then
            self.phase = "fade_out"
            self.timer = 0
        end
    elseif self.phase == "fade_out" then
        -- Fade out progressif
        self.alpha = math.max(0, 1 - (self.timer / self.FADE_OUT_DURATION))

        if self.timer >= self.FADE_OUT_DURATION then
            self:startTransition()
        end
    elseif self.phase == "transition" then
        -- Phase de transition (géré par le SceneManager)
        -- Rien à faire ici
    end
end

-- Gestion des entrées
function start_studio:keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    -- Skip sur n'importe quelle touche
    if key == "space" or key == "return" or key == "escape" or key == "z" or key == "x" then
        self:requestSkip()
    end
end

-- Gestion souris
function start_studio:mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Clic gauche
        self:requestSkip()
    end
end

-- Gestion gamepad
function start_studio:gamepadpressed(joystick, button)
    -- Skip sur n'importe quel bouton gamepad
    self:requestSkip()
end

-- Demande de skip
function start_studio:requestSkip()
    if not self.skipRequested and self.phase ~= "transition" then
        self.skipRequested = true

        local gf = _G.globalFunction
        if gf and gf.log then
            gf.log.info("⏭️ Skip demandé - transition vers menu")
        end
    end
end

-- Démarrage de la transition
function start_studio:startTransition()
    if self.phase == "transition" then
        return -- Éviter double transition
    end

    self.phase = "transition"

    local gf = _G.globalFunction
    if gf and gf.log then
        gf.log.info("🔄 Transition Start Studio → Menu")
    end

    -- Transition vers le menu principal
    if _G.scene and _G.scene.pop then
        -- Méthode recommandée: pop cette scène, le menu devrait déjà être en dessous
        _G.scene:pop()
        if gf and gf.log then
            gf.log.info("🎯 Scène start_studio supprimée, retour au menu")
        end
    elseif _G.scene and _G.scene.switch then
        -- Fallback: switch direct vers menu
        _G.scene:switch("menu")
        if gf and gf.log then
            gf.log.info("🔄 Fallback: switch vers menu")
        end
    else
        -- Fallback si scene manager non disponible
        local gf = _G.globalFunction
        if gf and gf.log then
            gf.log.error("❌ SceneManager non disponible pour transition")
        end
    end
end

-- Rendu visuel
function start_studio:draw()
    -- Utiliser les dimensions du jeu (1920x1080) au lieu de la fenêtre
    local screenWidth = screen.gameResolutionWidth or 1920
    local screenHeight = screen.gameResolutionHeight or 1080

    -- Fond noir
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Affichage du logo centré avec alpha OU fallback texte
    if self.logo then
        love.graphics.setColor(1, 1, 1, self.alpha)

        local logoWidth = self.logo:getWidth()
        local logoHeight = self.logo:getHeight()

        -- Calcul position centrée
        local x = (screenWidth - logoWidth) / 2
        local y = (screenHeight - logoHeight) / 2

        love.graphics.draw(self.logo, x, y)
    else
        -- Fallback texte si pas de logo
        love.graphics.setColor(1, 1, 1, self.alpha)

        -- Police pour le nom du studio
        local font = love.graphics.newFont(48)
        love.graphics.setFont(font)

        local studioText = "STUDIO DE DÉVELOPPEMENT"
        local textWidth = font:getWidth(studioText)
        local x = (screenWidth - textWidth) / 2
        local y = screenHeight / 2 - 30

        love.graphics.print(studioText, x, y)

        -- Sous-titre
        local smallFont = love.graphics.newFont(24)
        love.graphics.setFont(smallFont)

        local subText = "Présente"
        local subWidth = smallFont:getWidth(subText)
        local subX = (screenWidth - subWidth) / 2
        local subY = y + 60

        love.graphics.print(subText, subX, subY)
    end

    -- Indication skip en bas à droite (si pas en transition)
    if self.phase ~= "transition" and self.alpha > 0.5 then
        love.graphics.setColor(1, 1, 1, self.alpha * 0.7)

        -- Police pour le texte skip - utiliser police plus petite
        local font = love.graphics.newFont(16)
        love.graphics.setFont(font)

        local skipText = "Appuyez sur une touche pour passer"
        local textWidth = font:getWidth(skipText)

        -- Positionner en bas à droite avec marge suffisante
        local x = screenWidth - textWidth - 30
        local y = screenHeight - 40

        love.graphics.print(skipText, x, y)
    end

    -- Reset couleur
    love.graphics.setColor(1, 1, 1, 1)
end

-- Sortie de la scène
function start_studio:leave(next)
    local gf = _G.globalFunction
    if gf and gf.log then
        gf.log.info("🚪 Sortie scène Start Studio (vers: " .. tostring(next) .. ")")
    end

    -- Arrêter le son si encore en cours
    if self.startupSound and self.startupSound:isPlaying() then
        love.audio.stop(self.startupSound)
    end
end

-- Déchargement des ressources
function start_studio:unload()
    local gf = _G.globalFunction
    if gf and gf.log then
        gf.log.info("🗑️ Déchargement scène Start Studio")
    end

    -- Libération ressources
    self.logo = nil
    self.startupSound = nil

    -- Reset état
    self.timer = 0
    self.phase = "fade_in"
    self.alpha = 0
    self.skipRequested = false
end

-- Gestion pause (si scène mise en arrière-plan)
function start_studio:pause()
    if self.startupSound and self.startupSound:isPlaying() then
        love.audio.pause(self.startupSound)
    end
end

-- Gestion reprise
function start_studio:resume()
    -- Pas de reprise du son pour éviter confusion
    -- Le skip sera plus naturel
end

return start_studio
