--[[
==========================================
    CARD MANAGER - SYSTÈME CENTRALISÉ
==========================================
Ce module centralise TOUTE la logique de manipulation des cartes pour :
- Éviter les conflits entre modules
- Contrôler précisément le repositionnement
- Isoler les bugs de ciblage
- Avoir une source unique de vérité

Responsabilités :
- Gestion des positions des cartes
- Système de protection contre repositionnement
- Interface unifiée pour tous les modules
- Logging centralisé des opérations
==========================================
]] --

local CardManager = {}

-- === CHARGEMENT SÉCURISÉ DES DÉPENDANCES ===
-- Pour éviter les dépendances circulaires, on utilise un require sécurisé
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

-- Dépendances chargées de manière différée
local Common = nil
local function _getCommon()
    if not Common then
        Common = _safeRequire("my-librairie/card-librairie/core/common")
    end
    return Common
end

-- === ÉTAT GLOBAL ===
local _state = {
    -- Protection contre repositionnement
    repositioning_locked = false,
    repositioning_lock_time = 0, -- Timestamp du verrouillage
    targeting_active = false,
    targeting_start_time = 0,    -- Timestamp début ciblage

    -- Cartes en cours de manipulation
    cards_being_played = {},
    cards_being_targeted = {},

    -- Historique des positions
    position_history = {},

    -- Configuration timeout
    max_repositioning_lock_time = 5, -- 5 secondes max
    max_targeting_time = 10,         -- 10 secondes max pour ciblage

    -- Flags de debug
    debug_enabled = rawget(_G, "DEBUG_CARD_MANAGER") or false
}

-- === LOGGING ===
local function _log(level, fmt, ...)
    local gf = rawget(_G, 'globalFunction')
    local text = string.format("[CardManager] " .. fmt, ...)

    if gf and gf.log then
        if level == "info" then
            gf.log.info(text)
        elseif level == "warn" then
            gf.log.warn(text)
        elseif level == "error" then
            gf.log.error(text)
        end
    else
        print(text)
    end
end

local function _logInfo(fmt, ...) _log("info", fmt, ...) end
local function _logWarn(fmt, ...) _log("warn", fmt, ...) end
local function _logError(fmt, ...) _log("error", fmt, ...) end

-- === GESTION DES TIMEOUTS ===

-- Fonction pour vérifier et débloquer les timeouts
function CardManager.checkTimeouts()
    local current_time = os.time()
    local any_timeout = false

    -- Vérifier timeout repositionnement
    if _state.repositioning_locked and _state.repositioning_lock_time > 0 then
        local lock_duration = current_time - _state.repositioning_lock_time
        if lock_duration > _state.max_repositioning_lock_time then
            _logWarn("⏰ TIMEOUT REPOSITIONNEMENT - Déverrouillage automatique après %ds", lock_duration)
            CardManager.unlockRepositioning("timeout automatique")
            any_timeout = true
        end
    end

    -- Vérifier timeout ciblage
    if _state.targeting_active and _state.targeting_start_time > 0 then
        local targeting_duration = current_time - _state.targeting_start_time
        if targeting_duration > _state.max_targeting_time then
            _logWarn("⏰ TIMEOUT CIBLAGE - Nettoyage automatique après %ds", targeting_duration)
            _state.targeting_active = false
            _state.targeting_start_time = 0
            -- Nettoyer toutes les cartes en cours de ciblage
            for name, data in pairs(_state.cards_being_targeted) do
                if data.card then
                    CardManager.restoreCardPosition(data.card, "timeout ciblage")
                end
            end
            _state.cards_being_targeted = {}
            CardManager.unlockRepositioning("timeout ciblage")
            any_timeout = true
        end
    end

    return any_timeout
end

-- Fonction d'urgence pour débloquer manuellement
function CardManager.emergencyUnlock(reason)
    _logWarn("🚨 DÉBLOCAGE D'URGENCE: %s", reason or "manuel")
    _state.repositioning_locked = false
    _state.repositioning_lock_time = 0
    _state.targeting_active = false
    _state.targeting_start_time = 0
    _state.cards_being_targeted = {}
    _logInfo("🆘 État réinitialisé - Repositionnement libre")
end

-- === UTILITAIRES DE PROTECTION ===

function CardManager.isTargetingActive()
    -- Vérifier timeout avant de retourner l'état
    CardManager.checkTimeouts()
    local CardTargetSelection = rawget(_G, "CardTargetSelection")
    return CardTargetSelection and CardTargetSelection.isSelectingTarget
end

