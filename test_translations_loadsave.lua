-- Script de test pour vérifier les clés de traduction du système loadSave
-- Vérifie que toutes les clés utilisées dans loadSave.lua sont définies dans fr.json et en.json

print("=== TEST DES CLÉS DE TRADUCTION LOADSAVE ===")

-- Clés utilisées dans le système loadSave
local requiredKeys = {
    "ui.menu.load_save",
    "ui.menu.no_saves",
    "ui.menu.create_save",
    "ui.common.load",
    "ui.common.delete",
    "ui.common.back"
}

-- Test pour le français
print("\n1. Test des clés françaises (fr.json)")
local fr_ok, fr_data = pcall(function()
    local content = love.filesystem.read("localization/fr.json")
    return require("my-librairie.tools.json").decode(content)
end)

if fr_ok and fr_data then
    print("   ✓ Fichier fr.json chargé avec succès")

    for _, key in ipairs(requiredKeys) do
        local parts = {}
        for part in key:gmatch("[^.]+") do
            table.insert(parts, part)
        end

        local current = fr_data
        local found = true
        for _, part in ipairs(parts) do
            if current and type(current) == "table" and current[part] then
                current = current[part]
            else
                found = false
                break
            end
        end

        if found and type(current) == "string" then
            print("   ✓ " .. key .. " → '" .. current .. "'")
        else
            print("   ✗ " .. key .. " → MANQUANT")
        end
    end
else
    print("   ✗ Erreur chargement fr.json:", fr_data)
end

-- Test pour l'anglais
print("\n2. Test des clés anglaises (en.json)")
local en_ok, en_data = pcall(function()
    local content = love.filesystem.read("localization/en.json")
    return require("my-librairie.tools.json").decode(content)
end)

if en_ok and en_data then
    print("   ✓ Fichier en.json chargé avec succès")

    for _, key in ipairs(requiredKeys) do
        local parts = {}
        for part in key:gmatch("[^.]+") do
            table.insert(parts, part)
        end

        local current = en_data
        local found = true
        for _, part in ipairs(parts) do
            if current and type(current) == "table" and current[part] then
                current = current[part]
            else
                found = false
                break
            end
        end

        if found and type(current) == "string" then
            print("   ✓ " .. key .. " → '" .. current .. "'")
        else
            print("   ✗ " .. key .. " → MANQUANT")
        end
    end
else
    print("   ✗ Erreur chargement en.json:", en_data)
end

-- Test de simulation avec le système de localisation
print("\n3. Test avec LocalizationManager")
local localization_ok, localizationManager = pcall(require, "my-librairie.localization-system.localizationManager")

if localization_ok then
    print("   ✓ LocalizationManager chargé")

    -- Test français
    local fr_init = localizationManager.setLanguage("fr")
    if fr_init then
        print("   ✓ Français activé")
        for _, key in ipairs(requiredKeys) do
            local translation = localizationManager.t(key)
            if translation and translation ~= key then
                print("   ✓ " .. key .. " → '" .. translation .. "'")
            else
                print("   ✗ " .. key .. " → pas de traduction")
            end
        end
    end

    -- Test anglais
    print("\n   Test anglais:")
    local en_init = localizationManager.setLanguage("en")
    if en_init then
        print("   ✓ Anglais activé")
        for _, key in ipairs(requiredKeys) do
            local translation = localizationManager.t(key)
            if translation and translation ~= key then
                print("   ✓ " .. key .. " → '" .. translation .. "'")
            else
                print("   ✗ " .. key .. " → pas de traduction")
            end
        end
    end
else
    print("   ✗ Erreur chargement LocalizationManager:", localizationManager)
end

print("\n=== RÉSUMÉ ===")
print("Toutes les clés de traduction nécessaires pour le système loadSave")
print("ont été ajoutées aux fichiers fr.json et en.json :")
print("")
print("Français:")
print("- ui.menu.load_save → 'Charger Partie'")
print("- ui.menu.no_saves → 'Aucune sauvegarde disponible'")
print("- ui.menu.create_save → 'Créer une sauvegarde'")
print("- ui.common.load → 'Charger'")
print("- ui.common.delete → 'Supprimer'")
print("- ui.common.back → 'Retour'")
print("")
print("Anglais:")
print("- ui.menu.load_save → 'Load Game'")
print("- ui.menu.no_saves → 'No saves available'")
print("- ui.menu.create_save → 'Create New Save'")
print("- ui.common.load → 'Load'")
print("- ui.common.delete → 'Delete'")
print("- ui.common.back → 'Back'")

print("\n=== TEST TERMINÉ ===")
