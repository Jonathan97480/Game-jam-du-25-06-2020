-- =========================================================================
-- SAVE MANAGER - Gestionnaire de Sauvegarde JSON
-- =========================================================================
-- Auteur: GitHub Copilot
-- Date: 3 septembre 2025
-- Description: Système complet de sauvegarde/chargement avec JSON et validation
-- =========================================================================

local saveManager = {}

-- =========================================================================
-- CONFIGURATION
-- =========================================================================

local SAVE_DIRECTORY = "saves/"
local AUTO_SAVE_PREFIX = "autosave_"
local MANUAL_SAVE_PREFIX = "save_"
local SAVE_EXTENSION = ".json"
local MAX_SAVE_SLOTS = 10
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes en secondes

-- Version du format de sauvegarde
local SAVE_FORMAT_VERSION = "1.0"

-- =========================================================================
-- ÉTAT INTERNE
-- =========================================================================

local autoSaveTimer = 0
local isAutoSaveEnabled = true
local lastSaveTime = 0

-- Cache des slots de sauvegarde
local saveSlots = {}
local lastScanTime = 0
local SCAN_CACHE_DURATION = 10 -- Rescan tous les 10 secondes

-- =========================================================================
-- LOGGING
-- =========================================================================

local function log(level, message)
    if _G.globalFunction and _G.globalFunction.log then
        _G.globalFunction.log[level](string.format("[SaveManager] %s", message))
    else
        print(string.format("[%s] SaveManager: %s", level:upper(), message))
    end
end

-- =========================================================================
-- UTILITAIRES SYSTÈME DE FICHIERS
-- =========================================================================

-- Créer le dossier de sauvegarde s'il n'existe pas
local function ensureSaveDirectory()
    local info = love.filesystem.getInfo(SAVE_DIRECTORY)
    if not info then
        local success = love.filesystem.createDirectory(SAVE_DIRECTORY)
        if success then
            log("info", "Dossier de sauvegarde créé: " .. SAVE_DIRECTORY)
        else
            log("error", "Impossible de créer le dossier de sauvegarde")
            return false
        end
    elseif info.type ~= "directory" then
        log("error", "Le chemin de sauvegarde existe mais n'est pas un dossier")
        return false
    end
    return true
end

-- Générer nom de fichier de sauvegarde
local function generateSaveFilename(slotId, isAutoSave)
    local prefix = isAutoSave and AUTO_SAVE_PREFIX or MANUAL_SAVE_PREFIX
    local timestamp = os.date("%Y%m%d_%H%M%S")

    if slotId then
        return string.format("%s%s%02d_%s%s", SAVE_DIRECTORY, prefix, slotId, timestamp, SAVE_EXTENSION)
    else
        return string.format("%s%s%s%s", SAVE_DIRECTORY, prefix, timestamp, SAVE_EXTENSION)
    end
end

-- =========================================================================
-- COLLECTE DE DONNÉES DE JEU
-- =========================================================================

-- Collecter état du joueur
local function collectPlayerData()
    local playerData = {
        level = 1,
        experience = 0,
        health = 100,
        maxHealth = 100,
        energy = 10,
        maxEnergy = 10,
        position = { x = 0, y = 0 },
        stats = {}
    }

    -- Récupérer données depuis Hero si disponible
    if _G.Hero then
        playerData.health = _G.Hero.health or playerData.health
        playerData.maxHealth = _G.Hero.maxHealth or playerData.maxHealth
        playerData.level = _G.Hero.level or playerData.level

        if _G.Hero.position then
            playerData.position = {
                x = _G.Hero.position.x or 0,
                y = _G.Hero.position.y or 0
            }
        end
    end

    return playerData
end

-- Collecter état des cartes
local function collectCardData()
    local cardData = {
        deck = {},
        hand = {},
        graveyard = {},
        collection = {}
    }

    -- Récupérer données depuis Card si disponible
    if _G.Card then
        if _G.Card.deck and _G.Card.deck.cards then
            cardData.deck = _G.Card.deck.cards
        end

        if _G.Card.hand and _G.Card.hand.cards then
            cardData.hand = _G.Card.hand.cards
        end

        if _G.Card.graveyard and _G.Card.graveyard.cards then
            cardData.graveyard = _G.Card.graveyard.cards
        end
    end

    return cardData
end

-- Collecter état du jeu
local function collectGameData()
    local gameData = {
        currentStage = 1,
        currentRoom = 1,
        difficulty = "normal",
        playtime = 0,
        gameMode = "story",
        flags = {},
        achievements = {},
        settings = {}
    }

    -- Récupérer flags de jeu globaux
    if _G.GameFlags then
        gameData.flags = _G.GameFlags
    end

    -- Récupérer paramètres de localisation
    if _G.LocalizationManager then
        gameData.settings.language = _G.LocalizationManager:getCurrentLanguage()
    end

    return gameData
