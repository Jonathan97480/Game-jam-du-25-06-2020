-- my-librairie/ai/controller.lua
-- IA : logique de jeu des cartes (pipeline Card.* + fallback) + auto-câblage du télégraphe (visuel optionnel)

-- Chargement sécurisé pour éviter les boucles circulaires
local function _safeRequire(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

local actorMgr                = _G.actorManager or _safeRequire("my-librairie/managers/actorManager")
local Card                    = _G.Card or rawget(_G, "Card") or rawget(_G, "card")
local Hero                    = _G.Hero or rawget(_G, "Hero")
local EnemiesManager          = _G.Enemies or rawget(_G, "Enemies")
local globalFunction          = _G.globalFunction or rawget(_G, 'globalFunction')

-- Nouveau : Module de stratégie de sélection de cartes et ciblage
local CardSelectionStrategy   = _safeRequire("my-librairie/ai/card_selection_strategy")

local TransitionCombat        = _G.TransitionCombat or _safeRequire("my-librairie/transitions/templateCombatTransition")

local timerMaxTurnChanged     = 1
local timerDrawTurned         = 0
local lastTurnTransitionState = ''
local currentEnemy            = {}

local AI                      = {
  state               = "idle",
  timer               = 0,
  telegraphMin        = 0.3,

  currentIndex        = nil,
  currentCard         = nil,
  lastPlayed          = nil,

  -- NOUVEAU : Système de limite de jeu par tour
  maxPlaysPerTurn     = 1,  -- Nombre maximum de cartes par tour (configurable)
  playsThisTurn       = 0,  -- Compteur des cartes jouées ce tour
  chainCards          = {}, -- File des cartes en chaîne à jouer
  chainTimer          = 0,  -- Timer pour gérer les délais entre cartes
  deckSnapshot        = {}, -- Snapshot du deck avant de jouer une carte

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


local function logf(fmt, ...)
  if AI.DEBUG then
    if globalFunction == nil then
      globalFunction = rawget(_G, 'globalFunction') or
          require("my-librairie.utils.globalFunction")
    end
    local args = { ... }
    local message
    if #args > 0 then
      message = string.format(fmt, ...)
    else
      message = fmt
    end
    if globalFunction and globalFunction.log and globalFunction.log.info then
      globalFunction.log.info(message)
    else
      print(message)
    end
  end
end



-- ---------- VISUEL / LISTENER ----------
function AI.setListener(l)
  AI.listener = l
end

function AI.setConfig(opts)
  if type(opts) ~= "table" then return end
  if opts.telegraphMin ~= nil then AI.telegraphMin = tonumber(opts.telegraphMin) or AI.telegraphMin end

  -- NOUVEAU : Configuration du système de limite de jeu
  if opts.maxPlaysPerTurn ~= nil then
    AI.maxPlaysPerTurn = math.max(1, tonumber(opts.maxPlaysPerTurn) or AI.maxPlaysPerTurn)
    logf("[AI] Configuration: maxPlaysPerTurn = %d", AI.maxPlaysPerTurn)
  end
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
    logf("[AI] Telegraph auto-câblé depuis le contrôleur.")
  else
    logf("[AI] Telegraph indisponible (require a échoué) : visuel désactivé.")
  end
end

-- ---------- GESTION CARTES EN CHAÎNE ----------
-- Détecte les nouvelles cartes ajoutées au deck après avoir joué une carte
local function detectNewCardsInDeck(deckBefore, deckAfter)
  local newCards = {}

  -- Vérification de sécurité : les deux decks doivent exister
  if not deckBefore or not deckAfter then
    logf("[AI] Deck invalide: deckBefore=%s, deckAfter=%s",
      deckBefore and "présent" or "nil",
      deckAfter and "présent" or "nil")
    return newCards
  end

  -- Comparer les decks pour détecter les nouvelles cartes
  if #deckAfter > #deckBefore then
    logf("[AI] Deck agrandi: %d → %d cartes", #deckBefore, #deckAfter)

    -- Les nouvelles cartes sont généralement ajoutées à la fin
    for i = #deckBefore + 1, #deckAfter do
      if deckAfter[i] then
        table.insert(newCards, deckAfter[i])
        logf("[AI] Nouvelle carte détectée: '%s'", deckAfter[i].name or "?")
      end
    end
  end

  return newCards
end

-- Capture l'état du deck avant de jouer une carte
local function captureDecKState()
  if not (Card and Card.deckAi and Card.deckAi.cards) then
    return {}
  end

  -- Crée une copie de la liste des cartes (références, pas deep copy)
  local snapshot = {}
  for i, card in ipairs(Card.deckAi.cards) do
    snapshot[i] = card
  end

  logf("[AI] Deck snapshot: %d cartes", #snapshot)
  return snapshot
end

-- Ajoute des cartes à la file des cartes en chaîne avec délai
local function addChainCardsWithDelay(cards)
  for _, card in ipairs(cards) do
    table.insert(AI.chainCards, {
      card = card,
      delay = 1.0, -- 1 seconde de délai entre chaque carte
      timer = 0    -- Timer pour gérer le délai
    })
    logf("[AI] Carte ajoutée à la chaîne (délai 1s): '%s'", card.name or "?")
  end
end



-- Réinitialise le compteur pour un nouveau tour
local function resetTurnCounter()
  AI.playsThisTurn = 0
  AI.chainCards = {}
  AI.chainTimer = 0 -- Timer pour gérer les délais entre cartes
  logf("[AI] Compteur de tour réinitialisé (max: %d cartes)", AI.maxPlaysPerTurn)
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
local function ensureAIContainers(enemy)
  Card = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not Card then return nil end
  Card.deckAi = nil
  Card.deckAi = Card.getDeckByName(enemy.nameDeck)
  return Card.deckAi.cards
end

-- ============================================================================
-- DÉLÉGATION VERS LE MODULE DE STRATÉGIE
-- ============================================================================

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
  if h.skip and h.skip > 0 and actorMgr then pcall(function() actorMgr.applyEffect(heroActor, "skip", h.skip) end) end
end

-- ---------- CHOIX ----------
--[[ local function cardType(c)
  local eff = getEffects(c)
  local h, e = eff.hero or {}, eff.enemy or {}
  if (e.heal and e.heal > 0) then return "heal" end
  if (e.shield and e.shield > 0) or (e.epine and e.epine > 0) then return "shield" end
  if (h.attack and h.attack > 0) then return "attack" end
  if (h.skip and h.skip > 0) then return "control" end
  return "other"
end ]]

local function chooseDeterministic(deck, playsRemaining)
  -- Délégation vers le module de stratégie de sélection
  if CardSelectionStrategy and CardSelectionStrategy.chooseDeterministic then
    return CardSelectionStrategy.chooseDeterministic(deck, playsRemaining)
  end

  -- Fallback simple si le module n'est pas disponible
  if not deck or #deck == 0 then return nil, nil end
  if playsRemaining <= 0 then return nil, nil end

  logf("[AI] FALLBACK: sélection première carte disponible")
  return 1, deck[1]
end

-- ---------- CIBLAGE INTELLIGENT (DÉLÉGUÉ) ----------
local function selectTargetForCard(card, sourceEnemy, heroActor)
  -- Délégation vers le module de stratégie
  if CardSelectionStrategy and CardSelectionStrategy.selectTargetForCard then
    return CardSelectionStrategy.selectTargetForCard(card, sourceEnemy, heroActor)
  end

  -- Fallback simple
  logf("[AI] FALLBACK: ciblage par défaut → soi-même")
  return sourceEnemy
end

-- ---------- APPELS AU PIPELINE CARD.* MODERNISÉ ----------
local function modernCardSystem(c, enemyActor, heroActor)
  Card = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not Card then
    logf("[AI] MODERN-SYS: Card=nil -> impossible de jouer")
    return false, "no_card_module"
  end

  -- Sélection intelligente de la cible
  local targetActor = selectTargetForCard(c, enemyActor, heroActor)

  local beforeE, beforeH = snap(enemyActor), snap(heroActor)
  local beforeT = targetActor and snap(targetActor) or nil

  -- Tentative API moderne unifiée
  if Card.tryPlay and type(Card.tryPlay) == "function" then
    logf("[AI] MODERN-SYS: tentative Card.tryPlay moderne")

    -- Configuration de la carte pour l'ennemi
    local originalActorTag = c.actorTag
    c.actorTag = "Enemy" -- Force le tag ennemi pour cette carte

    local ok = pcall(function()
      return Card.tryPlay(c, false) -- false = coût normal
    end)

    -- Restauration du tag original
    c.actorTag = originalActorTag

    if ok then
      local afterE, afterH = snap(enemyActor), snap(heroActor)
      local afterT = targetActor and snap(targetActor) or nil
      logf("[AI] MODERN-SYS OK: Card.tryPlay | enemy %s | hero %s | target %s",
        delta(beforeE, afterE), delta(beforeH, afterH),
        afterT and delta(beforeT, afterT) or "N/A")
      return true, "Card.tryPlay"
    else
      logf("[AI] MODERN-SYS FAIL: Card.tryPlay")
    end
  end

  -- Fallback vers Common.playCard si disponible
  local Common = rawget(_G, "Common") or (Card and Card.Common)
  if Common and Common.playCard and type(Common.playCard) == "function" then
    logf("[AI] MODERN-SYS: tentative Common.playCard fallback")
    local ok = pcall(Common.playCard, c, enemyActor, targetActor or heroActor)
    if ok then
      local afterE, afterH = snap(enemyActor), snap(heroActor)
      local afterT = targetActor and snap(targetActor) or nil
      logf("[AI] MODERN-SYS OK: Common.playCard | enemy %s | hero %s | target %s",
        delta(beforeE, afterE), delta(beforeH, afterH),
        afterT and delta(beforeT, afterT) or "N/A")
      return true, "Common.playCard"
    else
      logf("[AI] MODERN-SYS FAIL: Common.playCard")
    end
  end

  logf("[AI] MODERN-SYS: aucune API moderne disponible → fallback legacy")
  return false, "no_modern_api"
end

-- Legacy system (conservé comme fallback ultime)
local function callCardSystemLegacy(c, enemyActor, heroActor)
  Card = Card or rawget(_G, "Card") or rawget(_G, "card")
  if not Card then
    logf("[AI] CARD-SYS: Card=nil -> impossible d’afficher/jouer via UI")
    return false, "no_card_module"
  end

  local beforeE, beforeH = snap(enemyActor), snap(heroActor)
  local okAny, tagName = false, ""

  -- Tentatives legacy réduites (seulement les APIs qui existent vraiment)
  local tries = {
    { "Card.tryPlay(card,'Enemy',true)",            Card.tryPlay,                             c, "Enemy",                       true },
    { "Card.tryPlay(card,{tag='Enemy',free=true})", Card.tryPlay,                             c, { tag = "Enemy", free = true } },
    { "Card.revealEnemyCard(card)",                 Card.revealEnemyCard or Card.revealEnemy, c }, -- visuel-only fallback
  }

  for _, t in ipairs(tries) do
    local label, fn = t[1], t[2]
    if type(fn) == "function" then
      logf("[AI] LEGACY-SYS TRY -> %s", label)
      local ok = pcall(fn, t[3], t[4], t[5])
      local afterE, afterH = snap(enemyActor), snap(heroActor)
      if ok then
        logf("[AI] LEGACY-SYS OK  -> %s | enemy %s | hero %s", label, delta(beforeE, afterE), delta(beforeH, afterH))
        okAny, tagName = true, label
        break
      else
        logf("[AI] LEGACY-SYS FAIL-> %s", label)
      end
    end
  end

  if not okAny then
    logf("[AI] LEGACY-SYS: aucune API legacy ne fonctionne")
    return false, "no_legacy_api"
  end

  return true, tagName
end

-- Fonction unifiée qui essaie modern puis legacy
local function callCardSystem(c, enemyActor, heroActor)
  -- 1. Tentative moderne en priorité
  local okModern, labelModern = modernCardSystem(c, enemyActor, heroActor)
  if okModern then
    return true, labelModern
  end

  -- 2. Fallback vers système legacy
  logf("[AI] SYSTEM: API moderne échouée → tentative legacy")
  local okLegacy, labelLegacy = callCardSystemLegacy(c, enemyActor, heroActor)
  return okLegacy, labelLegacy
end

-- ---------- onPlay (cartes scriptées) ----------
local function runOnPlay(c, enemyActor, heroActor)
  if type(c) ~= "table" or type(c.onPlay) ~= "function" then return false end

  logf("[AI] onPlay détecté sur '%s' -> essais de signatures…", tostring(c.name))

  -- 1) c:onPlay(enemy, hero)
  if globalFunction.safecall("onPlay(self,enemy,hero)", function() return c:onPlay(enemyActor, heroActor) end) then
    logf("[AI] onPlay OK: self,enemy,hero")
    return true
  end
  -- 2) c:onPlay({ctx})
  if globalFunction.safecall("onPlay({ctx})", function()
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
    logf("[AI] onPlay OK: ctx-table")
    return true
  end
  -- 3) c:onPlay(enemy)
  if globalFunction.safecall("onPlay(enemy)", function() return c:onPlay(enemyActor) end) then
    logf("[AI] onPlay OK: enemy-only")
    return true
  end
  -- 4) onPlay(c, enemy, hero)
  if globalFunction.safecall("onPlay(c,enemy,hero)", function() return c.onPlay(c, enemyActor, heroActor) end) then
    logf("[AI] onPlay OK: plain(c,enemy,hero)")
    return true
  end

  logf("[AI] onPlay présent mais aucune signature n’a abouti.")
  return false
end

-- ---------- APPLICATION ----------
local function applyCard(c)
  if not c then return end
  Hero             = Hero or rawget(_G, "Hero")
  EnemiesManager   = EnemiesManager or rawget(_G, "EnemiesManager")

  local enemyActor = currentEnemy
  local heroActor  = Hero and Hero.actor

  local eff        = getEffects(c)

  logf("[AI] applyCard '%s' eff.hero=%s eff.enemy=%s", tostring(c.name), globalFunction.tstr(eff.hero),
    globalFunction.tstr(eff.enemy))

  -- état avant
  local bE, bH = snap(enemyActor), snap(heroActor)

  -- Capturer l'état du deck avant de jouer la carte
  local deckBefore = captureDecKState()

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
    logf("[AI] aucun effet visuel/script → fallback générique")
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
    if c.effect or c.Effect then logf("[AI]  effect=%s", globalFunction.tstr(c.effect or c.Effect)) end
    if c.effects or c.Effects then logf("[AI]  effects(list)=%s", globalFunction.tstr(c.effects or c.Effects)) end
    if type(c.onPlay) == "function" then
      if usedOnPlay then
        logf("[AI]  onPlay: <function> (appelé, mais pas d'effet)")
      else
        logf("[AI]  onPlay: <function> (non appelé)")
      end
    end
    if okCardSys then logf("[AI]  NOTE: pipeline utilisé -> %s (mais aucun delta d’état détecté)", tostring(labelUsed)) end
  end
end

-- Détecter les nouvelles cartes ajoutées au deck après avoir joué cette carte
local function handleChainCards(cardPlayed, deckBefore)
  if not deckBefore then return end

  -- Obtenir le deck actuel après avoir joué la carte
  local deckAfter = (Card and Card.deckAi and Card.deckAi.cards) or nil

  local newCards = detectNewCardsInDeck(deckBefore, deckAfter)
  if #newCards > 0 then
    logf("[AI] Cartes ajoutées au deck après avoir joué '%s': %d cartes", tostring(cardPlayed.name), #newCards)
    addChainCardsWithDelay(newCards)
  end
end

-- ---------- API ----------
function AI.load(_enemy)
  ensureAIContainers(_enemy)
  currentEnemy = _enemy
  AI.state, AI.timer, AI.currentIndex, AI.currentCard, AI.lastPlayed =
      "idle", 0, nil, nil, nil
  AI.busy, AI.running, AI._endSent, AI.enemy, AI._badDtWarned =
      false, false, false, nil, false
  _autoWireTelegraph() -- auto-câblage visuel si dispo
  logf("[AI] Contrôleur simple chargé")
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

  -- NOUVEAU : Réinitialisation du système de compteur de tour
  resetTurnCounter()

  _notify("onTurnStart", enemy)
  ensureAIContainers(enemy)
  logf("[AI] startTurn - limite: %d cartes par tour", AI.maxPlaysPerTurn)
end

function AI:isTurnDone() return self._endSent == true end

function AI:update(dt)
  dt = normDt(dt)
  EnemiesManager = EnemiesManager or rawget(_G, "EnemiesManager")
  local e = currentEnemy

  -- Gestion du timer pour les cartes en chaîne
  if AI.chainTimer > 0 then
    AI.chainTimer = AI.chainTimer - dt
    if AI.chainTimer <= 0 and #AI.chainCards > 0 and AI.playsThisTurn < AI.maxPlaysPerTurn then
      -- Timer écoulé, jouer la prochaine carte en chaîne
      local nextChainCard = table.remove(AI.chainCards, 1)
      logf("[AI] Timer écoulé, jouer carte en chaîne: '%s'", nextChainCard.name or "?")

      -- Rechercher l'index de la carte en chaîne dans le deck
      for i, deckCard in ipairs(Card.deckAi.cards) do
        if deckCard == nextChainCard then
          self.currentIndex, self.currentCard = i, deckCard
          self.state = "resolve" -- Jouer immédiatement la carte en chaîne
          AI.chainTimer = 0      -- Reset timer
          logf("[AI] Jouer carte en chaîne immédiatement: index=%d", i)
          break
        end
      end
    end
  end

  if type(e) ~= "table" or type(e.state) ~= "table" then
    if not self._endSent and TransitionCombat and TransitionCombat.requestEndTurn then
      logf("[AI] pas d'ennemi valide → fin de tour")
      TransitionCombat.requestEndTurn()
      self._endSent = true
    end
    self.busy, self.running = false, false
    self.state, self.timer  = "idle", 0
    return
  end

  TransitionCombat = TransitionCombat or rawget(_G, "TransitionCombat")
  if TransitionCombat and (TransitionCombat.state == "victory_check" or TransitionCombat.state == "reward_choice"
        or TransitionCombat.state == "advance_enemy" or TransitionCombat.state == "game_over") then
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
    if not Card or #Card.deckAi.cards == 0 then
      if not self._endSent then
        logf("[AI] deck IA vide → fin de tour")
        -- Marque et envoie immédiatement la demande de fin de tour au Transition Manager
        self._endSent = true
        if TransitionCombat and TransitionCombat.requestEndTurn then
          logf("[AI->Transition] demande fin de tour (deck vide)")
          pcall(function() TransitionCombat.requestEndTurn() end)
        else
          logf("[AI->Transition] Transition non disponible pour requestEndTurn()")
        end
        -- On passe en attente : Transition doit basculer le tour
        self.state = "waiting_end"
      else
        -- on a déjà demandé la fin de tour : attendre le Transition
        self.state = "waiting_end"
      end
      return
    end

    local playsRemaining = AI.maxPlaysPerTurn - AI.playsThisTurn
    local idx, c = chooseDeterministic(Card.deckAi.cards, playsRemaining)
    if not idx or not c then
      self.state = "endturn"
      return
    end

    -- éviter de jouer 2x la même carte quand il y a d'autres options
    if self.lastPlayed and c.name == self.lastPlayed and #Card.deckAi.cards > 1 then
      for i, cc in ipairs(Card.deckAi.cards) do
        if i ~= idx and cc.name ~= self.lastPlayed then
          idx, c = i, cc; break
        end
      end
    end

    self.currentIndex, self.currentCard = idx, c
    logf("[AI] choose -> %s (plays: %d/%d)", tostring(c.name), AI.playsThisTurn + 1, AI.maxPlaysPerTurn)
    _notify("onCardChosen", c, idx, playsRemaining, { enemy = e, card = c })
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

      -- Capturer l'état du deck avant de jouer la carte
      local deckBefore = captureDecKState()

      -- Tenter de jouer/appliquer la carte
      applyCard(c)

      _notify("onResolveDone", c)

      -- NOUVEAU : Gestion des cartes en chaîne et compteur de tour
      AI.playsThisTurn = AI.playsThisTurn + 1
      logf("[AI] Carte jouée '%s' (%d/%d ce tour)", tostring(c.name), AI.playsThisTurn, AI.maxPlaysPerTurn)

      -- Détection et ajout des nouvelles cartes ajoutées au deck
      handleChainCards(c, deckBefore)

      -- Retrait de la carte du deck IA si elle y est encore
      --[[  local deck = ensureAIContainers() ]]
      if deck and idx and deck[idx] == c then
        --[[ table.remove(deck, idx) ]]

        --TODO : Ajouter une verification quil joue pas de fois la même carte

        logf("[AI] deckAi remove '%s' (index=%d) -> reste=%d", tostring(c.name), idx, #deck)
      else
        logf("[AI] deckAi: carte '%s' déjà retirée par le système de cartes ?", tostring(c.name))
      end

      self.lastPlayed = c.name

      -- Vérifier s'il faut jouer une carte en chaîne immédiatement
      if #AI.chainCards > 0 and AI.playsThisTurn < AI.maxPlaysPerTurn then
        local nextChainCard = table.remove(AI.chainCards, 1)
        logf("[AI] Carte en chaîne à jouer: '%s'", nextChainCard.name or "?")

        -- Rechercher l'index de la carte en chaîne dans le deck
        for i, deckCard in ipairs(Card.deckAi.cards) do
          if deckCard == nextChainCard then
            self.currentIndex, self.currentCard = i, deckCard
            self.state = "telegraph" -- Rester dans le cycle pour jouer la chaîne
            logf("[AI] Préparation carte en chaîne: index=%d", i)
            return
          end
        end
        logf("[AI] WARN: Carte en chaîne '%s' non trouvée dans le deck", nextChainCard.name or "?")
      end
    end
    self.currentIndex, self.currentCard = nil, nil

    -- Vérifier si on peut encore jouer des cartes ce tour
    if AI.playsThisTurn < AI.maxPlaysPerTurn and #Card.deckAi.cards > 0 then
      logf("[AI] Peut encore jouer %d cartes ce tour", AI.maxPlaysPerTurn - AI.playsThisTurn)
      self.state = "choose" -- Retourner au choix de carte
    else
      logf("[AI] Fin de tour: %d cartes jouées (limite: %d)", AI.playsThisTurn, AI.maxPlaysPerTurn)
      self.state = "endturn"
    end
  elseif self.state == "endturn" then
    if not self._endSent then
      self._endSent = true
      logf("[AI] fin de tour -> TransitionCombat.requestEndTurn()")
      if TransitionCombat and TransitionCombat.requestEndTurn then TransitionCombat.requestEndTurn() end
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
  TransitionCombat = TransitionCombat or rawget(_G, "TransitionCombat")
  if TransitionCombat.state == 'overlay_start' or TransitionCombat.state == 'overlay_initiative' then return end

  if (not AI.listener or not AI.listener.draw) then
    logf("[AI] draw: pas de listener ou draw non implémenté")
    return
  else
    AI.listener:draw()
  end
  drawTourCh(_G.Tour, _G.deltaTime) -- Annonce les changements de tour
  -- indicateurs visuels éventuels (si tu veux des overlays de debug)
end

return AI
