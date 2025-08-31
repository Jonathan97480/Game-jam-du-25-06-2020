-- my-librairie/migration_cleanup.lua
-- Script utilitaire pour migrer les fichiers et nettoyer les rawget(_G, ...)
-- Usage : lua my-librairie/migration_cleanup.lua

local migration = {}

-- Patterns de migration les plus courants
local patterns = {
    -- rawget simple
    ['rawget%(_G, "(%w+)"%)'] = '_G.%1',
    ['rawget%(_G, \'(%w+)\'%)'] = '_G.%1',

    -- Patterns avec fallback
    ['rawget%(_G, "Card"%) or rawget%(_G, "card"%)'] = '_G.Card',
    ['rawget%(_G, \'Card\'%) or rawget%(_G, \'card\'%)'] = '_G.Card',

    -- Patterns complets avec require
    ['local (%w+)%s*=%s*rawget%(_G, "(%w+)"%)[^;]*'] = 'local %1 = _G.%2',
    ['local (%w+)%s*=%s*rawget%(_G, \'(%w+)\'%)[^;]*'] = 'local %1 = _G.%2',
}

-- Liste des globales connues pour validation
local knownGlobals = {
    "json", "hud", "Card", "screen", "scene", "effect", "Transition",
    "inputManager", "actorManager", "globalFunction", "myFunction", "myFonction",
    "Hero", "Enemies", "GameFlags", "HUD_BOTTOM_BG_PATH"
}

function migration.isKnownGlobal(name)
    for _, known in ipairs(knownGlobals) do
        if known == name then return true end
    end
    return false
end

function migration.processFile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        print("Erreur: impossible d'ouvrir " .. filepath)
        return false
    end

    local content = file:read("*all")
    file:close()

    local modified = false
    local newContent = content

    -- Applique les patterns de migration
    for pattern, replacement in pairs(patterns) do
        local oldContent = newContent
        newContent = newContent:gsub(pattern, replacement)
        if newContent ~= oldContent then
            modified = true
            print("  - Appliqué: " .. pattern .. " -> " .. replacement)
        end
    end

    if modified then
        -- Sauvegarde
        local backupFile = filepath .. ".backup"
        local backup = io.open(backupFile, "w")
        if backup then
            backup:write(content)
            backup:close()
            print("  - Backup créé: " .. backupFile)
        end

        -- Écriture du nouveau contenu
        local outFile = io.open(filepath, "w")
        if outFile then
            outFile:write(newContent)
            outFile:close()
            print("  - Fichier mis à jour: " .. filepath)
            return true
        else
            print("  - Erreur: impossible d'écrire " .. filepath)
            return false
        end
    else
        print("  - Aucune modification nécessaire")
        return true
    end
end

function migration.scanDirectory(dir)
    -- Cette fonction nécessiterait lfs (LuaFileSystem) pour être complète
    -- Pour l'instant, on liste manuellement les fichiers importants
    local files = {
        "my-librairie/ai/controller.lua",
        "scene/overlay_start/overlay_start.lua",
        "scene/gameplay/HUD/hud_gameplay.lua",
        "my-librairie/transition/templateCombatTransition.lua"
    }

    print("=== Migration des globales ===")
    print("Début du processus de migration...")

    for _, file in ipairs(files) do
        print("\nTraitement: " .. file)
        migration.processFile(file)
    end

    print("\n=== Migration terminée ===")
    print("N'oubliez pas de tester que tout fonctionne encore !")
    print("Les backups sont disponibles avec l'extension .backup")
end

-- Auto-exécution si appelé directement
if ... == nil then
    migration.scanDirectory(".")
end

return migration