end

-- Collecter l'état complet du jeu pour sauvegarde
local function collectCompleteGameState()
    local gameState = {
        -- Métadonnées de sauvegarde
        meta = {
            version = SAVE_FORMAT_VERSION,
            timestamp = os.time(),
            gameVersion = "1.0", -- Version du jeu
            saveType = "manual", -- sera modifié selon le contexte
            playTime = 0         -- temps de jeu total
        },

        -- Données principales
        player = collectPlayerData(),
        cards = collectCardData(),
        game = collectGameData(),

        -- État des scènes
        scene = {
            current = _G.scene and _G.scene.current and _G.scene.current.name or "menu",
            stack = {},
            data = {}
        },

        -- État des ennemis (si en combat)
        combat = {
            active = false,
            enemies = {},
            turn = 1,
            playerTurn = true
        }
    }

    -- Collecter état de la pile de scènes si disponible
    if _G.scene and _G.scene.stack then
        for _, sceneInfo in ipairs(_G.scene.stack) do
            table.insert(gameState.scene.stack, {
                name = sceneInfo.name or "unknown",
                data = sceneInfo.data or {}
            })
        end
    end

    return gameState
end

-- =========================================================================
-- SAUVEGARDE
-- =========================================================================

-- Sauvegarder l'état du jeu
function saveManager.saveGame(slotId, isAutoSave)
    if not ensureSaveDirectory() then
        return false, "Impossible de créer le dossier de sauvegarde"
    end

    -- Collecter l'état du jeu
    local gameState = collectCompleteGameState()
    gameState.meta.saveType = isAutoSave and "auto" or "manual"

    -- Générer nom de fichier
    local filename = generateSaveFilename(slotId, isAutoSave)

    -- Encoder en JSON
    local json = _G.json or require("my-librairie.tools.json")
    local success, jsonData = pcall(json.encode, gameState)

    if not success then
        log("error", "Erreur encodage JSON: " .. tostring(jsonData))
        return false, "Erreur d'encodage des données"
    end

    -- Écrire le fichier
    local writeSuccess, writeError = love.filesystem.write(filename, jsonData)

    if not writeSuccess then
        log("error", "Erreur écriture fichier: " .. tostring(writeError))
        return false, "Impossible d'écrire le fichier de sauvegarde"
    end

    lastSaveTime = love.timer.getTime()

    log("info", string.format("Sauvegarde réussie: %s (slot %s)", filename, slotId or "auto"))

    -- Nettoyer les anciennes sauvegardes automatiques
    if isAutoSave then
        saveManager.cleanupOldAutoSaves()
    end

    return true, filename
end

-- Sauvegarde manuelle dans un slot spécifique
function saveManager.saveToSlot(slotId)
    if not slotId or slotId < 1 or slotId > MAX_SAVE_SLOTS then
        return false, "Numéro de slot invalide (1-" .. MAX_SAVE_SLOTS .. ")"
    end

    return saveManager.saveGame(slotId, false)
end

-- Sauvegarde automatique
function saveManager.autoSave()
    if not isAutoSaveEnabled then
        return true, "Auto-save désactivé"
    end

    return saveManager.saveGame(nil, true)
end

-- =========================================================================
-- CHARGEMENT
-- =========================================================================

-- Charger une sauvegarde depuis un fichier
function saveManager.loadFromFile(filename)
    if not filename then
        return false, "Nom de fichier requis"
    end

    -- Vérifier que le fichier existe
    local info = love.filesystem.getInfo(filename)
    if not info then
        return false, "Fichier de sauvegarde non trouvé: " .. filename
    end

    -- Lire le contenu du fichier
    local content, readError = love.filesystem.read(filename)
    if not content then
        log("error", "Erreur lecture fichier: " .. tostring(readError))
        return false, "Impossible de lire le fichier"
    end

    -- Décoder le JSON
    local json = _G.json or require("my-librairie.tools.json")
    local success, gameState = pcall(json.decode, content)

    if not success then
        log("error", "Erreur décodage JSON: " .. tostring(gameState))
        return false, "Fichier de sauvegarde corrompu"
    end

    -- Valider la structure
    if not saveManager.validateSaveData(gameState) then
        return false, "Structure de sauvegarde invalide"
    end

    -- Appliquer l'état du jeu
    local applySuccess, applyError = saveManager.applySaveData(gameState)
    if not applySuccess then
        return false, "Erreur application sauvegarde: " .. tostring(applyError)
    end

    log("info", "Sauvegarde chargée avec succès: " .. filename)
    return true, gameState
