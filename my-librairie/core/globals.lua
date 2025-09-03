-- my-librairie/globals.lua
-- Centralisation de toutes les variables globales du projet
-- Ce fichier doit être requis depuis main.lua AVANT tout autre module

local globals = {}


--[[ =====================================================================
Modules Core - Chargés et exposés globalement
===================================================================== ]]

-- GlobalFunction (fonctions utilitaires et logging) - DOIT ÊTRE EN PREMIER
_G.globalFunction = require("my-librairie/utils/globalFunction")

-- Fonction _safeRequire centralisée (exposition globale immédiate)
if _G.globalFunction and _G.globalFunction._safeRequire then
    _G._safeRequire = _G.globalFunction._safeRequire
else
    -- Fallback si globalFunction n'est pas encore chargé
    _G._safeRequire = function(name)
        local ok, mod = pcall(require, name)
        if ok then return mod else return nil end
    end
end

-- JSON Library
_G.json = require("my-librairie.utils.json")

-- HUD System
_G.hud = require("my-librairie/hud/hud")

-- Card System (API façade principale)
_G.Card = require("my-librairie/card-librairie/card")

-- Card Effects System (nouveau système centralisé)
_G.card_effects = require("my-librairie/card-librairie/core/card_effects")

-- Card Actions System (utilitaires pour fonctions action)
_G.card_actions = require("my-librairie/card-librairie/core/card_actions")

-- Card Standby Play System
_G.CardStandbyPlay = require("my-librairie/card-librairie/cardStandbyPlay")

-- Responsive Screen Manager
_G.screen = require("my-librairie.utils.responsive")

-- Scene Manager
_G.scene = require("my-librairie/core/sceneManager")

-- Effects System
_G.effect = require("ressources/effect")

-- Transition Manager
_G.Transition = require("my-librairie.transitions.transitionManager")
_G.TransitionCombat = require("my-librairie/transitions/templateCombatTransition")

-- Le module `core/cursor` a été supprimé : utiliser `inputInterface` comme source unique d'input
local okInputIface, inputInterface = pcall(require, "my-librairie/inputInterface")
_G.cursor = okInputIface and inputInterface or nil
print("[globals] _G.cursor set to inputInterface?", okInputIface)


--[[ =====================================================================
Modules Optionnels - Chargés avec fallback
===================================================================== ]]

-- Input Manager (unifie souris/gamepad)
local okInput, inputManager = pcall(require, "my-librairie/inputManager")
_G.inputManager = okInput and inputManager or nil

-- Actor Manager (gestion entités de combat)
local okActor, actorManager = pcall(require, "my-librairie/managers/actorManager")
_G.actorManager = okActor and actorManager or nil

-- Card Target Selection (système de ciblage manuel)
-- Force rechargement en vidant le cache
package.loaded["my-librairie/card-librairie/ui/card_target_selection"] = nil
local okCTS, cardTargetSelection = pcall(require, "my-librairie/card-librairie/ui/card_target_selection")
_G.CardTargetSelection = okCTS and cardTargetSelection or nil

--[[ =====================================================================
Système de Localisation Multi-Langue
===================================================================== ]]

-- LocalizationManager (système principal)
local okLoc, localizationManager = pcall(require, "my-librairie/localization-system/localizationManager")
_G.localizationManager = okLoc and localizationManager or nil

-- TextFormatter (formatage avec variables)
local okFormatter, textFormatter = pcall(require, "my-librairie/localization-system/textFormatter")
_G.textFormatter = okFormatter and textFormatter or nil

-- TextLoader (chargement JSON)
local okLoader, textLoader = pcall(require, "my-librairie/localization-system/textLoader")
_G.textLoader = okLoader and textLoader or nil

-- Initialiser le système de localisation
local translateFunction
if _G.localizationManager then
    local initSuccess = _G.localizationManager.initialize()
    if initSuccess then
        print("[globals] ✅ LocalizationManager initialisé avec succès")

        -- Définir fonction de traduction avec LocalizationManager
        translateFunction = function(key, variables)
            return _G.localizationManager.t(key, variables)
        end
    else
        print("[globals] ❌ Échec initialisation LocalizationManager")
        -- Fallback si initialisation échoue
        translateFunction = function(key, variables)
            return "[LOCALIZATION_INIT_FAILED:" .. (key or "nil") .. "]"
        end
    end
else
    print("[globals] ⚠️ LocalizationManager non disponible")

    -- Fallback si système de localisation non disponible
    translateFunction = function(key, variables)
        return "[LOCALIZATION_UNAVAILABLE:" .. (key or "nil") .. "]"
    end
end

-- Assigner la fonction globale t()
_G.t = translateFunction

-- Créer l'alias _G.localization pour compatibilité avec les menus
if _G.localizationManager then
    _G.localization = {
        get = function(key, variables)
            return _G.localizationManager.t(key, variables)
        end,
        setLanguage = function(language)
            return _G.localizationManager.setLanguage(language)
        end,
        getCurrentLanguage = function()
            return _G.localizationManager.getCurrentLanguage()
        end,
        getAvailableLanguages = function()
            return _G.localizationManager.getAvailableLanguages()
        end
    }
else
    _G.localization = {
        get = function(key, variables)
            return "[LOCALIZATION_UNAVAILABLE:" .. (key or "nil") .. "]"
        end,
        setLanguage = function(language)
            return false
        end,
        getCurrentLanguage = function()
            return "unknown"
        end,
        getAvailableLanguages = function()
            return {}
        end
    }
