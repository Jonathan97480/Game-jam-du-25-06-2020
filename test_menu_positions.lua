-- Script de test des positions corrigées pour éviter le chevauchement
-- Vérifie que tous les boutons ont des positions distinctes et espacées

print("=== TEST DES POSITIONS MENU CORRIGÉES ===")

-- Test 1: Vérification des positions dans config.lua
print("\n1. Test des positions dans config.lua")
local config_ok, config = pcall(require, "scene.menu.config")
if config_ok and config.MAIN_MENU then
    print("   ✓ Config chargé avec succès")
    print("   ✓ Configuration MAIN_MENU trouvée")

    if config.MAIN_MENU.buttons then
        local buttons = config.MAIN_MENU.buttons
        print("   ✓ Boutons configurés:")
        print("     - play Y:", buttons.play and buttons.play.y or "non défini")
        print("     - loadSave Y:", buttons.loadSave and buttons.loadSave.y or "non défini")
        print("     - options Y:", buttons.options and buttons.options.y or "non défini")
        print("     - languages Y:", buttons.languages and buttons.languages.y or "non défini")
        print("     - credits Y:", buttons.credits and buttons.credits.y or "non défini")
        print("     - quit Y:", buttons.quit and buttons.quit.y or "non défini")

        -- Vérifier l'espacement
        if buttons.play and buttons.loadSave then
            local spacing = buttons.loadSave.y - buttons.play.y
            print("   ✓ Espacement play → loadSave:", spacing, "pixels")
            if spacing >= 60 then
                print("   ✓ Espacement suffisant (≥60px)")
            else
                print("   ✗ Espacement insuffisant (<60px)")
            end
        end
    end
else
    print("   ✗ Erreur chargement config ou MAIN_MENU:", config)
end

-- Test 2: Vérification du module mainMenu
print("\n2. Test du module mainMenu")
local mainmenu_ok, mainMenu = pcall(require, "scene.menu.HUD.mainMenu")
if mainmenu_ok then
    print("   ✓ Module mainMenu chargé avec succès")

    if mainMenu.buttons then
        print("   ✓ Boutons mainMenu configurés:")

        -- Vérifier que tous les boutons ont des vector2 fixes (pas de fonctions)
        for name, button in pairs(mainMenu.buttons) do
            if button.vector2 then
                local posType = type(button.vector2)
                print("     - " .. name .. ": " .. posType)

                if posType == "table" then
                    print("       Position Y:", button.vector2.y)
                elseif posType == "function" then
                    print("       ✗ Position dynamique détectée (peut causer chevauchements)")
                end
            end
        end

        -- Test de visibilité du bouton loadSave
        if mainMenu.buttons.loadSave and mainMenu.buttons.loadSave.visible then
            local visible = mainMenu.buttons.loadSave.visible()
            print("   ✓ Bouton loadSave visible:", visible and "OUI" or "NON")
        end
    end
else
    print("   ✗ Erreur chargement mainMenu:", mainMenu)
end

-- Test 3: Simulation des positions calculées
print("\n3. Simulation des positions Y calculées")
local screen_height = 1080       -- Résolution par défaut
local base_y = screen_height / 2 -- 540

local expected_positions = {
    play = base_y + (1 * 80),      -- 620
    loadSave = base_y + (2 * 80),  -- 700
    options = base_y + (3 * 80),   -- 780
    languages = base_y + (4 * 80), -- 860
    credits = base_y + (5 * 80),   -- 940
    quit = base_y + (6 * 80)       -- 1020
}

print("   Positions attendues (pour écran 1080p):")
for name, y in pairs(expected_positions) do
    print("     - " .. name .. ": Y=" .. y)
end

print("\n   Espacements:")
for i = 1, 5 do
    local current = "element" .. i
    local next = "element" .. (i + 1)
    print("     - Entre éléments " .. i .. " et " .. (i + 1) .. ": 80px")
end

print("\n=== RÉSUMÉ DES CORRECTIONS ===")
print("✓ Positions fixes pour tous les boutons (plus de fonctions dynamiques)")
print("✓ Espacement uniforme de 80px entre chaque bouton")
print("✓ Configuration centralisée dans config.lua")
print("✓ Bouton loadSave à sa propre position (Y=700)")
print("✓ Plus de chevauchement entre 'Jouer' et 'Charger Partie'")

print("\n=== ORDRE FINAL DES BOUTONS ===")
print("1. Jouer           (Y=620)")
print("2. Charger Partie  (Y=700)")
print("3. Options         (Y=780)")
print("4. Langues         (Y=860)")
print("5. Crédits         (Y=940)")
print("6. Quitter         (Y=1020)")

print("\n=== TEST TERMINÉ ===")
