-- Configuration centrale pour la librairie de cartes
-- Modifier ces valeurs pour régler l'apparence et le comportement des cartes
local Config = {}

-- Taille par défaut des cartes (px)
Config.CARD_W = 337
Config.CARD_H = 462

-- Scale de base
Config.SCALE_BASE = 0.50

-- Offset appliqué au dessin de la main (x, y)
-- utile pour corriger position après changement d'ancrage
Config.HAND_DRAW_OFFSET = { x = -50, y = -200 }

-- Hover : scale et hauteur du 'lift' au survol
Config.HOVER = {
    SCALE = 2,
    HEIGHT = 80
}

-- Animation : vitesses / lissage
Config.ANIM = {
    SMOOTH_SPEED = 10,
    LERP = 12
}

-- Options DEAL (tirage initial)
Config.DEAL = {
    ENABLED = true,
    FROM = 'left',
    DURATION = 0.35,
    STAGGER = 0.08,
    HOP = 12
}

Config.STANDBY = {
    --POSITION LEFT SCREEN
    standbyX = 50,
    standbyY = 400,
    scaleX = 0.8,
    scaleY = 0.8,
    animationSpeed = 10,

    DEBUG_ENABLED = true,
    DURATION = 0.15,
    --au play card self
    AUTO_CONFIRM = 2,
    fontPath = 'fonts/PANICKO.ttf',
    fontSize = 24

}

return Config