end


--[[ =====================================================================
Système de Sauvegarde (NOUVEAU - 3 sept 2025)
===================================================================== ]]

-- SaveManager (gestion sauvegarde/chargement)
local okSave, saveManager = pcall(require, "my-librairie/save-system/saveManager")
_G.saveManager = okSave and saveManager or nil

-- SaveUI (interface utilisateur pour sauvegardes)
local okSaveUI, saveUI = pcall(require, "my-librairie/save-system/saveUI")
_G.saveUI = okSaveUI and saveUI or nil

-- Initialiser le système de sauvegarde
if _G.saveManager then
    local saveInitSuccess = _G.saveManager.initialize()
    if saveInitSuccess then
        print("[globals] ✅ SaveManager initialisé avec succès")

        -- Démarrer auto-save si disponible
        if _G.saveManager.startAutoSave then
            _G.saveManager.startAutoSave()
            print("[globals] 🔄 Auto-save démarré")
        end
    else
        print("[globals] ❌ Échec initialisation SaveManager")
    end
else
    print("[globals] ⚠️ SaveManager non disponible")
end

if _G.saveUI then
    print("[globals] ✅ SaveUI chargé avec succès")
else
    print("[globals] ⚠️ SaveUI non disponible")
end

--[[ =====================================================================
Phase 3 : Fonctionnalités avancées et UX (NOUVEAU - 2 sept 2025)
===================================================================== ]]

-- Phase 3 Integration Module (charge et coordonne tous les modules Phase 3)
local okPhase3, phase3Integration = pcall(require, "my-librairie/phase3/phase3_integration")
if okPhase3 and phase3Integration then
    _G.phase3Integration = phase3Integration
    if _G.globalFunction and _G.globalFunction.log then
        _G.globalFunction.log.info("🚀 Phase 3 modules loaded and integrated successfully")
    end
else
    if _G.globalFunction and _G.globalFunction.log then
        _G.globalFunction.log.warn("⚠️ Phase 3 modules not available - continuing with base system")
    end
end

--[[ =====================================================================
Actors Scripts - Chargés à la demande
===================================================================== ]]

-- Hero (joueur)
_G.Hero = require("my-librairie.entities.player.hero")

-- Enemies (ennemis)
_G.Enemies = require("my-librairie.entities.Enemy.Enemies")

--[[ =====================================================================
Configuration Flags & Constants
===================================================================== ]]

-- Game state flags - Migration vers système debug centralisé
if not _G.GameFlags then
    _G.GameFlags = {}
end

-- S'assurer que tous les flags ont des valeurs par défaut (legacy)
_G.GameFlags.initial_draft_completed = _G.GameFlags.initial_draft_completed or false
_G.GameFlags.debug_mode = _G.GameFlags.debug_mode or false
_G.GameFlags.hud_debug_energy = _G.GameFlags.hud_debug_energy or false

-- 🔧 NOUVEAU: Système debug centralisé (Problème #13)
local debugConfig = require("my-librairie/core/debugConfig")
debugConfig.init() -- Initialise et migre les anciens flags

-- Scene Manager
_G.scene = require("my-librairie/core/sceneManager")

-- Effects System
_G.effect = require("ressources/effect")

--[[ -- Transition Manager
_G.Transition = require("my-librairie.transitionManager") ]]

--[[ =====================================================================
Modules Optionnels - Chargés avec fallback
===================================================================== ]]

-- Input Manager (unifie souris/gamepad)
local okInput, inputManager = pcall(require, "my-librairie/inputManager")
_G.inputManager = okInput and inputManager or nil

-- Actor Manager (gestion entités de combat)
local okActor, actorManager = pcall(require, "my-librairie/managers/actorManager")
_G.actorManager = okActor and actorManager or nil

--systeme de chache pour les fonts les images et e le sond
_G.cache = require("my-librairie.managers.resource_cache")

-- HUD Configuration
_G.HUD_BOTTOM_BG_PATH = 'img/hud/footer-bare.jpg'

--[[ =====================================================================
API d'accès sécurisé pour les modules
===================================================================== ]]

-- Fonction helper pour récupérer une globale de manière sécurisée
-- Usage : local Card = globals.get("Card") or require("fallback")
function globals.get(name)
    return rawget(_G, name)
end

-- Fonction utilitaire pour migration - simplifier les patterns courants
function globals.safe(name, fallback)
    return rawget(_G, name) or fallback
end

-- Fonction pour lister toutes les globales définies par ce module
function globals.list()
    return {
        -- Core modules
        "json", "hud", "Card", "screen", "scene", "effect", "Transition",
        -- Optional modules
        "inputManager", "actorManager", "globalFunction",
        -- Actor scripts
        "Hero", "Enemies",
        -- Localization system
        "localizationManager", "textFormatter", "textLoader", "t",
        -- Configuration
        "GameFlags", "HUD_BOTTOM_BG_PATH"
    }
end

-- Fonction de diagnostic pour vérifier l'état des globales
function globals.status()
    local status = {}
    for _, name in ipairs(globals.list()) do
        local val = rawget(_G, name)
        status[name] = {
            exists = val ~= nil,
            type = type(val),
            loaded = val ~= nil and (type(val) ~= "table" or next(val) ~= nil)
        }
    end
    return status
end

return globals
