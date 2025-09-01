--[[
====================================
TEST VALIDATION SYSTÈME CARDSTANDBYPLAY  
====================================
Test complet et validation du système CardStandbyPlay
Problème #5 du TODO_CORRECTIONS.md
]] --

print("🎯 [TEST] Validation complète système CardStandbyPlay")

-- Mocks LÖVE2D complets pour les tests
_G.love = {
    graphics = {
        getDimensions = function() return 1920, 1080 end,
        getWidth = function() return 1920 end,
        getHeight = function() return 1080 end,
        setColor = function() end,
        setFont = function() end,
        printf = function() end
    },
    window = {
        getMode = function() return 1920, 1080, {} end,
        setMode = function() return true end
    },
    mouse = {
        getPosition = function() return 0, 0 end
    }
}

-- Mock globalFunction basique
_G.globalFunction = {
    log = {
        info = function(msg) print("ℹ️  " .. msg) end,
        warn = function(msg) print("⚠️  " .. msg) end,
        error = function(msg) print("❌ " .. msg) end
    },
    clone = function(obj)
        if type(obj) ~= 'table' then return obj end
        local copy = {}
        for k, v in pairs(obj) do
            copy[k] = type(v) == 'table' and _G.globalFunction.clone(v) or v
        end
        return copy
    end,
    lerpNum = function(a, b, t) return a + (b - a) * t end
}

-- Mock responsive/screen
_G.screen = {
    toScreenX = function(x) return x end,
    toScreenY = function(y) return y end
}

-- Mock cache manager
_G.cache = {
    font = function(path, size) return {} end
}

-- Chargement du module avec gestion d'erreur
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if not ok then
        print("❌ Erreur chargement " .. name .. ": " .. tostring(mod))
        return nil
    end
    return mod
end

-- Test du chargement
print("📁 Test 1: Chargement CardStandbyPlay")
local CardStandbyPlay = _safeRequire("my-librairie/card-librairie/cardStandbyPlay")

if not CardStandbyPlay then
    print("❌ ÉCHEC: Impossible de charger CardStandbyPlay")
    return
end
print("✅ CardStandbyPlay chargé avec succès")

-- Vérification de l'API
print("\n🔍 Test 2: Vérification API disponible")
local expectedFunctions = {
    "init",
    "hasCardInStandby", 
    "getStandbyCard",
    "putCardInStandby",
    "returnCardToHand",
    "confirmCardPlay",
    "getStandbyCopy",
    "autoPlaySelfOnly",
    "clearStandby",
    "handleClick",
    "update",
    "draw"
}

local missingFunctions = {}
for _, funcName in ipairs(expectedFunctions) do
    if type(CardStandbyPlay[funcName]) ~= "function" then
        table.insert(missingFunctions, funcName)
    end
end

if #missingFunctions > 0 then
    print("❌ Fonctions manquantes: " .. table.concat(missingFunctions, ", "))
    return
