-- Shim de compatibilité
-- Ancien emplacement : my-librairie/globals.lua
-- Ce fichier redirige vers la nouvelle implémentation core/globals.lua

local ok, globals = pcall(require, "my-librairie.core.globals")
if ok and globals then
    -- Assure les alias globaux éventuels
    if rawget(_G, "globalFunction") == nil and globals.get and globals.get("globalFunction") then
        rawset(_G, "globalFunction", globals.get("globalFunction"))
    end
    return globals
end

-- Fallback minimal pour éviter les erreurs si la migration n'est pas en place
local fallback = {}
rawset(_G, "globalFunction", rawget(_G, "globalFunction") or {})
return fallback
