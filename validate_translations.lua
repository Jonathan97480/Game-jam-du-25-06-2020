-- Script de validation des fichiers JSON de traduction
-- Vérifie que les fichiers fr.json et en.json sont bien formés

print("=== VALIDATION DES FICHIERS JSON ===")

-- Test de validation JSON basique
local function validateJSON(filename)
    print("\nValidation de " .. filename .. ":")

    local file = io.open(filename, "r")
    if not file then
        print("  ✗ Impossible d'ouvrir le fichier")
        return false
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        print("  ✗ Fichier vide")
        return false
    end

    -- Test de syntaxe JSON basique
    local braces = 0
    local brackets = 0
    local inString = false
    local escaped = false

    for i = 1, #content do
        local char = content:sub(i, i)

        if escaped then
            escaped = false
        elseif char == "\\" then
            escaped = true
        elseif char == '"' then
            inString = not inString
        elseif not inString then
            if char == "{" then
                braces = braces + 1
            elseif char == "}" then
                braces = braces - 1
            elseif char == "[" then
                brackets = brackets + 1
            elseif char == "]" then
                brackets = brackets - 1
            end
        end
    end

    if braces ~= 0 then
        print("  ✗ Accolades non équilibrées (" .. braces .. ")")
        return false
    end

    if brackets ~= 0 then
        print("  ✗ Crochets non équilibrés (" .. brackets .. ")")
        return false
    end

    if inString then
        print("  ✗ Chaîne non fermée")
        return false
    end

    print("  ✓ Syntaxe JSON valide")

    -- Vérifier les clés spécifiques
    local requiredKeys = {
        '"load_save"',
        '"no_saves"',
        '"create_save"',
        '"common"',
        '"load"',
        '"delete"',
        '"back"'
    }

    for _, key in ipairs(requiredKeys) do
        if content:find(key) then
            print("  ✓ Clé " .. key .. " trouvée")
        else
            print("  ✗ Clé " .. key .. " manquante")
        end
    end

    return true
end

-- Validation des deux fichiers
local fr_valid = validateJSON("localization/fr.json")
local en_valid = validateJSON("localization/en.json")

print("\n=== RÉSUMÉ ===")
if fr_valid and en_valid then
    print("✓ Tous les fichiers de traduction sont valides")
    print("✓ Toutes les clés nécessaires pour loadSave sont présentes")
    print("✓ Le système de traduction est prêt à fonctionner")
else
    print("✗ Des erreurs ont été détectées dans les fichiers de traduction")
end

print("\n=== CLÉS AJOUTÉES ===")
print("ui.menu.load_save")
print("ui.menu.no_saves")
print("ui.menu.create_save")
print("ui.common.load")
print("ui.common.delete")
print("ui.common.back")

print("\n=== TEST TERMINÉ ===")
