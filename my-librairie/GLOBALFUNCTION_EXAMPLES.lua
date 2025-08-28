-- Exemples d'utilisation de globalFunction pour éviter les duplications

-- ❌ AVANT : Code dupliqué partout
local function lerp_custom(a, b, t)
    local dt = love.timer.getDelta()
    -- code d'interpolation répété...
end

local function hover_check(x, y, w, h)
    local mx, my = love.mouse.getPosition()
    -- logique de hover répétée...
end

local function safe_log(msg)
    if debug_mode then print(msg) end
    -- code logging dispersé...
end

-- ✅ APRÈS : Utilisation de globalFunction
local gf = _G.globalFunction

-- Animation fluide (anti-jitter intégré)
local moved = gf.lerp(sprite.pos, target.pos, 10)

-- Détection hover robuste (avec scale support)
if gf.mouse.hover(btn.x, btn.y, btn.w, btn.h, screen.scale) then
    -- logique hover
end

-- Click front-edge (évite les clics multiples)
if gf.mouse.click() then
    -- action exécutée UNE seule fois par clic
end

-- Logging centralisé avec stack trace
gf.log.info("Carte jouée: " .. card.name)
gf.log.warn("Énergie faible: " .. player.energy)
gf.log.error("Impossible de charger: " .. filename)

-- Clone profond sécurisé
local cardCopy = gf.clone(originalCard)

-- Appel sécurisé avec gestion d'erreur
gf.safecall(function()
    card:onPlay(target)
end)

-- Debug rapide de table
gf.tstr(player.stats) -- Log tous les champs

-- Affichage barres de vie standardisé
gf.drawLifeBarStatus(enemy, "red")
gf.drawLifeBarStatus(hero, "bleu")

-- Raccourcis fin de tour automatiques
gf.endTurnHotkeys() -- E/Return/Space

-- Affichage logs en overlay (F12)
if gf.log.show then
    gf.drawLogs({ x = 10, y = 50, w = 600, h = 300 })
end

-- =========================================================
-- ✨ NOUVELLES FONCTIONS AJOUTÉES (éviter plus de duplication)
-- =========================================================

-- Math utilities (remplace les patterns répétés)
local healthRatio = gf.progress(player.health, player.maxHealth) -- au lieu de math.max(0, math.min(1, health/maxHealth))
local safeValue = gf.clamp(input, 0, 100)                        -- au lieu de math.max(0, math.min(100, input))
local mappedSpeed = gf.mapRange(distance, 0, 1000, 1, 10)        -- conversion d'échelle
local smoothMove = gf.lerpNum(current.x, target.x, 0.1)          -- lerp pour nombres simples

-- Table utilities (manipulation de données)
local hasCard = gf.contains(hand, selectedCard)
local cardIndex = gf.indexOf(deck, targetCard)
local validCards = gf.filter(cards, function(c) return c.cost <= energy end)
local cardNames = gf.map(cards, function(c) return c.name end)

-- String utilities (traitement de texte)
local words = gf.split("health,mana,energy", ",")
local cleanName = gf.trim(user_input)
local paddedScore = gf.pad(score, 6, "0") -- "000123"

-- Validation utilities (vérification robuste)
if gf.isNumber(damage) then
    -- utilise damage en sécurité
end

if gf.hasFields(actor, { "health", "maxHealth", "position" }) then
    -- l'acteur a tous les champs requis
end

local safeEnergy = gf.default(player.energy, 0) -- 0 si energy est nil
