-- my-librairie/ai/controller.lua
-- IA : logique de jeu des cartes (pipeline Card.* + fallback) + auto-câblage du télégraphe (visuel optionnel)

local heal                    = require("my-librairie/card-librairie/cardEffect/heal")
local shield                  = require("my-librairie/card-librairie/cardEffect/giveSheld")
local attack                  = require("my-librairie/card-librairie/cardEffect/attack")
local epine                   = require("my-librairie/card-librairie/cardEffect/giveEpine")
local actorMgr                = _G.actorManager or require("my-librairie/actorManager")

local Card                    = rawget(_G, "Card") or rawget(_G, "card")
local Hero                    = rawget(_G, "Hero")
local Enemies                 = rawget(_G, "Enemies")
local Transition              = rawget(_G, "Transition")

local timerMaxTurnChanged     = 1
local timerDrawTurned         = 0
local lastTurnTransitionState = ''

local AI                      = {
  state               = "idle",
  timer               = 0,
  telegraphMin        = 0.3,

  currentIndex        = nil,
  currentCard         = nil,
  lastPlayed          = nil,

  busy                = false,
  running             = false,
  _endSent            = false,
  enemy               = nil,
  _badDtWarned        = false,
  DEBUG               = true,

  -- Visuel (télégraphe) :
  AUTO_WIRE_TELEGRAPH = true, -- branche automatiquement my-librairie/ai/telegraph s'il existe
  listener            = nil,  -- objet visuel optionnel (voir telegraph.lua)
}

-- ---------- LOG / SAFE ----------
local function log(...) if AI.DEBUG then print(...) end end
local function logf(fmt, ...) if AI.DEBUG then print(string.format(fmt, ...)) end end
local function safecall(tag, fn, ...)
  if type(fn) ~= "function" then
    logf("[AI][safe:%s] fn=nil", tostring(tag))
    return false
  end
  local ok, err = pcall(fn, ...)
  if not ok then logf("[AI][safe:%s] ERREUR -> %s", tostring(tag), tostring(err)) end
  return ok
end
local function tstr(v, depth)
  depth = depth or 0
  if type(v) ~= "table" then return tostring(v) end
  if depth > 2 then return "{...}" end
  local parts = {}
  for k, val in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. tstr(val, depth + 1) end
  return "{" .. table.concat(parts, ", ") .. "}"
end

-- ---------- VISUEL / LISTENER ----------
function AI.setListener(l)
  AI.listener = l
end

function AI.setConfig(opts)
  if type(opts) ~= "table" then return end
  if opts.telegraphMin ~= nil then AI.telegraphMin = tonumber(opts.telegraphMin) or AI.telegraphMin end
end

local function _notify(event, ...)
  local L = AI.listener
  if L and type(L[event]) == "function" then
    local ok, err = pcall(L[event], L, AI, ...)
    if not ok then logf("[AI][listener.%s] erreur: %s", event, tostring(err)) end
  end
end

-- Essaie d'afficher la carte IA via des APIs possibles du module Card
local function showCardVisual(_card)
  local CardManager = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not CardManager then return false end
  if (_card and type(_card) == 'table') then
    AI.listener:onTelegraph(_card, AI.telegraphMin, AI)
  end
  logf("[AI][VISUAL] _card n'est de type table il est du type %s", tostring(type(_card)))
  return false
end

-- Auto-câblage du télégraphe si disponible
local function _autoWireTelegraph()
  if not AI.AUTO_WIRE_TELEGRAPH then return end
  if AI.listener ~= nil then return end
  local ok, Telegraph = pcall(require, "my-librairie/ai/telegraph")
  if ok and type(Telegraph) == "table" then
    AI.setListener(Telegraph)
    if type(Telegraph.setDelay) == "function" and tonumber(AI.telegraphMin) then
      Telegraph:setDelay(AI.telegraphMin)
    end
    if type(Telegraph.setEnabled) == "function" then
      Telegraph:setEnabled(true)
    end
    print("[AI] Telegraph auto-câblé depuis le contrôleur.")
  else
    print("[AI] Telegraph indisponible (require a échoué) : visuel désactivé.")
  end
end

-- ---------- SNAP / DELTA ----------
local function snap(actor)
  if not actor or not actor.state then return { life = 0, max = 0, sh = 0, ep = 0, pwr = 0 } end
  local s = actor.state
  return {
    life = tonumber(s.life) or 0,
    max  = tonumber(s.maxLife) or 0,
    sh   = tonumber(s.shield) or 0,
    ep   = tonumber(s.epine) or 0,
    pwr  = tonumber(s.power) or 0,
  }