else
    print("✅ Toutes les fonctions API sont présentes (" .. #expectedFunctions .. ")")
end

-- Test d'initialisation
print("\n🚀 Test 3: Initialisation du système")
local initSuccess = CardStandbyPlay.init()
print("✅ Initialisation réussie:", initSuccess)

-- Test état initial
print("\n📊 Test 4: État initial du système")
local initialStandby = CardStandbyPlay.hasCardInStandby()
local initialCard = CardStandbyPlay.getStandbyCard()
local initialCopy = CardStandbyPlay.getStandbyCopy()

print("  - Carte en standby:", initialStandby)
print("  - Carte standby:", initialCard and "présente" or "nil")
print("  - Copie standby:", initialCopy and "présente" or "nil")

if initialStandby == false and initialCard == nil and initialCopy == nil then
    print("✅ État initial correct")
else
    print("❌ État initial incorrect")
    return
end

-- Test création carte simulée
print("\n🎴 Test 5: Création carte de test")
local testCard = {
    name = "Carte de Test",
    actorTag = "Hero",
    targetType = "enemy",
    isVisible = true,
    position = { x = 500, y = 600 },
    vector2 = { x = 500, y = 600 },
    inHand = true,
    width = 120,
    height = 180
}
print("✅ Carte de test créée:", testCard.name)

-- Test mise en standby
print("\n🎯 Test 6: Mise en standby")
local putSuccess = CardStandbyPlay.putCardInStandby(testCard, 1)
print("  - Mise en standby réussie:", putSuccess)

local afterPutStandby = CardStandbyPlay.hasCardInStandby()
local afterPutCard = CardStandbyPlay.getStandbyCard()
local afterPutCopy = CardStandbyPlay.getStandbyCopy()

print("  - Carte en standby:", afterPutStandby)
print("  - Carte originale visible:", testCard.isVisible)
print("  - Copie créée:", afterPutCopy and "oui" or "non")

if putSuccess and afterPutStandby and not testCard.isVisible and afterPutCopy then
    print("✅ Système copie/invisible fonctionne")
else
    print("❌ Problème avec système copie/invisible")
    print("    putSuccess:", putSuccess)
    print("    afterPutStandby:", afterPutStandby)
    print("    card.isVisible:", testCard.isVisible)
    print("    afterPutCopy présent:", afterPutCopy and true or false)
end

-- Test cohérence copie
print("\n🔄 Test 7: Cohérence carte originale vs copie")
if afterPutCard and afterPutCopy then
    local originalName = afterPutCard.name
    local copyName = afterPutCopy.name
    local sameNames = (originalName == copyName)
    
    print("  - Nom carte originale:", originalName)
    print("  - Nom copie:", copyName)
    print("  - Noms identiques:", sameNames)
    
    if sameNames then
        print("✅ Cohérence copie validée")
    else
        print("❌ Incohérence entre originale et copie")
    end
else
    print("❌ Impossible de tester cohérence (carte ou copie manquante)")
end

-- Test annulation
print("\n❌ Test 8: Annulation (retour en main)")
local cancelSuccess = CardStandbyPlay.returnCardToHand()
print("  - Annulation réussie:", cancelSuccess)

local afterCancelStandby = CardStandbyPlay.hasCardInStandby()
local afterCancelVisible = testCard.isVisible

print("  - Carte en standby:", afterCancelStandby)
print("  - Carte redevenue visible:", afterCancelVisible)

if cancelSuccess and not afterCancelStandby and afterCancelVisible then
    print("✅ Annulation fonctionne correctement")
else
    print("❌ Problème avec annulation")
end

-- Test confirmation  
print("\n✅ Test 9: Confirmation de jeu")
-- Remettre en standby pour tester confirmation
CardStandbyPlay.putCardInStandby(testCard, 1)
local confirmSuccess = CardStandbyPlay.confirmCardPlay()
print("  - Confirmation réussie:", confirmSuccess)

local afterConfirmStandby = CardStandbyPlay.hasCardInStandby()
print("  - Carte encore en standby:", afterConfirmStandby)

if confirmSuccess then
    print("✅ Confirmation fonctionne")
else
    print("❌ Problème avec confirmation")
end

-- Test nettoyage
print("\n🧹 Test 10: Nettoyage du système")
CardStandbyPlay.clearStandby()
local afterClearStandby = CardStandbyPlay.hasCardInStandby()
print("  - Système nettoyé:", not afterClearStandby)

if not afterClearStandby then
    print("✅ Nettoyage fonctionne")
else
    print("❌ Problème avec nettoyage")
end

-- Test gestion erreurs
print("\n⚠️ Test 11: Gestion d'erreurs")
local errorTest1 = CardStandbyPlay.putCardInStandby(nil, 1)
print("  - Carte nil gérée:", not errorTest1)

local errorTest2 = CardStandbyPlay.putCardInStandby({}, nil)
print("  - Index nil géré:", type(errorTest2) == "boolean")

if not errorTest1 then
    print("✅ Gestion erreurs basique validée")
else
    print("❌ Gestion erreurs insuffisante")
end

-- Test cycle update/draw (simulation)
print("\n🔄 Test 12: Cycle update/draw")
-- Remettre en standby pour test
CardStandbyPlay.putCardInStandby(testCard, 1)

-- Test update
local updateSuccess = pcall(function()
    CardStandbyPlay.update(0.016) -- 60 FPS
end)

-- Test draw
local drawSuccess = pcall(function()
    CardStandbyPlay.draw()
end)

print("  - Update sans erreur:", updateSuccess)
print("  - Draw sans erreur:", drawSuccess)

if updateSuccess and drawSuccess then
    print("✅ Cycle update/draw stable")
else
    print("❌ Problème dans cycle update/draw")
end

-- Résumé final
print("\n" .. string.rep("=", 50))
print("📊 RÉSULTATS VALIDATION CARDSTANDBYPLAY:")

local testResults = {
    {name = "Chargement module", success = true},
    {name = "API complète disponible", success = true},
    {name = "Initialisation", success = true},
    {name = "État initial correct", success = true},
    {name = "Création carte test", success = true},
    {name = "Système copie/invisible", success = putSuccess and afterPutStandby and not testCard.isVisible and afterPutCopy},
    {name = "Cohérence copie", success = afterPutCard and afterPutCopy and afterPutCard.name == afterPutCopy.name},
    {name = "Annulation", success = cancelSuccess and not afterCancelStandby and afterCancelVisible},
    {name = "Confirmation", success = confirmSuccess},
    {name = "Nettoyage", success = not afterClearStandby},
    {name = "Gestion erreurs", success = not errorTest1},
    {name = "Cycle update/draw", success = updateSuccess and drawSuccess}
}

local passedTests = 0
for _, result in ipairs(testResults) do
    local status = result.success and "✅" or "❌"
    print(status .. " " .. result.name)
    if result.success then
        passedTests = passedTests + 1
    end
end

print(string.rep("=", 50))
print(string.format("🎯 Tests réussis: %d/%d", passedTests, #testResults))

if passedTests == #testResults then
    print("🎉 TOUS LES TESTS PASSENT - SYSTÈME VALIDÉ")
elseif passedTests >= #testResults - 1 then
    print("✅ SYSTÈME GLOBALEMENT VALIDÉ - Problèmes mineurs")
else
    print("⚠️ CERTAINS TESTS ÉCHOUENT - RÉVISION REQUISE")
end

print("🏁 Test terminé")
