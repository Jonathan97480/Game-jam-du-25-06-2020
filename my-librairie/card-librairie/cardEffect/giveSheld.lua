-- my-librairie/card-librairie/cardEffect/giveSheld.lua
local effect       = require("ressources/effect")
local actorManager = require("my-librairie/actorManager")

local giveSheld    = {}

-- p_card  : table carte (peut contenir effect.enemy.shield)
-- p_actor : acteur cible (ex: Enemies.curentEnemy)
-- p_value : valeur numérique optionnelle (prioritaire sur la carte)
function giveSheld.applique(p_card, p_actor, p_value)
  -- Cible valide ?
  if type(p_actor) ~= "table" or type(p_actor.state) ~= "table" then
    return false
  end

  -- Valeur de bouclier sûre
  local amount = tonumber(p_value)
  if not amount and p_card and p_card.effect then
    local e = p_card.effect.enemy or p_card.effect.Enemy
    amount  = e and tonumber(e.shield) or 0
  end
  amount = math.max(0, amount or 0)

  -- Application via actorManager (gère l’addition proprement)
  actorManager.applyEffect(p_actor, "shield", amount)
  -- Si jamais tu n’utilises pas applyEffect :
  -- p_actor.state.shield = (p_actor.state.shield or 0) + amount

  -- Animation
  if effect and effect.play then
    local x = (p_actor.vector2 and p_actor.vector2.x) or 0
    local y = (p_actor.vector2 and p_actor.vector2.y) or 0
    effect.play("shield", x, y)
  end

  return true
end

return giveSheld