end
local function delta(b, a)
  local function d(k) return (a[k] or 0) - (b[k] or 0) end
  return string.format("Δ life=%+d, shield=%+d, epine=%+d, power=%+d", d("life"), d("sh"), d("ep"), d("pwr"))
end

-- ---------- HELPERS ----------
local function ensureAIContainers()
  Card = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not Card then return nil end
  Card.deckAi = Card.deckAi or {}
  return Card.deckAi
end
local function lifeRatio(actor)
  if not actor or not actor.state then return 1 end
  local max = tonumber(actor.state.maxLife) or 1
  if max <= 0 then max = 1 end
  local cur = tonumber(actor.state.life) or 0
  return cur / max
end
local function getShield(actor)
  if not actor or not actor.state then return 0 end
  return tonumber(actor.state.shield) or 0
end
local function normDt(dt)
  if type(dt) == "number" then return dt end
  if type(dt) == "table" then
    if type(dt.dt) == "number" then return dt.dt end
    if type(dt[1]) == "number" then return dt[1] end
  end
  if not AI._badDtWarned then
    print("[AI] WARN: dt non-numérique -> fallback 0.016")
    AI._badDtWarned = true
  end
  return 0.016
end


local function drawTourCh(state, dt)
  if (state ~= lastTurnTransitionState) then
    if (state == 'player' or state == 'Enemy') then
      timerDrawTurned = 0
      lastTurnTransitionState = state
    end
  end
  if (timerDrawTurned < timerMaxTurnChanged) then
    timerDrawTurned = timerDrawTurned + dt
    -- Mettre à jour l'affichage du tour
    local text = lastTurnTransitionState == 'player' and "Tour du joueur" or "Tour de l'ennemi"
    --calcul de la position en x
    local responsive = require("my-librairie/responsive")
    local _x = responsive.gameReso.width / 2 - 100
    local _y = 200
    --calcul size font parapore la résolution de l'écrant

    hud.text(text, _x, _y, {

      fontSize = 50,
      color = { 1, 1, 1, 1 },
    })
  end
end


-- ---------- EFFETS (fallback) ----------
local ALIAS = {
  attack = "attack",
  dmg = "attack",
  damage = "attack",
  hit = "attack",
  heal = "heal",
  hp = "heal",
  shield = "shield",
  armor = "shield",
  block = "shield",
  guard = "shield",
  Epine = "epine",
  epine = "epine",
  thorns = "epine",
  skip = "skip",
  stun = "skip",
  sleep = "skip",
}
local function _acc(t, k, v)
  k = ALIAS[k] or k
  local n = tonumber(v); if not n then return end
  t[k] = (t[k] or 0) + n
end
local function getEffects(c)
  local hero, enemy = {}, {}
  if type(c) ~= "table" then return { hero = hero, enemy = enemy } end

  local eff = c.Effect or c.effect or c.effects or c.Effects
  if type(eff) == "table" then
    if type(eff.hero) == "table" then for k, v in pairs(eff.hero) do _acc(hero, k, v) end end
    if type(eff.enemy) == "table" then for k, v in pairs(eff.enemy) do _acc(enemy, k, v) end end
  end

  for _, key in ipairs({ "attack", "damage", "dmg", "heal", "shield", "armor", "Epine", "epine", "thorns", "skip" }) do
    if c[key] ~= nil then
      if key == "attack" or key == "damage" or key == "dmg" or key == "skip" then
        _acc(hero, key, c[key])
      else
        _acc(enemy, key, c[key])
      end
    end
  end

  for _, side in ipairs({ "hero", "Hero" }) do
    if type(c[side]) == "table" then for k, v in pairs(c[side]) do _acc(hero, k, v) end end
  end
  for _, side in ipairs({ "enemy", "Enemy" }) do
    if type(c[side]) == "table" then for k, v in pairs(c[side]) do _acc(enemy, k, v) end end
  end

  local list = c.effects or c.Effects
  if type(list) == "table" then
    for _, it in ipairs(list) do
      if type(it) == "table" then
        local tgt  = (it.target or it.to or it.side or "hero"):lower()
        local kind = it.kind or it.type or it.action or it.name
        local val  = it.value or it.val or it.amount or it.n
        if tgt == "hero" then _acc(hero, kind, val) else _acc(enemy, kind, val) end
      end
    end
  end
  return { hero = hero, enemy = enemy }
