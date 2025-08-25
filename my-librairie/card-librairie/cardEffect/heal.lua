-- my-librairie/card-librairie/cardEffect/heal.lua
local effect       = require("ressources/effect")
local actorManager = require("my-librairie/actorManager")

local heal         = {}

-- Soigne p_actor et renvoie la quantité réellement soignée (0 si rien)
-- p_card est accepté pour homogénéité mais non utilisé ici
function heal.give(p_card, p_actor, heal_value)
  -- Garde-fous
  if type(p_actor) ~= "table" or type(p_actor.state) ~= "table" then return 0 end

  local maxLife = tonumber(p_actor.state.maxLife) or 0
  local life    = tonumber(p_actor.state.life) or 0
  local want    = math.max(0, tonumber(heal_value) or 0)

  if want <= 0 or maxLife <= 0 then return 0 end

  -- Si déjà full vie
  local missing = maxLife - life
  if missing <= 0 then return 0 end

  local amount = math.min(want, missing)

  -- Tente d'utiliser le gestionnaire d'effets s'il existe
  local before = life
  local usedManager = false
  if actorManager and type(actorManager.applyEffect) == "function" then
    -- applyEffect devrait gérer le clamp côté manager
    actorManager.applyEffect(p_actor, "heal", amount, { source = p_card })
    local after = tonumber(p_actor.state.life) or before
    amount = math.max(0, after - before)
    usedManager = true
  end

  -- Fallback manuel si pas d'actorManager/applyEffect
  if not usedManager then
    p_actor.state.life = math.min(maxLife, life + amount)
  end

  -- Animation (coordonnées sûres)
  local x = (p_actor.vector2 and p_actor.vector2.x) or 0
  local y = (p_actor.vector2 and p_actor.vector2.y) or 0
  if effect and type(effect.play) == "function" then
    effect.play("heal", x, y, { speed = 0.2, sx = 1.2, sy = 1.2 })
  end

  return amount
end

return heal
