-- my-librairie/card-librairie/cardEffect/giveEpine.lua
local effect       = require("ressources/effect")
local actorManager = require("my-librairie/actorManager")

local giveEpine    = {}

-- p_card  : table carte (peut contenir effect.enemy.Epine/epine)
-- p_actor : acteur cible (ex: Enemies.curentEnemy)
-- p_value : valeur numérique optionnelle
function giveEpine.applique(p_card, p_actor, p_value)
  -- Cible valide ?
  if type(p_actor) ~= "table" or type(p_actor.state) ~= "table" then
    return false
  end

  -- Valeur d'épines sûre (priorité au paramètre, sinon fallback depuis la carte)
  local amount = tonumber(p_value)
  if not amount and p_card and p_card.effect then
    local e = p_card.effect.enemy or p_card.effect.Enemy
    amount  = e and (tonumber(e.Epine) or tonumber(e.epine)) or 0
  end
  amount = math.max(0, amount or 0)

  -- Application via l'actorManager
  actorManager.applyEffect(p_actor, "epine", amount)

  -- Animation (même signature que dans attack.applique)
  if effect and effect.play then
    local x = (p_actor.vector2 and p_actor.vector2.x) or 0
    local y = (p_actor.vector2 and p_actor.vector2.y) or 0
    effect.play("epine", x, y)
  end

  return true
end

return giveEpine