end

local function applyGeneric(heroActor, enemyActor, eff)
  local h, e = eff.hero or {}, eff.enemy or {}
  if e.heal and e.heal > 0 then pcall(function() heal.give(nil, enemyActor, e.heal) end) end
  if e.shield and e.shield > 0 then pcall(function() shield.applique(nil, enemyActor, e.shield) end) end
  if e.epine and e.epine > 0 then pcall(function() epine.applique(nil, enemyActor, e.epine) end) end
  if h.attack and h.attack > 0 then pcall(function() attack.applique(nil, enemyActor, heroActor, h.attack) end) end
  if h.skip and h.skip > 0 then pcall(function() actorMgr.applyEffect(heroActor, "skip", h.skip) end) end
end

-- ---------- CHOIX ----------
local function cardType(c)
  local eff = getEffects(c)
  local h, e = eff.hero or {}, eff.enemy or {}
  if (e.heal and e.heal > 0) then return "heal" end
  if (e.shield and e.shield > 0) or (e.epine and e.epine > 0) then return "shield" end
  if (h.attack and h.attack > 0) then return "attack" end
  if (h.skip and h.skip > 0) then return "control" end
  return "other"
end

local function chooseDeterministic(deck, powerNow)
  if not deck or #deck == 0 then return nil, nil end
  Hero             = Hero or rawget(_G, "Hero")
  Enemies          = Enemies or rawget(_G, "Enemies")
  local heroActor  = Hero and Hero.actor
  local enemyActor = Enemies and Enemies.curentEnemy

  logf("[AI] status  enemy: %s", tstr(snap(enemyActor)))
  logf("[AI] status  hero : %s", tstr(snap(heroActor)))

  local playable = {}
  for i, c in ipairs(deck) do
    local cost = tonumber(c.cost or c.PowerBlow or c.power or 1) or 1
    if cost <= (enemyActor and (enemyActor.state and enemyActor.state.power or 0) or 0) then
      local t   = cardType(c)
      local eff = getEffects(c)
      logf("[AI] card[%d]: name=%s type=%s cost=%d  eff.hero=%s eff.enemy=%s",
        i, tostring(c.name), t, cost, tstr(eff.hero), tstr(eff.enemy))
      playable[#playable + 1] = { i = i, c = c, t = t }
    else
      logf("[AI] card[%d] INJOUABLE (cost=%d): %s", i, cost, tostring(c.name))
    end
  end
  if #playable == 0 then
    log("[AI] aucune carte jouable → fin de tour")
    return nil, nil
  end

  local g = { heal = {}, shield = {}, attack = {}, control = {}, other = {} }
  for _, it in ipairs(playable) do g[it.t][#g[it.t] + 1] = it end

  local eHP = lifeRatio(enemyActor)
  local hHP = lifeRatio(heroActor)
  local eSH = getShield(enemyActor)

  if eHP <= 0.35 and #g.heal > 0 then
    log("[AI] priorité: HEAL"); return g.heal[1].i, g.heal[1].c
  end
  if eSH <= 2 and #g.shield > 0 then
    log("[AI] priorité: SHIELD"); return g.shield[1].i, g.shield[1].c
  end
  if hHP <= 0.40 and #g.attack > 0 then
    log("[AI] priorité: ATTACK"); return g.attack[1].i, g.attack[1].c
  end

  if #g.attack > 0 then
    log("[AI] défaut -> ATTACK"); return g.attack[1].i, g.attack[1].c
  end
  if #g.shield > 0 then
    log("[AI] défaut -> SHIELD"); return g.shield[1].i, g.shield[1].c
  end
  if #g.heal > 0 then
    log("[AI] défaut -> HEAL"); return g.heal[1].i, g.heal[1].c
  end
  if #g.control > 0 then
    log("[AI] défaut -> CONTROL"); return g.control[1].i, g.control[1].c
  end
  if #g.other > 0 then
    log("[AI] défaut -> OTHER"); return g.other[1].i, g.other[1].c
  end
  return nil, nil
end

-- ---------- APPELS AU PIPELINE CARD.* ----------
local function callCardSystem(c, enemyActor, heroActor)
  Card = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not Card then
    log("[AI] CARD-SYS: Card=nil -> impossible d’afficher/jouer via UI")
    return false, "no_card_module"
  end

  local beforeE, beforeH = snap(enemyActor), snap(heroActor)
  local okAny, tagName = false, ""

  local tries = {
    { "Card.tryPlay(card,'Enemy',true)",            Card.tryPlay,                             c, "Enemy",                       true },
    { "Card.tryPlay(card,{tag='Enemy',free=true})", Card.tryPlay,                             c, { tag = "Enemy", free = true } },
    { "Card.play(card,'Enemy',true)",               Card.play,                                c, "Enemy",                       true },
    { "Card.playEnemy(card)",                       Card.playEnemy,                           c },
    { "Card.playIA(card)",                          Card.playIA,                              c },
    { "Card.aiPlay(card)",                          Card.aiPlay,                              c },
    { "Card.revealEnemyCard(card)",                 Card.revealEnemyCard or Card.revealEnemy, c }, -- visuel-only fallback
  }

  for _, t in ipairs(tries) do
    local label, fn = t[1], t[2]
    if type(fn) == "function" then
      logf("[AI] CARD-SYS TRY -> %s", label)
      local ok = pcall(fn, t[3], t[4], t[5])
      local afterE, afterH = snap(enemyActor), snap(heroActor)
      if ok then
        logf("[AI] CARD-SYS OK  -> %s | enemy %s | hero %s", label, delta(beforeE, afterE), delta(beforeH, afterH))
        okAny, tagName = true, label
        break
      else
        logf("[AI] CARD-SYS FAIL-> %s", label)
      end
    end
  end

  if not okAny then
    log("[AI] CARD-SYS: aucune API ne fonctionne (on passera par onPlay/fallback)")
    return false, "no_card_api"
  end

  return true, tagName
end

-- ---------- onPlay (cartes scriptées) ----------
local function runOnPlay(c, enemyActor, heroActor)
  if type(c) ~= "table" or type(c.onPlay) ~= "function" then return false end

  logf("[AI] onPlay détecté sur '%s' -> essais de signatures…", tostring(c.name))

  -- 1) c:onPlay(enemy, hero)
  if safecall("onPlay(self,enemy,hero)", function() return c:onPlay(enemyActor, heroActor) end) then
    log("[AI] onPlay OK: self,enemy,hero")
    return true
  end
  -- 2) c:onPlay({ctx})
  if safecall("onPlay({ctx})", function()
        return c:onPlay({
          self = c,
          source = enemyActor,
          enemy = enemyActor,
          target = heroActor,
          hero = heroActor,
          actorManager = actorMgr,
          Card = Card,
          who = "Enemy"
        })
      end) then
    log("[AI] onPlay OK: ctx-table")
    return true
  end
  -- 3) c:onPlay(enemy)
  if safecall("onPlay(enemy)", function() return c:onPlay(enemyActor) end) then
    log("[AI] onPlay OK: enemy-only")
    return true
  end
  -- 4) onPlay(c, enemy, hero)
  if safecall("onPlay(c,enemy,hero)", function() return c.onPlay(c, enemyActor, heroActor) end) then
    log("[AI] onPlay OK: plain(c,enemy,hero)")
    return true
  end

  log("[AI] onPlay présent mais aucune signature n’a abouti.")
  return false