end

-- Charger depuis un slot spécifique
function saveManager.loadFromSlot(slotId)
    local saves = saveManager.getSaveSlots()

    for _, saveInfo in ipairs(saves) do
        if saveInfo.slot == slotId and not saveInfo.isAutoSave then
            return saveManager.loadFromFile(saveInfo.filename)
        end
    end

    return false, "Aucune sauvegarde trouvée dans le slot " .. slotId
end

-- =========================================================================
-- VALIDATION ET APPLICATION
-- =========================================================================

-- Valider la structure d'une sauvegarde
function saveManager.validateSaveData(gameState)
    if not gameState or type(gameState) ~= "table" then
        return false
    end

    -- Vérifier métadonnées
    if not gameState.meta or not gameState.meta.version then
        log("warn", "Métadonnées de sauvegarde manquantes")
        return false
    end

    -- Vérifier version supportée
    if gameState.meta.version ~= SAVE_FORMAT_VERSION then
        log("warn", string.format("Version de sauvegarde non supportée: %s (attendu: %s)",
            gameState.meta.version, SAVE_FORMAT_VERSION))
        -- Pour l'instant, on accepte quand même, mais on pourrait migrer
    end

    -- Vérifier sections principales
    local requiredSections = { "player", "cards", "game", "scene" }
    for _, section in ipairs(requiredSections) do
        if not gameState[section] then
            log("warn", "Section manquante dans la sauvegarde: " .. section)
            return false
        end
    end

    return true
end

-- Appliquer les données de sauvegarde au jeu
function saveManager.applySaveData(gameState)
    local success, error = pcall(function()
        -- Appliquer données joueur
        if gameState.player and _G.Hero then
            _G.Hero.health = gameState.player.health or _G.Hero.health
            _G.Hero.maxHealth = gameState.player.maxHealth or _G.Hero.maxHealth
            _G.Hero.level = gameState.player.level or _G.Hero.level

            if gameState.player.position then
                _G.Hero.position = gameState.player.position
            end
        end

        -- Appliquer données cartes
        if gameState.cards and _G.Card then
            if gameState.cards.deck and _G.Card.deck then
                _G.Card.deck.cards = gameState.cards.deck
            end

            if gameState.cards.hand and _G.Card.hand then
                _G.Card.hand.cards = gameState.cards.hand
            end

            if gameState.cards.graveyard and _G.Card.graveyard then
                _G.Card.graveyard.cards = gameState.cards.graveyard
            end
        end

        -- Appliquer flags de jeu
        if gameState.game and gameState.game.flags then
            if _G.GameFlags then
                for key, value in pairs(gameState.game.flags) do
                    _G.GameFlags[key] = value
                end
            end
        end

        -- Appliquer paramètres de langue
        if gameState.game and gameState.game.settings and gameState.game.settings.language then
            if _G.LocalizationManager then
                _G.LocalizationManager:setLanguage(gameState.game.settings.language)
            end
        end

        -- Charger la scène appropriée
        if gameState.scene and gameState.scene.current and _G.scene then
            -- Note: Ici on pourrait implémenter une logique plus sophistiquée
            -- pour restaurer l'état exact des scènes
            log("info", "Restauration scène: " .. gameState.scene.current)
        end
    end)

    return success, error
end

-- =========================================================================
-- GESTION DES SLOTS ET LISTE
-- =========================================================================

-- Scanner et mettre à jour la liste des sauvegardes
local function scanSaveFiles()
    local currentTime = love.timer.getTime()

    -- Utiliser cache si récent
    if lastScanTime > 0 and (currentTime - lastScanTime) < SCAN_CACHE_DURATION then
        return saveSlots
    end

    saveSlots = {}

    if not love.filesystem.getInfo(SAVE_DIRECTORY) then
        return saveSlots
    end

    local files = love.filesystem.getDirectoryItems(SAVE_DIRECTORY)

    for _, filename in ipairs(files) do
        if filename:match(SAVE_EXTENSION .. "$") then
            local fullPath = SAVE_DIRECTORY .. filename
            local info = love.filesystem.getInfo(fullPath)

            if info and info.type == "file" then
                -- Analyser le nom du fichier
                local isAutoSave = filename:match("^" .. AUTO_SAVE_PREFIX)
                local slotMatch = filename:match("(%d+)_")

                local saveInfo = {
                    filename = fullPath,
                    displayName = filename:gsub(SAVE_EXTENSION .. "$", ""),
                    timestamp = info.modtime,
                    size = info.size,
                    isAutoSave = isAutoSave ~= nil,
                    slot = slotMatch and tonumber(slotMatch) or nil
                }

                -- Essayer de lire les métadonnées
                local metaSuccess, meta = pcall(function()
                    local content = love.filesystem.read(fullPath)
                    local json = _G.json or require("my-librairie.tools.json")
                    local data = json.decode(content)
                    return data.meta
                end)

                if metaSuccess and meta then
                    saveInfo.gameVersion = meta.gameVersion
                    saveInfo.saveVersion = meta.version
                    saveInfo.playTime = meta.playTime
                    saveInfo.saveType = meta.saveType
                end

                table.insert(saveSlots, saveInfo)
            end
        end
    end

    -- Trier par timestamp (plus récent en premier)
    table.sort(saveSlots, function(a, b)
        return a.timestamp > b.timestamp
    end)

    lastScanTime = currentTime
    return saveSlots
