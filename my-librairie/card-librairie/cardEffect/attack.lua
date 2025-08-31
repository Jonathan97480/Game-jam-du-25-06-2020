-- my-librairie/card-librairie/cardEffect/attack.lua
local effect       = require("ressources/effect")
local actorManager = require("my-librairie/actorManager")

local attack       = {}

function attack.applique(card, attacker, target, value)
  -- valeur numérique sûre
  local amount = tonumber(value)
  if not amount then
    -- fallback depuis la carte si dispo
    local eff = card and card.effect and card.effect.hero
    amount = tonumber(eff and eff.attack) or 0
  end
  amount = math.max(0, amount)

  -- cible valide ?
  if type(target) ~= "table" or type(target.state) ~= "table" then
    return false
  end

  -- applique les dégâts via l’actorManager
  actorManager.applyEffect(target, "damage", amount, { source = attacker })

  -- animation d’attaque (signature unifiée partout: table)
  if effect and effect.play then
    effect.play({
      name    = "attack",
      vector2 = {
        x = target.vector2 and target.vector2.x or 0,
        y = (target.vector2 and target.vector2.y or 0) + ((target.height or 0) / 2) - 40
      }
    })
  end

  return true
end

return attack
