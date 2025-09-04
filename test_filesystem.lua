-- Test pour comprendre où LÖVE2D peut écrire
print("=== Test système de fichiers LÖVE2D ===")

-- Simuler l'environnement LÖVE2D
local love = {
    filesystem = {
        getSaveDirectory = function() return "C:\\Users\\berou\\AppData\\Roaming\\LOVE\\Game-jam-du-25-06-2020" end,
        getInfo = function(path)
            print("getInfo appelé pour: " .. path)
            return nil
        end,
        createDirectory = function(path)
            print("createDirectory appelé pour: " .. path)
            return true
        end,
        write = function(filename, data)
            print("write appelé pour: " .. filename)
            print("Chemin complet serait: " .. love.filesystem.getSaveDirectory() .. "/" .. filename)
            return false, "Could not open file " .. filename .. " (not found)"
        end
    }
}

-- Test avec le chemin du SaveManager
local SAVE_DIRECTORY = "saves/"
local filename = SAVE_DIRECTORY .. "test_save.json"

print("\n1. Répertoire de sauvegarde LÖVE2D:")
print(love.filesystem.getSaveDirectory())

print("\n2. Test création dossier:")
local success = love.filesystem.createDirectory(SAVE_DIRECTORY)
print("Résultat createDirectory: " .. tostring(success))

print("\n3. Test écriture fichier:")
local writeSuccess, writeError = love.filesystem.write(filename, '{"test": true}')
print("Résultat write: " .. tostring(writeSuccess))
print("Erreur: " .. tostring(writeError))

print("\n=== Conclusion ===")
print("LÖVE2D essaie d'écrire dans son répertoire de sauvegarde, pas dans le dossier du jeu.")
print("Le dossier 'saves/' doit être créé dans le répertoire de sauvegarde de LÖVE2D.")
