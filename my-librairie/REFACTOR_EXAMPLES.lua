-- AVANT/APRÈS : Exemples de remplacement de code dupliqué réel du projet

-- ❌ AVANT : Pattern répété partout (clamp)
-- Dans actorManager.lua ligne 141 :
st.life = math.max(0, math.min(st.life, st.maxLife))
-- Dans Enemies.lua ligne 134 :
s.life = math.max(0, math.min(s.life, s.maxLife))
-- Dans globalFunction.lua ligne 194 :
local life = math.max(0, math.min(tonumber(p_actor.state.life) or 0, maxLife))

-- ✅ APRÈS : Utilisation centralisée
local gf = _G.globalFunction
st.life = gf.clamp(st.life, 0, st.maxLife)
s.life = gf.clamp(s.life, 0, s.maxLife)
local life = gf.clamp(tonumber(p_actor.state.life) or 0, 0, maxLife)

-- ❌ AVANT : Pattern ratio répété (progress)
-- Dans hud.lua ligne 1103 :
local ratio = math.max(0, math.min(1, (el.current or 0) / max))
-- Dans transitionManager.lua ligne 77 :
local progress = math.min(1, t.time / math.max(0.0001, t.dur))

-- ✅ APRÈS : Plus sûr et plus lisible
local ratio = gf.progress(el.current or 0, max)
local progress = gf.progress(t.time, t.dur) -- gère automatiquement /0

-- ❌ AVANT : Vérification des champs répétée
if actor and actor.state and actor.state.health and actor.position then
    -- logique
end

-- ✅ APRÈS : Validation centralisée
if gf.hasFields(actor, { "state", "position" }) and gf.hasFields(actor.state, { "health" }) then
    -- logique
end

-- ❌ AVANT : Split manuel répété
local parts = {}
for part in string.gmatch(config, "([^,]+)") do
    table.insert(parts, part)
end

-- ✅ APRÈS : Fonction dédiée
local parts = gf.split(config, ",")

-- ❌ AVANT : Recherche dans table répétée
local found = false
for _, card in ipairs(hand) do
    if card.id == targetId then
        found = true
        break
    end
end

-- ✅ APRÈS : Helper dédié
local found = gf.contains(hand, targetCard)
local index = gf.indexOf(hand, targetCard) -- ou récupère l'index
