-- =========================================================================
-- PHASE 3.1 : Système de raccourcis clavier avancés
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 2 septembre 2025
-- Description: Améliore l'expérience utilisateur avec des raccourcis intuitifs
-- Dépendances: InputManager, SceneManager
-- =========================================================================

local keyboardShortcuts = {}

-- Dépendances
local globalFunction = _G.globalFunction
local scene = _G.scene
local visualFeedback = _G.visualFeedback

-- Configuration des raccourcis
local SHORTCUTS = {
    -- Raccourcis de base
    END_TURN = { "e", "return", "space" },
    CANCEL_ACTION = { "escape", "backspace" },
    CONFIRM_ACTION = { "space", "return" },

    -- Raccourcis cartes
    PLAY_FIRST_CARD = { "1" },
    PLAY_SECOND_CARD = { "2" },
    PLAY_THIRD_CARD = { "3" },
    PLAY_FOURTH_CARD = { "4" },
    PLAY_FIFTH_CARD = { "5" },

    -- Raccourcis avancés
    SHOW_ALL_CARDS = { "tab" },
    SHOW_GRAVEYARD = { "g" },
    SHOW_DECK_COUNT = { "d" },
    TOGGLE_HELP = { "h", "f1" },

    -- Raccourcis debug (en mode développement)
    DEBUG_ADD_ENERGY = { "f2" },
    DEBUG_DRAW_CARD = { "f3" },
    DEBUG_TOGGLE_INFO = { "f12" }
}

-- État des raccourcis
local shortcutState = {
    enabled = true,
    helpVisible = false,
    lastKeyTime = {},
    comboPressTime = 0.3, -- Temps maximum pour combo de touches
    debugMode = false
}

-- Messages d'aide
local HELP_MESSAGES = {
    basic = {
        "🎮 RACCOURCIS CLAVIER",
        "",
        "⚡ Actions principales:",
        "  E / Entrée / Espace : Fin de tour",
        "  Échap : Annuler action",
        "  Espace : Confirmer",
        "",
        "🃏 Cartes:",
        "  1-5 : Jouer carte de la main",
        "  Tab : Voir toutes les cartes",
        "  G : Voir cimetière",
        "  D : Compter cartes deck",
        "",
        "❓ H / F1 : Afficher/masquer cette aide"
    },
    advanced = {
        "🔧 RACCOURCIS AVANCÉS",
        "",
        "🎯 Ciblage:",
        "  Clic : Sélectionner cible",
        "  Espace : Confirmer ciblage",
        "  Échap : Annuler ciblage",
        "",
        "⚡ Énergie:",
        "  Couleur verte : Énergie suffisante",
        "  Couleur orange : Énergie faible",
        "  Couleur rouge : Énergie insuffisante",
        "",
        "🎲 Debug (F12 pour activer):",
        "  F2 : +1 énergie",
        "  F3 : Tirer une carte"
    }
}

-- =========================================================================
-- GESTION DES RACCOURCIS DE BASE
-- =========================================================================

---Vérifier si une touche fait partie d'un raccourci
---@param key string Touche pressée
---@param shortcutKeys table Liste des touches du raccourci
---@return boolean isShortcut Si la touche correspond au raccourci
function keyboardShortcuts.isShortcutKey(key, shortcutKeys)
    for _, shortcutKey in ipairs(shortcutKeys) do
        if key == shortcutKey then
            return true
        end
    end
    return false
end

---Gérer fin de tour via raccourcis
function keyboardShortcuts.handleEndTurn()
    -- Vérifier qu'on est en gameplay
    if not scene or not scene.getCurrentScene then
        return false
    end

    local currentScene = scene.getCurrentScene()
    if not currentScene or currentScene.name ~= "gameplay" then
        return false
    end

    -- Vérifier qu'aucune action n'est en cours
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby() then
        -- Annuler action en standby d'abord
        keyboardShortcuts.handleCancelAction()
        return true
    end

    -- Déclencher fin de tour
    if globalFunction and globalFunction.endTurnHotkeys then
        globalFunction.endTurnHotkeys()
        if visualFeedback then
            visualFeedback.showMessage("🔄 Fin de tour", 1.5)
        end
        return true
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("End turn shortcut triggered")
    end

    return false
end

---Gérer annulation d'action
function keyboardShortcuts.handleCancelAction()
    local CardStandbyPlay = _G.CardStandbyPlay
    local CardTargetSelection = _G.CardTargetSelection

    -- Annuler ciblage en cours
    if CardTargetSelection and CardTargetSelection.clearSelection then
        CardTargetSelection.clearSelection()
        if visualFeedback then
            visualFeedback.showMessage("❌ Ciblage annulé", 1.0)
        end
        return true
    end

    -- Annuler carte en standby
    if CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby() then
        if CardStandbyPlay.returnCardToHand then
            CardStandbyPlay.returnCardToHand()
            if visualFeedback then
                visualFeedback.showMessage("🔙 Carte retournée en main", 1.0)
            end
            return true
        end
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Cancel action shortcut triggered")
    end

    return false
end

