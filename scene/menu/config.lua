-- scene/menu/config.lua (refactored)

local function safeRequire(name)
    if type(_G.globalFunction) == "table" and type(_G.globalFunction.safeRequire) == "function" then
        return _G.globalFunction.safeRequire(name)
    end
    local ok, mod = pcall(require, name)
    return ok and mod or nil
end

local screen = _G.screen
    or safeRequire("my-librairie.utils.responsive")
    or {}

local json = _G.json or safeRequire("my-librairie.utils.json")

local _configJson = {}


local gameReso = (screen and screen.gameReso) or { width = 1920, height = 1080 }

local Config = {
    ZONE_TEXT_MAIN_MENU = { x = 0, y = 0 },

    ZONE_BUTTON_PLAY = { x = 60, y = gameReso.height / 2 + (1 * 80) },
    ZONE_BUTTON_CREDIT = { x = 60, y = gameReso.height / 2 + (2 * 80) },
    ZONE_BUTTON_MULTILINGUAL = { x = 60, y = gameReso.height / 2 + (3 * 80) },
    ZONE_BUTTON_SAVE_DEMO = { x = 60, y = gameReso.height / 2 + (4 * 80) },

    -- Configuration des positions pour le panneau Menu Principal
    MAIN_MENU = {
        title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
        -- Panel conteneur pour tous les boutons
        buttonPanel = {
            x = 60,
            y = gameReso.height / 2 - 50,
            width = 300,
            height = 500,
            spacing = 70 -- Espacement entre les boutons
        },
        buttons = {
            play = { x = 0, y = 0, width = 250, height = 60 },
            continue = { x = 0, y = 70, width = 250, height = 60 },
            loadSave = { x = 0, y = 140, width = 250, height = 60 },
            options = { x = 0, y = 210, width = 250, height = 60 },
            languages = { x = 0, y = 280, width = 250, height = 60 },
            credits = { x = 0, y = 350, width = 250, height = 60 },
            quit = { x = 0, y = 420, width = 250, height = 60 }
        }
    },

    -- Configuration des positions pour le panneau MultiLangue
    MULTILANGUE = {
        title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
        buttons = {
            francais = {
                clickZone = { x = 60, y = gameReso.height / 2 + (1 * 120), width = 300, height = 80 },
                text = { x = 60, y = gameReso.height / 2 + (1 * 120) + 10 },
                flag = { x = 60, y = gameReso.height / 2 + (1 * 120) + 40, scaleX = 0.2, scaleY = 0.15 }
            },
            english = {
                clickZone = { x = 60, y = gameReso.height / 2 + (2 * 120) + 20, width = 300, height = 80 },
                text = { x = 60, y = gameReso.height / 2 + (2 * 120) + 30 },
                flag = { x = 60, y = gameReso.height / 2 + (2 * 120) + 60, scaleX = 0.2, scaleY = 0.15 }
            },
            retour = {
                clickZone = { x = 60, y = gameReso.height / 2 + (4 * 100), width = 180, height = 60 },
                text = { x = 60, y = gameReso.height / 2 + (4 * 100) }
            }
        }
    },

    -- Configuration des positions pour le panneau Options
    OPTIONS = {
        title = { x = 60, y = gameReso.height / 2 - 150, fontSize = 80 },
        labels = {
            volume = { x = 60, y = gameReso.height / 2 - 50 },
            fullscreen = { x = 60, y = gameReso.height / 2 + 20 },
            debug = { x = 60, y = gameReso.height / 2 + 90 }
        },
        buttons = {
            volumeMinus = { x = 200, y = gameReso.height / 2 - 60, width = 50, height = 40 },
            volumePlus = { x = 300, y = gameReso.height / 2 - 60, width = 50, height = 40 },
            fullscreenToggle = { x = 200, y = gameReso.height / 2 + 10, width = 100, height = 40 },
            debugToggle = { x = 200, y = gameReso.height / 2 + 80, width = 100, height = 40 },
            retour = { x = 60, y = gameReso.height / 2 + 160, width = 180, height = 60 }
        },
        values = {
            volume = { x = 260, y = gameReso.height / 2 - 50 },
            fullscreen = { x = 310, y = gameReso.height / 2 + 20 },
            debug = { x = 310, y = gameReso.height / 2 + 90 }
        }
    },

    -- Configuration des positions pour le panneau Load Save
    LOAD_SAVE = {
        title = { x = 60, y = gameReso.height / 2 - 300, fontSize = 60 },
        slotContainer = { x = 60, y = gameReso.height / 2 - 200, width = 600, height = 400 },
        noSavesMessage = { x = 60, y = gameReso.height / 2 - 100, fontSize = 24 },
        buttons = {
            retour = { x = 60, y = gameReso.height / 2 + 250, width = 180, height = 60 },
            createSave = { x = 260, y = gameReso.height / 2 + 250, width = 200, height = 60 }
        },
        notification = {
            x = gameReso.width / 2 - 200,
            y = 50,
            width = 400,
            height = 60
        }
    },

    RESOURCES = {}
}

Config.load = function()
    if json and type(json.decode) == "function" then
        -- Lire d'abord le fichier, puis décoder son contenu
        local filePath = "scene/menu/resources.json"
        local fileContent = love.filesystem.read(filePath)

        if fileContent then
            local ok, data = pcall(json.decode, fileContent)
            _configJson = ok and type(data) == "table" and data or {}
        else
            print("[config] Erreur: impossible de lire le fichier " .. filePath)
            _configJson = {}
        end
    else
        print("[config] Erreur: décodeur JSON non disponible")
        _configJson = {}
    end
    Config.RESOURCES = _configJson.menu or {}
    return Config.RESOURCES
end

return Config