end

-- Obtenir la liste des sauvegardes disponibles
function saveManager.getSaveSlots()
    return scanSaveFiles()
end

-- Obtenir la sauvegarde la plus récente
function saveManager.getLatestSave()
    local saves = saveManager.getSaveSlots()
    return saves[1] -- Premier élément = plus récent
end

-- =========================================================================
-- NETTOYAGE ET MAINTENANCE
-- =========================================================================

-- Nettoyer les anciennes sauvegardes automatiques
function saveManager.cleanupOldAutoSaves()
    local saves = saveManager.getSaveSlots()
    local autoSaves = {}

    -- Filtrer les sauvegardes automatiques
    for _, save in ipairs(saves) do
        if save.isAutoSave then
            table.insert(autoSaves, save)
        end
    end

    -- Garder seulement les 5 plus récentes
    local MAX_AUTO_SAVES = 5
    if #autoSaves > MAX_AUTO_SAVES then
        for i = MAX_AUTO_SAVES + 1, #autoSaves do
            local success = love.filesystem.remove(autoSaves[i].filename)
            if success then
                log("info", "Ancienne sauvegarde automatique supprimée: " .. autoSaves[i].filename)
            end
        end
    end
end

-- Supprimer une sauvegarde
function saveManager.deleteSave(filename)
    if not filename then
        return false, "Nom de fichier requis"
    end

    local success = love.filesystem.remove(filename)
    if success then
        log("info", "Sauvegarde supprimée: " .. filename)
        -- Invalider le cache
        lastScanTime = 0
        return true
    else
        log("error", "Impossible de supprimer: " .. filename)
        return false, "Échec de suppression"
    end
end

-- =========================================================================
-- AUTO-SAVE ET TIMER
-- =========================================================================

-- Mettre à jour le timer d'auto-save
function saveManager.update(dt)
    if not isAutoSaveEnabled then
        return
    end

    autoSaveTimer = autoSaveTimer + dt

    if autoSaveTimer >= AUTO_SAVE_INTERVAL then
        local success, error = saveManager.autoSave()
        if success then
            log("info", "Auto-save effectué")
        else
            log("warn", "Échec auto-save: " .. tostring(error))
        end

        autoSaveTimer = 0
    end
end

-- Activer/désactiver l'auto-save
function saveManager.setAutoSaveEnabled(enabled)
    isAutoSaveEnabled = enabled
    log("info", "Auto-save " .. (enabled and "activé" or "désactivé"))
end

-- =========================================================================
-- API PUBLIQUE
-- =========================================================================

-- Initialiser le système de sauvegarde
function saveManager.initialize()
    if not ensureSaveDirectory() then
        return false
    end

    -- Scanner les sauvegardes existantes
    scanSaveFiles()

    log("info", "Save Manager initialisé avec " .. #saveSlots .. " sauvegardes trouvées")
    return true
end

-- Obtenir des statistiques sur le système de sauvegarde
function saveManager.getStats()
    local saves = saveManager.getSaveSlots()
    local autoSaveCount = 0
    local manualSaveCount = 0

    for _, save in ipairs(saves) do
        if save.isAutoSave then
            autoSaveCount = autoSaveCount + 1
        else
            manualSaveCount = manualSaveCount + 1
        end
    end

    return {
        totalSaves = #saves,
        autoSaves = autoSaveCount,
        manualSaves = manualSaveCount,
        autoSaveEnabled = isAutoSaveEnabled,
        lastSaveTime = lastSaveTime,
        nextAutoSave = isAutoSaveEnabled and (AUTO_SAVE_INTERVAL - autoSaveTimer) or nil
    }
end

-- =========================================================================
-- EXPORT DU MODULE
-- =========================================================================

return saveManager