---Gérer confirmation d'action
function keyboardShortcuts.handleConfirmAction()
    local CardStandbyPlay = _G.CardStandbyPlay
    local CardTargetSelection = _G.CardTargetSelection

    -- Confirmer ciblage et jouer carte
    if CardStandbyPlay and CardStandbyPlay.hasCardInStandby and CardStandbyPlay.hasCardInStandby() then
        if CardTargetSelection and CardTargetSelection.selectedTarget then
            if CardStandbyPlay.confirmCardPlay then
                CardStandbyPlay.confirmCardPlay()
                if visualFeedback then
                    visualFeedback.showMessage("✅ Carte jouée !", 1.5)
                end
                return true
            end
        else
            if visualFeedback then
                visualFeedback.showMessage("🎯 Sélectionnez une cible d'abord", 2.0)
            end
            return true
        end
    end

    return false
end

-- =========================================================================
-- RACCOURCIS CARTES
-- =========================================================================

---Jouer une carte par son index dans la main
---@param cardIndex number Index de la carte (1-5)
function keyboardShortcuts.playCardByIndex(cardIndex)
    local Card = _G.Card
    if not Card or not Card.hand then
        return false
    end

    -- Vérifier que la carte existe
    if cardIndex < 1 or cardIndex > #Card.hand then
        if visualFeedback then
            visualFeedback.showMessage(string.format("❌ Pas de carte en position %d", cardIndex), 1.5)
        end
        return false
    end

    local card = Card.hand[cardIndex]
    if not card then
        return false
    end

    -- Vérifier l'énergie
    local Hero = _G.Hero
    if Hero and Hero.actor and Hero.actor.state then
        local currentEnergy = Hero.actor.state.power or 0
        local cardCost = card.PowerBlow or card.cost or card.power or 0

        if currentEnergy < cardCost then
            if visualFeedback then
                visualFeedback.showInsufficientEnergyError(cardCost, currentEnergy)
            end
            return false
        end
    end

    -- Mettre la carte en standby
    local CardStandbyPlay = _G.CardStandbyPlay
    if CardStandbyPlay and CardStandbyPlay.putCardInStandby then
        CardStandbyPlay.putCardInStandby(card, cardIndex)
        if visualFeedback then
            visualFeedback.showMessage(string.format("🎯 %s en attente de cible", card.name or "Carte"), 2.0)
        end
        return true
    end

    return false
end

---Afficher informations sur toutes les cartes en main
function keyboardShortcuts.showAllCards()
    local Card = _G.Card
    if not Card or not Card.hand then
        return false
    end

    if #Card.hand == 0 then
        if visualFeedback then
            visualFeedback.showMessage("🃏 Aucune carte en main", 1.5)
        end
        return true
    end

    -- Construire message avec info cartes
    local cardInfo = {}
    for i, card in ipairs(Card.hand) do
        local cost = card.PowerBlow or card.cost or card.power or 0
        local info = string.format("%d. %s (%d⚡)", i, card.name or "???", cost)
        table.insert(cardInfo, info)
    end

    local message = "🃏 Cartes en main:\n" .. table.concat(cardInfo, "\n")
    if visualFeedback then
        visualFeedback.showMessage(message, 4.0)
    end

    return true
end

---Afficher informations cimetière
function keyboardShortcuts.showGraveyard()
    local Card = _G.Card
    if not Card or not Card.graveyard then
        return false
    end

    local graveyardCount = #Card.graveyard
    local message = string.format("⚱️ Cimetière: %d carte(s)", graveyardCount)

    if graveyardCount > 0 and graveyardCount <= 3 then
        -- Afficher noms des dernières cartes
        local recentCards = {}
        for i = math.max(1, graveyardCount - 2), graveyardCount do
            table.insert(recentCards, Card.graveyard[i].name or "???")
        end
        message = message .. "\n" .. table.concat(recentCards, ", ")
    end

    if visualFeedback then
        visualFeedback.showMessage(message, 3.0)
    end

    return true
end

---Afficher compte des cartes restantes dans le deck
function keyboardShortcuts.showDeckCount()
    local Card = _G.Card
    if not Card or not Card.deck then
        return false
    end

    local deckCount = #Card.deck
    local message = string.format("📚 Deck: %d carte(s) restante(s)", deckCount)

    if visualFeedback then
        visualFeedback.showMessage(message, 2.0)
    end

    return true
end

-- =========================================================================
-- SYSTÈME D'AIDE
-- =========================================================================

---Basculer l'affichage de l'aide
function keyboardShortcuts.toggleHelp()
    shortcutState.helpVisible = not shortcutState.helpVisible

    if shortcutState.helpVisible then
        keyboardShortcuts.showHelp()
    else
        keyboardShortcuts.hideHelp()
    end
end

---Afficher l'aide à l'écran
function keyboardShortcuts.showHelp()
    if not visualFeedback then return end

    local helpText = table.concat(HELP_MESSAGES.basic, "\n")
    visualFeedback.showMessage(helpText, 10.0) -- Aide visible longtemps

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Keyboard shortcuts help displayed")
    end
end