function CardManager.isRepositioningLocked()
    -- Vérifier timeout avant de retourner l'état
    CardManager.checkTimeouts()
    return _state.repositioning_locked or CardManager.isTargetingActive()
end

function CardManager.lockRepositioning(reason)
    _logWarn("🔒 REPOSITIONNEMENT VERROUILLÉ: %s", reason or "raison non spécifiée")
    _state.repositioning_locked = true
    _state.repositioning_lock_time = os.time() -- Timestamp du verrouillage
end

function CardManager.unlockRepositioning(reason)
    _logInfo("🔓 REPOSITIONNEMENT DÉVERROUILLÉ: %s", reason or "raison non spécifiée")
    _state.repositioning_locked = false
    _state.repositioning_lock_time = 0 -- Reset timestamp
end

-- === GESTION DES CARTES EN JEU ===

function CardManager.markCardAsPlaying(card, reason)
    if not card then return end

    _logInfo("🎯 CARTE MARQUÉE EN JEU: %s - Raison: %s",
        card.name or "sans nom", reason or "non spécifiée")

    card._playing = true
    card._cardManager_playing = true
    card._cardManager_reason = reason

    _state.cards_being_played[card.name or tostring(card)] = {
        card = card,
        reason = reason,
        timestamp = os.time()
    }
end

function CardManager.unmarkCardAsPlaying(card, reason)
    if not card then return end

    _logInfo("✅ CARTE LIBÉRÉE DU JEU: %s - Raison: %s",
        card.name or "sans nom", reason or "non spécifiée")

    card._playing = false
    card._cardManager_playing = false
    card._cardManager_reason = nil

    _state.cards_being_played[card.name or tostring(card)] = nil
end

function CardManager.isCardPlaying(card)
    if not card then return false end
    return card._playing or card._cardManager_playing
end

-- === GESTION DES POSITIONS ===

function CardManager.saveCardPosition(card, reason)
    if not card then return end

    local key = card.name or tostring(card)
    _state.position_history[key] = {
        x = card.vector2.x,
        y = card.vector2.y,
        scale_x = card.scale.x,
        scale_y = card.scale.y,
        reason = reason,
        timestamp = os.time()
    }

    _logInfo("💾 POSITION SAUVÉE: %s (%.1f, %.1f) - %s",
        card.name or "carte", card.vector2.x, card.vector2.y, reason or "")
end

function CardManager.restoreCardPosition(card, reason)
    if not card then return false end

    local key = card.name or tostring(card)
    local saved = _state.position_history[key]

    if saved then
        card.vector2.x = saved.x
        card.vector2.y = saved.y
        card.scale.x = saved.scale_x
        card.scale.y = saved.scale_y

        _logInfo("🔄 POSITION RESTAURÉE: %s (%.1f, %.1f) - %s",
            card.name or "carte", saved.x, saved.y, reason or "")
        return true
    end

    _logWarn("❌ AUCUNE POSITION SAUVÉE POUR: %s", card.name or "carte")
    return false
end

-- === REPOSITIONNEMENT SÉCURISÉ ===

function CardManager.updateHandTargets(caller, force)
    local caller_info = caller or "inconnu"

    _logInfo("🎯 DEMANDE updateHandTargets de: %s (force=%s)", caller_info, tostring(force))

    -- Vérification automatique des timeouts à chaque appel
    local timeout_occurred = CardManager.checkTimeouts()
    if timeout_occurred then
        _logInfo("⏰ Timeout détecté et traité automatiquement")
    end

    -- Vérifications de protection
    if not force and CardManager.isRepositioningLocked() then
        _logWarn("🛡️  REPOSITIONNEMENT BLOQUÉ - Raison: %s",
            _state.repositioning_locked and "verrouillé manuellement" or "ciblage actif")
        return false
    end

    -- Récupérer Common de manière sécurisée
    local Common = _getCommon()
    if not Common or not Common.hand or not Common.hand.cards then
        _logError("❌ Common non disponible ou hand.cards inexistant")
        return false
    end

    -- Compter les cartes protégées
    local protected_count = 0
    local total_cards = #Common.hand.cards

    for i = 1, total_cards do
        local card = Common.hand.cards[i]
        if CardManager.isCardPlaying(card) then
            protected_count = protected_count + 1
            _logInfo("🛡️  Carte protégée: %s", card.name or "sans nom")
        end
    end

    _logInfo("📊 BILAN: %d cartes protégées sur %d total", protected_count, total_cards)

    -- Appel effectif si autorisé
    if Common._updateHandTargets then
        _logInfo("✅ REPOSITIONNEMENT AUTORISÉ par: %s", caller_info)
        Common._updateHandTargets()
        return true
    else
        _logError("❌ _updateHandTargets non disponible")
        return false
    end
