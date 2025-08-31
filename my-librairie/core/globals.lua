-- my-librairie/core/globals.lua
-- Centralisation de toutes les variables globales du projet
-- Ce fichier doit être requis depuis main.lua AVANT tout autre module

local globals = {}

--[[ =====================================================================
Configuration et helpers
===================================================================== ]]

-- Helper pour charger de manière sécurisée
local function safeRequireAny(list)
    for _, name in ipairs(list) do
        local ok, mod = pcall(require, name)
        if ok and mod then return mod end
    end
    return nil
end

--[[ =====================================================================
Modules Core - Chargés et exposés globalement
===================================================================== ]]

-- JSON Library
_G.json = require("my-librairie/utils/json")

-- HUD System
_G.hud = require("my-librairie/systems/hud/hud")

-- Card System (API façade principale)
_G.Card = require("my-librairie/systems/card-librairie/card")

-- Card Standby Play System
_G.CardStandbyPlay = require("my-librairie/systems/card-librairie/states/standby")

-- Responsive Screen Manager
_G.screen = require("my-librairie/utils/responsive")

-- Scene Manager
_G.scene = require("my-librairie/core/sceneManager")

-- Effects System
_G.effect = require("ressources/effect")

-- Transition Manager
_G.Transition = require("my-librairie.systems.transitions.transitionManager")
_G.TransitionCombat = require("my-librairie/systems/transitions/templateCombatTransition")

--[[ =====================================================================
Modules Optionnels - Chargés avec fallback
===================================================================== ]]

-- Input Manager (unifie souris/gamepad)
local okInput, inputManager = pcall(require, "my-librairie/managers/inputManager")
_G.inputManager = okInput and inputManager or nil

-- Actor Manager (gestion entités de combat)
local okActor, actorManager = pcall(require, "my-librairie/core/actorManager")
_G.actorManager = okActor and actorManager or nil

-- Card Target Selection (système de ciblage manuel)
-- Force rechargement en vidant le cache
package.loaded["my-librairie/systems/card-librairie/ui/card_target_selection"] = nil
local okCTS, cardTargetSelection = pcall(require, "my-librairie/systems/card-librairie/ui/card_target_selection")
_G.CardTargetSelection = okCTS and cardTargetSelection or nil

-- Global Function / My Function (utilitaires legacy)
_G.globalFunction = safeRequireAny({
    "my-librairie/utils/globalFunction",
    "my-librairie.utils.globalFunction"
}) or {}

_G.myFunction = _G.globalFunction -- Alias pour compatibilité
_G.myFonction = _G.globalFunction -- Alias typo legacy

-- NOTE: globalFunction contient de nombreux utilitaires réutilisables :
-- - Animation: lerp(), clone()
-- - Input: mouse.hover(), mouse.click(), endTurnHotkeys()
-- - Logging: log.info/warn/error(), drawLogs(), log.toggle()
-- - Rendu: drawLifeBarStatus()
-- - Utils: safecall(), tstr()
-- Consultez my-librairie/globalFunction.lua pour la liste complète

--[[ =====================================================================
Actors Scripts - Chargés à la demande
===================================================================== ]]

-- Hero (joueur)
local okHero, Hero = pcall(require, "my-librairie/ActorScripts/player/Hero")
_G.Hero = okHero and Hero or nil

-- Enemies (ennemis)
local okEnemies, Enemies = pcall(require, "my-librairie/ActorScripts/Enemy/Enemies")
_G.Enemies = okEnemies and Enemies or nil

--[[ =====================================================================
Configuration Flags & Constants
===================================================================== ]]

-- Game state flags
_G.GameFlags = _G.GameFlags or {
    first_draft_done = true,
    debug_mode = false,
    hud_debug_energy = false
}

-- Scene Manager
_G.scene = require("my-librairie/sceneManager")

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
local okActor, actorManager = pcall(require, "my-librairie/actorManager")
_G.actorManager = okActor and actorManager or nil

-- Global Function / My Function (utilitaires legacy)
_G.globalFunction = safeRequireAny({
    "my-librairie/globalFunction",
    "my-librairie.globalFunction"
}) or {}

_G.myFunction = _G.globalFunction -- Alias pour compatibilité
_G.myFonction = _G.globalFunction -- Alias typo legacy

--[[ =====================================================================
Actors Scripts - Chargés à la demande
===================================================================== ]]

-- Hero (joueur)
local okHero, Hero = pcall(require, "my-librairie/ActorScripts/player/Hero")
_G.Hero = okHero and Hero or nil

-- Enemies (ennemis)
local okEnemies, Enemies = pcall(require, "my-librairie/ActorScripts/Enemy/Enemies")
_G.Enemies = okEnemies and Enemies or nil

--[[ =====================================================================
Configuration Flags & Constants
===================================================================== ]]

-- Game state flags
_G.GameFlags = _G.GameFlags or {
    first_draft_done = false,
    debug_mode = false,
    hud_debug_energy = false
}

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
        "inputManager", "actorManager", "globalFunction", "myFunction", "myFonction",
        -- Actor scripts
        "Hero", "Enemies",
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
