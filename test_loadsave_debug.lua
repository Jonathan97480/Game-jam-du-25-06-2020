-- Test simple pour vérifier le système loadSave
-- À exécuter depuis la console pour debugger

print("=== TEST LOADSAVE SYSTEM ===")

-- Vérifier SaveManager
if _G.saveManager then
    print("✅ SaveManager disponible")

    -- Obtenir statistiques
    local stats = _G.saveManager.getStats()
    if stats then
        print("📊 Statistiques SaveManager:")
        print("  - Total sauvegardes:", stats.totalSaves)
        print("  - Auto-saves:", stats.autoSaves)
        print("  - Manuelles:", stats.manualSaves)
        print("  - Auto-save activé:", stats.autoSaveEnabled)
    end

    -- Lister sauvegardes
    local saves = _G.saveManager.getSaveSlots()
    print("📋 Sauvegardes disponibles:", #saves)
    for i, save in ipairs(saves) do
        print("  " .. i .. ". " .. save.displayName .. " (" .. (save.isAutoSave and "AUTO" or "MANUAL") .. ")")
    end

    -- Créer une sauvegarde test si aucune
    if #saves == 0 then
        print("🔧 Création d'une sauvegarde test...")
        local success, result = _G.saveManager.saveToSlot(1)
        if success then
            print("✅ Sauvegarde test créée:", result)
        else
            print("❌ Échec création sauvegarde test:", result)
        end
    end
else
    print("❌ SaveManager non disponible")
end

-- Vérifier LoadSave
if _G.loadSave then
    print("✅ LoadSave module disponible")
    print("  - Sauvegardes détectées:", _G.loadSave.hasSaves and _G.loadSave.hasSaves() or "fonction manquante")
    print("  - Nombre de sauvegardes:", _G.loadSave.getSaveCount and _G.loadSave.getSaveCount() or "fonction manquante")
else
    print("❌ LoadSave module non disponible")
end

-- Vérifier menu principal
if _G.mainMenu then
    print("✅ MainMenu disponible")
else
    print("❌ MainMenu non disponible")
end

print("=== FIN TEST ===")
