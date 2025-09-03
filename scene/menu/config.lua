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
