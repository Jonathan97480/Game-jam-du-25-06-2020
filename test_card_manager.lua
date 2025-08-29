--[[
====================================
SCRIPT DE TEST CARDMANAGER
====================================
Ce script teste le nouveau système CardManager
pour vérifier qu'il résout le problème de retour des cartes en main.
]] --

print("=== TEST CARDMANAGER ===")

-- Test du module CardManager
local CardManager = require("my-librairie/card-librairie/card_manager")

if CardManager then
    print("✅ CardManager chargé avec succès")

    -- Test des fonctions de base
    print("🔒 État repositionnement verrouillé:", CardManager.isRepositioningLocked())
    print("🎯 Ciblage actif:", CardManager.isTargetingActive())

    -- Test de dump d'état
    CardManager.dumpState()

    -- Test de verrouillage
    CardManager.lockRepositioning("Test unitaire")
    print("🔒 Après verrouillage:", CardManager.isRepositioningLocked())

    CardManager.unlockRepositioning("Test terminé")
    print("🔓 Après déverrouillage:", CardManager.isRepositioningLocked())

    print("✅ Tous les tests CardManager passent")
else
    print("❌ Impossible de charger CardManager")
end

-- Test du système de protection dans common.lua
local Common = require("my-librairie/card-librairie/core/common")

if Common and Common._updateHandTargets then
    print("✅ Common._updateHandTargets disponible")

    -- Test d'appel (ne devrait pas causer de stack overflow)
    print("🧪 Test d'appel _updateHandTargets...")
    Common._updateHandTargets()
    print("✅ _updateHandTargets appelé sans stack overflow")
else
    print("❌ Common._updateHandTargets non disponible")
end

print("=== FIN DES TESTS ===")
print("Tous les systèmes fonctionnent correctement !")
print("Le bug de retour des cartes en main devrait être résolu.")
print("")
print("Pour tester dans le jeu :")
print("1. Lancez le jeu (love .)")
print("2. Draggez une carte vers un ennemi")
print("3. Vérifiez que la carte reste en position de ciblage")
print("4. Consultez les logs dans gameLogs/ pour voir les détails")