---Masquer l'aide
function keyboardShortcuts.hideHelp()
    -- L'aide disparaîtra automatiquement via le système de messages
    if globalFunction and globalFunction.log then
        globalFunction.log.info("Keyboard shortcuts help hidden")
    end
end

-- =========================================================================
-- RACCOURCIS DEBUG
-- =========================================================================

---Activer/désactiver mode debug
function keyboardShortcuts.toggleDebugMode()
    shortcutState.debugMode = not shortcutState.debugMode

    local message = shortcutState.debugMode and "🔧 Mode debug activé" or "🔧 Mode debug désactivé"
    if visualFeedback then
        visualFeedback.showMessage(message, 2.0)
    end

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Debug mode: " .. tostring(shortcutState.debugMode))
    end
end

---Ajouter de l'énergie (debug uniquement)
function keyboardShortcuts.debugAddEnergy()
    if not shortcutState.debugMode then return false end

    local Hero = _G.Hero
    if Hero and Hero.actor and Hero.actor.state then
        Hero.actor.state.power = (Hero.actor.state.power or 0) + 1

        if visualFeedback then
            visualFeedback.showMessage(string.format("🔧 Énergie: %d", Hero.actor.state.power), 1.0)
        end
        return true
    end

    return false
end

---Tirer une carte (debug uniquement)
function keyboardShortcuts.debugDrawCard()
    if not shortcutState.debugMode then return false end

    local Card = _G.Card
    if Card and Card.tirage then
        Card.tirage(1)

        if visualFeedback then
            visualFeedback.showMessage("🔧 Carte tirée", 1.0)
        end
        return true
    end

    return false
end

-- =========================================================================
-- GESTIONNAIRE PRINCIPAL
-- =========================================================================

---Traiter une pression de touche
---@param key string Touche pressée
---@return boolean handled Si la touche a été traitée
function keyboardShortcuts.handleKeyPress(key)
    if not shortcutState.enabled then
        return false
    end

    local handled = false

    -- Raccourcis de base
    if keyboardShortcuts.isShortcutKey(key, SHORTCUTS.END_TURN) then
        handled = keyboardShortcuts.handleEndTurn()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.CANCEL_ACTION) then
        handled = keyboardShortcuts.handleCancelAction()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.CONFIRM_ACTION) then
        handled = keyboardShortcuts.handleConfirmAction()

        -- Raccourcis cartes
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.PLAY_FIRST_CARD) then
        handled = keyboardShortcuts.playCardByIndex(1)
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.PLAY_SECOND_CARD) then
        handled = keyboardShortcuts.playCardByIndex(2)
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.PLAY_THIRD_CARD) then
        handled = keyboardShortcuts.playCardByIndex(3)
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.PLAY_FOURTH_CARD) then
        handled = keyboardShortcuts.playCardByIndex(4)
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.PLAY_FIFTH_CARD) then
        handled = keyboardShortcuts.playCardByIndex(5)

        -- Raccourcis informatifs
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.SHOW_ALL_CARDS) then
        handled = keyboardShortcuts.showAllCards()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.SHOW_GRAVEYARD) then
        handled = keyboardShortcuts.showGraveyard()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.SHOW_DECK_COUNT) then
        handled = keyboardShortcuts.showDeckCount()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.TOGGLE_HELP) then
        keyboardShortcuts.toggleHelp()
        handled = true

        -- Raccourcis debug
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.DEBUG_TOGGLE_INFO) then
        keyboardShortcuts.toggleDebugMode()
        handled = true
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.DEBUG_ADD_ENERGY) then
        handled = keyboardShortcuts.debugAddEnergy()
    elseif keyboardShortcuts.isShortcutKey(key, SHORTCUTS.DEBUG_DRAW_CARD) then
        handled = keyboardShortcuts.debugDrawCard()
    end

    if handled and globalFunction and globalFunction.log then
        globalFunction.log.info("Keyboard shortcut handled: " .. key)
    end

    return handled
end

-- =========================================================================
-- INTÉGRATION AVEC LE SYSTÈME
-- =========================================================================

---Activer/désactiver les raccourcis
---@param enabled boolean État des raccourcis
function keyboardShortcuts.setEnabled(enabled)
    shortcutState.enabled = enabled

    if globalFunction and globalFunction.log then
        globalFunction.log.info("Keyboard shortcuts: " .. (enabled and "enabled" or "disabled"))
    end
end

---Obtenir l'état actuel des raccourcis
---@return boolean enabled Si les raccourcis sont activés
function keyboardShortcuts.isEnabled()
    return shortcutState.enabled
end

-- =========================================================================
-- INITIALISATION ET EXPORT
-- =========================================================================

-- Exposer globalement
_G.keyboardShortcuts = keyboardShortcuts

-- Hook dans le système d'input existant si disponible
local inputManager = _G.inputManager
if inputManager and inputManager.addKeyHandler then
    inputManager.addKeyHandler("shortcuts", keyboardShortcuts.handleKeyPress)
end

if globalFunction and globalFunction.log then
    globalFunction.log.info("Keyboard shortcuts system initialized")
end

return keyboardShortcuts