end

-- ---------- APPLICATION ----------
local function applyCard(c)
  if not c then return end
  Hero             = Hero or rawget(_G, "Hero")
  Enemies          = Enemies or rawget(_G, "Enemies")

  local enemyActor = Enemies and Enemies.curentEnemy
  local heroActor  = Hero and Hero.actor

  local cost       = tonumber(c.cost or c.PowerBlow or c.power or 1) or 1
  local eff        = getEffects(c)
  logf("[AI] applyCard '%s' cost=%d eff.hero=%s eff.enemy=%s", tostring(c.name), cost, tstr(eff.hero), tstr(eff.enemy))

  -- état avant
  local bE, bH = snap(enemyActor), snap(heroActor)

  -- 1) Tenter le pipeline officiel des cartes (affichage + logique interne)
  local okCardSys, labelUsed = callCardSystem(c, enemyActor, heroActor)

  -- 2) Vérifier s’il y a eu un vrai effet
  local mE, mH = snap(enemyActor), snap(heroActor)
  local changed = (mE.life ~= bE.life or mE.sh ~= bE.sh or mE.ep ~= bE.ep
    or mH.life ~= bH.life or mH.sh ~= bH.sh or mH.ep ~= bH.ep)

  -- 3) Si rien n’a bougé, essayer onPlay (même si Card.* a “réussi”)
  local usedOnPlay = false
  if not changed then
    usedOnPlay = runOnPlay(c, enemyActor, heroActor)
    mE, mH = snap(enemyActor), snap(heroActor)
    changed = (mE.life ~= bE.life or mE.sh ~= bE.sh or mE.ep ~= bE.ep
      or mH.life ~= bH.life or mH.sh ~= bH.sh or mH.ep ~= bH.ep)
  end

  -- 4) Si toujours rien, appliquer le fallback générique à partir des champs
  if not changed then
    log("[AI] aucun effet visuel/script → fallback générique")
    applyGeneric(heroActor, enemyActor, eff)
  end

  -- 5) Logs de diff
  local aE, aH = snap(enemyActor), snap(heroActor)
  logf("[AI] enemy  %s", delta(bE, aE))
  logf("[AI] hero   %s", delta(bH, aH))

  if bE.life == aE.life and bE.sh == aE.sh and bE.ep == aE.ep
      and bH.life == aH.life and bH.sh == aH.sh and bH.ep == aH.ep then
    local keys = {}
    for k, _ in pairs(c) do keys[#keys + 1] = tostring(k) end
    table.sort(keys)
    logf("[AI][WARN] aucun changement d'état après '%s'. keys={%s}", tostring(c.name), table.concat(keys, ", "))
    if c.effect or c.Effect then logf("[AI]  effect=%s", tstr(c.effect or c.Effect, 1)) end
    if c.effects or c.Effects then logf("[AI]  effects(list)=%s", tstr(c.effects or c.Effects, 1)) end
    if type(c.onPlay) == "function" then
      if usedOnPlay then
        log("[AI]  onPlay: <function> (appelé, mais pas d'effet)")
      else
        log("[AI]  onPlay: <function> (non appelé)")
      end
    end
    if okCardSys then logf("[AI]  NOTE: pipeline utilisé -> %s (mais aucun delta d’état détecté)", tostring(labelUsed)) end
  end
end

-- ---------- API ----------
function AI.load()
  ensureAIContainers()
  AI.state, AI.timer, AI.currentIndex, AI.currentCard, AI.lastPlayed =
      "idle", 0, nil, nil, nil
  AI.busy, AI.running, AI._endSent, AI.enemy, AI._badDtWarned =
      false, false, false, nil, false
  _autoWireTelegraph() -- auto-câblage visuel si dispo
  print("[AI] Contrôleur simple chargé")
end

function AI:startTurn(enemy)
  self.enemy        = enemy
  self.state        = "choose"
  self.timer        = 0
  self.currentIndex = nil
  self.currentCard  = nil
  self._endSent     = false
  self.busy         = true
  self.running      = true
  _notify("onTurnStart", enemy)
  logf("[AI] startTurn (power=%s)", tostring(enemy and enemy.state and enemy.state.power))
end

function AI:isTurnDone() return self._endSent == true end

function AI:update(dt)
  dt = normDt(dt)
  Enemies = Enemies or rawget(_G, "Enemies")
  local e = Enemies and Enemies.curentEnemy

  if type(e) ~= "table" or type(e.state) ~= "table" then
    if not self._endSent and Transition and Transition.requestEndTurn then
      print("[AI] pas d'ennemi valide → fin de tour")
      Transition.requestEndTurn()
      self._endSent = true
    end
    self.busy, self.running = false, false
    self.state, self.timer  = "idle", 0
    return
  end

  Transition = Transition or rawget(_G, "Transition")
  if Transition and (Transition.state == "victory_check" or Transition.state == "reward_choice"
        or Transition.state == "advance_enemy" or Transition.state == "game_over") then
    AI.listener.clear();
    return
  end

  if _G.Tour ~= "Enemy" then
    if self.state ~= "idle" then
      logf("[AI] Tour='%s' → reset état interne", tostring(_G.Tour))
      self.state, self.timer, self.currentIndex, self.currentCard = "idle", 0, nil, nil
    end
    return
  end

  if self.state == "idle" then
    self.state   = "choose"
    self.busy    = true
    self.running = true
  elseif self.state == "choose" then
    local deck = ensureAIContainers()
    if not deck or #deck == 0 then
      if not self._endSent then
        log("[AI] deck IA vide → fin de tour")
        -- Marque et envoie immédiatement la demande de fin de tour au Transition Manager
        self._endSent = true
        if Transition and Transition.requestEndTurn then
          log("[AI->Transition] demande fin de tour (deck vide)")
          pcall(function() Transition.requestEndTurn() end)
        else
          log("[AI->Transition] Transition non disponible pour requestEndTurn()")
        end
        -- On passe en attente : Transition doit basculer le tour
        self.state = "waiting_end"
      else
        -- on a déjà demandé la fin de tour : attendre le Transition
        self.state = "waiting_end"
      end
      return
    end

    local powerNow = tonumber(e.state.power or 0) or 0
    local idx, c = chooseDeterministic(deck, powerNow)
    if not idx or not c then
      self.state = "endturn"
      return
    end

    -- éviter de jouer 2x la même carte quand il y a d'autres options
    if self.lastPlayed and c.name == self.lastPlayed and #deck > 1 then
      for i, cc in ipairs(deck) do
        local cost = tonumber(cc.cost or cc.PowerBlow or cc.power or 1) or 1
        if i ~= idx and cost <= powerNow and cc.name ~= self.lastPlayed then
          idx, c = i, cc; break
        end
      end
    end

    self.currentIndex, self.currentCard = idx, c
    logf("[AI] choose -> %s", tostring(c.name))
    _notify("onCardChosen", c, idx, powerNow, { enemy = e, card = c })
    self.timer = self.telegraphMin

    -- Si on a un listener ou si on peut afficher, on passe en télégraphe, sinon on résout direct
    if (AI.telegraphMin or 0) > 0 then
      -- tenter un visuel immédiat (listener OU Card.*)
      _notify("onTelegraphStart", c)
      if AI.listener ~= nil then showCardVisual(c) end
      self.state = "telegraph"
    else
      self.state = "resolve"
    end
  elseif self.state == "telegraph" then
    self.timer = (self.timer or 0) - dt
    if self.timer <= 0 then self.state = "resolve" end
  elseif self.state == "resolve" then
    local c, idx = self.currentCard, self.currentIndex
    if c then
      logf("[AI] resolve -> %s", tostring(c.name))
      _notify("onResolveStart", c)

      -- Tenter de jouer/appliquer la carte
      applyCard(c)

      _notify("onResolveDone", c)

      -- Gestion du coût (si on a passé free=true au pipeline)
      -- → On déduit toujours ici pour éviter double-décompte aléatoire.
      local cost = tonumber(c.cost or c.PowerBlow or c.power or 1) or 1
      local bE = snap(e)
      e.state.power = math.max(0, (e.state.power or 0) - cost)
      local aE = snap(e)
      logf("[AI] POWER after cost %d -> %s", cost, delta(bE, aE))

      -- Retrait de la carte du deck IA si elle y est encore
      local deck = ensureAIContainers()
      if deck and idx and deck[idx] == c then
        --[[ table.remove(deck, idx) ]]

        --TODO : Ajouter une verification quil joue pas de fois la même carte

        logf("[AI] deckAi remove '%s' (index=%d) -> reste=%d", tostring(c.name), idx, #deck)
      else
        logf("[AI] deckAi: carte '%s' déjà retirée par le système de cartes ?", tostring(c.name))
      end

      self.lastPlayed = c.name
    end
    self.currentIndex, self.currentCard = nil, nil
    self.state = "endturn"
  elseif self.state == "endturn" then
    if not self._endSent then
      self._endSent = true
      log("[AI] fin de tour -> Transition.requestEndTurn()")
      if Transition and Transition.requestEndTurn then Transition.requestEndTurn() end
      _notify("onTurnEnd")
      -- Évite le spam : on attend que Transition bascule le tour
      self.state = "waiting_end"
      self.busy, self.running = false, false
    end
  elseif self.state == "waiting_end" then
    -- On ne fait rien : on attend que _G.Tour change (voir le début de update)
    return
  end
end

function AI.draw()
  if not AI.listener or not AI.listener.draw then
    log("[AI] draw: pas de listener ou draw non implémenté")
    return
  else
    AI.listener:draw()
  end
  drawTourCh(_G.Tour, _G.deltaTime) -- Annonce les changements de tour
  -- indicateurs visuels éventuels (si tu veux des overlays de debug)
end

return AI
