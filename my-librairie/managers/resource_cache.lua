-- Auto-generated resource cache to prevent repeated allocations.
local res = {}

local _images = {}
--[[*
    Charge une image et la met en cache.
    @param path Le chemin de l'image à charger.
    @return L'image chargée ou nil en cas d'erreur.
--]]
--[[
Fonction : res.image
Rôle : Fonction « Image » liée à la logique du jeu.
Paramètres :
  - path : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function res.image(path)
    assert(type(path) == "string", "res.image expects a string path")
    if not _images[path] then
        _images[path] = love.graphics.newImage(path)
    end

    return _images[path] or nil
end

local _fonts = {}
--[[
Fonction : res.font
Rôle : Fonction « Font » liée à la logique du jeu.
Paramètres :
  - path_or_size : paramètre détecté automatiquement.
  - size : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function res.font(path_or_size, size)
    if type(path_or_size) == "number" then
        local key = "__default__:" .. tostring(path_or_size)
        if not _fonts[key] then
            _fonts[key] = love.graphics.newFont(path_or_size)
        end
        return _fonts[key]
    else
        local path = path_or_size
        local s = size or 12
        local key = path .. ":" .. tostring(s)
        if not _fonts[key] then
            _fonts[key] = love.graphics.newFont(path, s)
        end
        return _fonts[key]
    end
end

local _sources = {}
--[[
Fonction : res.audio
Rôle : Fonction « Audio » liée à la logique du jeu.
Paramètres :
  - path : paramètre détecté automatiquement.
  - type_hint : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function res.audio(path, type_hint)
    assert(type(path) == "string", "res.audio expects a string path")
    local key = path .. ":" .. (type_hint or "")
    if not _sources[key] then
        _sources[key] = love.audio.newSource(path, type_hint or "static")
    end
    return _sources[key]:clone()
end

return res
