-- test/card_librairie_cardEffect_test.lua
-- Tests unitaires pour les effets de carte : attack, heal, giveEpine, giveSheld

-- Mocks globaux pour dépendances
package.loaded["ressources/effect"]         = {
    play = function() end
}
package.loaded["my-librairie/actorManager"] = {
    applyEffect = function(actor, effectType, value)
        actor._lastEffect = { effectType = effectType, value = value }
        if effectType == "damage" then
            actor.state.life = (actor.state.life or 0) - value
        elseif effectType == "heal" then
            actor.state.life = math.min((actor.state.maxLife or 0), (actor.state.life or 0) + value)
        elseif effectType == "epine" then
            actor.state.epine = (actor.state.epine or 0) + value
        elseif effectType == "shield" then
            actor.state.shield = (actor.state.shield or 0) + value
        end
    end
}

local attack                                = require("my-librairie/card-librairie/cardEffect/attack")
local heal                                  = require("my-librairie/card-librairie/cardEffect/heal")
local giveEpine                             = require("my-librairie/card-librairie/cardEffect/giveEpine")
local giveSheld                             = require("my-librairie/card-librairie/cardEffect/giveSheld")

-- Utilitaire d'assertion
local function assertEq(a, b, msg)
    if a ~= b then error((msg or "") .. " attendu: " .. tostring(b) .. ", obtenu: " .. tostring(a), 2) end
end

-- Test attack
local target = { state = { life = 20 }, vector2 = { x = 0, y = 0 }, height = 100 }
local ok = attack.applique({ effect = { hero = { attack = 5 } } }, { name = "hero" }, target, 7)
assertEq(ok, true, "attack.applique doit retourner true")
assertEq(target.state.life, 13, "attack doit retirer 7 de vie")

-- Test heal
local actor = { state = { life = 5, maxLife = 10 } }
local healed = heal.give({}, actor, 4)
assertEq(actor.state.life, 9, "heal.give doit soigner correctement")

-- Test giveEpine
local actor2 = { state = { epine = 1 }, vector2 = { x = 0, y = 0 } }
local ok2 = giveEpine.applique({ effect = { enemy = { Epine = 3 } } }, actor2, 2)
assertEq(ok2, true, "giveEpine.applique doit retourner true")
assertEq(actor2.state.epine, 3, "giveEpine doit ajouter les épines")

-- Test giveSheld
local actor3 = { state = { shield = 2 }, vector2 = { x = 0, y = 0 } }
local ok3 = giveSheld.applique({ effect = { enemy = { shield = 5 } } }, actor3, 4)
assertEq(ok3, true, "giveSheld.applique doit retourner true")
assertEq(actor3.state.shield, 6, "giveSheld doit ajouter le bouclier")

print("[TEST] cardEffect : OK")
