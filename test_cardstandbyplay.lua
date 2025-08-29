--[[
====================================
TEST CARDSTANDBYPLAY
====================================
Test complet du nouveau système CardStandbyPlay
]] --

print("=== TEST CARDSTANDBYPLAY ===")

-- Test du système CardStandbyPlay
local CardStandbyPlay = require("my-librairie/card-librairie/cardStandbyPlay")

if CardStandbyPlay then
    print("✅ CardStandbyPlay chargé avec succès")

    -- Initialiser le système
    CardStandbyPlay.init()

    -- Test des fonctions de base
    print("🎯 État initial:")
    print("  - Carte en standby:", CardStandbyPlay.hasCardInStandby())
    print("  - Gestion main désactivée:", CardStandbyPlay.isHandManagementDisabled())

    -- Simuler une carte
    local testCard = {
        name = "Carte de Test",
        position = { x = 500, y = 600 },
        vector2 = { x = 500, y = 600 }
    }

    -- Test mise en standby
    print("\n🔄 Test mise en standby...")
    local success = CardStandbyPlay.putCardInStandby(testCard, 1)
    print("  - Mise en standby réussie:", success)
    print("  - Carte en standby:", CardStandbyPlay.hasCardInStandby())
    print("  - Gestion main désactivée:", CardStandbyPlay.isHandManagementDisabled())

    -- Afficher l'état
    CardStandbyPlay.dumpState()

    -- Test annulation
    print("\n❌ Test annulation...")
    local cancelSuccess = CardStandbyPlay.returnCardToHand()
    print("  - Annulation réussie:", cancelSuccess)
    print("  - Carte en standby:", CardStandbyPlay.hasCardInStandby())
    print("  - Gestion main réactivée:", not CardStandbyPlay.isHandManagementDisabled())

    -- Test confirmation
    print("\n✅ Test confirmation...")
    CardStandbyPlay.putCardInStandby(testCard, 1)
    local confirmSuccess = CardStandbyPlay.confirmCardPlay()
    print("  - Confirmation réussie:", confirmSuccess)
    print("  - Carte en standby:", CardStandbyPlay.hasCardInStandby())

    print("\n✅ Tous les tests CardStandbyPlay passent!")
else
    print("❌ Impossible de charger CardStandbyPlay")
end

print("=== FIN DES TESTS ===")
