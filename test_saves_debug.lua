-- Test pour vérifier la lecture des sauvegardes
require("my-librairie.config")

-- Initialiser les globales minimales
_G.screen = require("my-librairie.core.screen")
_G.globalFunction = require("my-librairie.core.globalFunction")
_G.saveManager = require("my-librairie.save-system.saveManager")

print("=== Test de lecture des sauvegardes ===")

local saveManager = _G.saveManager
local saves = saveManager.getSaveSlots()

print("Nombre de sauvegardes trouvées: " .. #saves)

for i, save in ipairs(saves) do
    print(string.format("Sauvegarde %d:", i))
    print(string.format("  - Filename: %s", save.filename or "N/A"))
    print(string.format("  - Slot: %s", tostring(save.slot)))
    print(string.format("  - Date: %s", save.dateString or "N/A"))
    print(string.format("  - Auto Save: %s", tostring(save.isAutoSave)))
    print("")
end

print("=== Fin du test ===")