end -- === INTERFACE POUR play.lua ===

function CardManager.onCardPlayStart(card, reason)
    CardManager.saveCardPosition(card, "avant jeu")
    CardManager.markCardAsPlaying(card, reason or "play.lua")
    CardManager.lockRepositioning("carte en cours de jeu: " .. (card.name or ""))
end

function CardManager.onCardPlayComplete(card, reason)
    CardManager.unmarkCardAsPlaying(card, reason or "jeu terminé")
    -- Ne pas déverrouiller automatiquement - laisser le contrôle au système de ciblage
end

function CardManager.onCardMoveToGrave(card, reason)
    CardManager.unmarkCardAsPlaying(card, reason or "envoi au cimetière")
    -- Permettre repositionnement après envoi au cimetière SI pas de ciblage actif
    if not CardManager.isTargetingActive() then
        CardManager.unlockRepositioning("carte au cimetière")
        CardManager.updateHandTargets("moveToGrave", false)
    else
        _logWarn("🎯 Carte au cimetière mais ciblage actif - repositionnement différé")
    end
end

-- === INTERFACE POUR SYSTÈME DE CIBLAGE ===

function CardManager.onTargetingStart(card)
    _logInfo("🎯 CIBLAGE DÉMARRÉ pour: %s", card.name or "carte")
    _state.targeting_active = true
    _state.targeting_start_time = os.time() -- Timestamp début ciblage
    CardManager.saveCardPosition(card, "avant ciblage")
    CardManager.lockRepositioning("ciblage en cours")

    _state.cards_being_targeted[card.name or tostring(card)] = {
        card = card,
        timestamp = os.time()
    }
end

function CardManager.onTargetingEnd(card, success)
    _logInfo("🎯 CIBLAGE TERMINÉ pour: %s (succès: %s)",
        card.name or "carte", tostring(success))

    _state.targeting_active = false
    _state.targeting_start_time = 0 -- Reset timestamp
    _state.cards_being_targeted[card.name or tostring(card)] = nil

    if success then
        -- Ciblage réussi - la carte va être jouée normalement
        CardManager.unlockRepositioning("ciblage réussi")
    else
        -- Ciblage échoué - restaurer position
        CardManager.restoreCardPosition(card, "ciblage échoué")
        CardManager.unlockRepositioning("ciblage échoué")
        CardManager.updateHandTargets("ciblage échoué", false)
    end
end

-- === INTERFACE POUR interaction.lua ===

function CardManager.onResetInteractions(hard, caller)
    _logInfo("🔄 RESET INTERACTIONS demandé par: %s (hard=%s)",
        caller or "inconnu", tostring(hard))

    if CardManager.isTargetingActive() then
        _logWarn("🛡️  RESET INTERACTIONS BLOQUÉ - ciblage en cours")
        return false
    end

    -- Nettoyer l'état
    for card_key, info in pairs(_state.cards_being_played) do
        _logWarn("🧹 Nettoyage carte en jeu: %s", card_key)
        if info.card then
            CardManager.unmarkCardAsPlaying(info.card, "reset interactions")
        end
    end

    CardManager.unlockRepositioning("reset interactions")
    return true
end

-- === DEBUG ET MONITORING ===

function CardManager.getState()
    return {
        repositioning_locked = _state.repositioning_locked,
        targeting_active = CardManager.isTargetingActive(),
        cards_being_played = _state.cards_being_played,
        cards_being_targeted = _state.cards_being_targeted,
        position_history_count = 0
    }
end

function CardManager.dumpState()
    local state = CardManager.getState()

    -- Compter les éléments dans les tables
    local playing_count = 0
    for _ in pairs(_state.cards_being_played) do playing_count = playing_count + 1 end

    local targeted_count = 0
    for _ in pairs(_state.cards_being_targeted) do targeted_count = targeted_count + 1 end

    _logInfo("=== ÉTAT CARD MANAGER ===")
    _logInfo("Repositionnement verrouillé: %s", tostring(state.repositioning_locked))
    _logInfo("Ciblage actif: %s", tostring(state.targeting_active))
    _logInfo("Cartes en jeu: %d", playing_count)
    _logInfo("Cartes ciblées: %d", targeted_count)
    _logInfo("========================")
end

-- === INITIALISATION ===

function CardManager.init()
    _logInfo("🚀 CARD MANAGER INITIALISÉ")

    -- Enregistrer comme global pour accès facile
    rawset(_G, "CardManager", CardManager)

    return CardManager
end

-- Auto-initialisation
CardManager.init()

return CardManager
