local res = require("res")
local gameplay = require("scene.gameplay")
local responsive = require("my-librairie/responsive")
-- optional unified input helper (mouse + joystick)
local _safeRequire = function(name)
  local ok, mod = pcall(require, name)
  if ok then return mod end
  return nil
end
local inputManager = _safeRequire("my-librairie/inputManager")
-- Layered HUD Manager
local hud = {}

-- small logging helpers -> use globalFunction.log if present, fallback to print
local function _to_text(...)
  local t = {}
  for i = 1, select('#', ...) do t[i] = tostring(select(i, ...)) end
  return table.concat(t, ' ')
end
local function _logf(fmt, ...)
  local gf = rawget(_G, 'globalFunction')
  local txt = string.format(fmt, ...)
  if gf and gf.log and gf.log.info then gf.log.info(txt) else print(txt) end
end

-- Debug flags
local HUD_DEBUG_ENERGY = false
-- expose flag for runtime toggle (will be set into hud)
hud.HUD_DEBUG_ENERGY = HUD_DEBUG_ENERGY
-- previous energy snapshot (for change detection)
local _prev_energy_value = nil


-- Layers (draw order: background -> decor -> props -> card -> button)
local LAYERS = { "background", "decor", "props", "card", "button" }
local layer_index = { background = 1, decor = 2, props = 3, card = 4, button = 5 }

-- Registry
local elements = {} -- id -> element
local layers = { background = {}, decor = {}, props = {}, card = {}, button = {} }

-- Theme
hud.theme = { font_size = 20 }


local function fixeSizeFontByResolotionGame(size)
  local scale = responsive.getWindow.height / responsive.gameReso.height
  local fontSize = size * scale
  return fontSize
end

--[[

Fonction : ensureFont

Rôle : Fonction « Ensure font » liée à la logique du jeu.

Paramètres :

  - (aucun)

Retour : aucune valeur (nil).

]]

local function ensureFont()
  love.graphics.setFont(res.font(hud.theme.font_size))
end

--[[

Fonction : pointInRect

Rôle : Fonction « Point in rect » liée à la logique du jeu.

Paramètres :

  - px : paramètre détecté automatiquement.

  - py : paramètre détecté automatiquement.

  - x : paramètre détecté automatiquement.

  - y : paramètre détecté automatiquement.

  - w : paramètre détecté automatiquement.

  - h : paramètre détecté automatiquement.

Retour : valeur calculée.

]]

hud.pointInRect = function(px, py, x, y, w, h)
  if type(px) ~= "number" or type(py) ~= "number" or type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then
    return false
  end
  return px >= x and py >= y and px <= x + w and py <= y + h
end

--[[

Fonction : addToLayer

Rôle : Fonction « Add to layer » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - layer : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

local function addToLayer(id, layer)
  layer = layer or "button"
  if not layers[layer] then layers[layer] = {} end
  table.insert(layers[layer], id)
end

--[[

Fonction : dimsFrom

Rôle : Fonction « Dims from » liée à la logique du jeu.

Paramètres :

  - el : paramètre détecté automatiquement.

Retour : valeur calculée.

]]

local function dimsFrom(el)
  local w = el.w or (el.img and el.img.getWidth and el.img:getWidth()) or 0
  local h = el.h or (el.img and el.img.getHeight and el.img:getHeight()) or 0
  return w, h
end

-- helper: prefer unified inputInterface cursor, then screen.mouse, then love.mouse.getPosition()
local function _getCursor()
  local ok, cur = pcall(require, "my-librairie/cursor")
  if ok and cur and cur.get then return cur.get() end
  return 0, 0
end

-- Public API
--[[
Fonction : hud.addIcon
Rôle : Fonction « Add icon » liée à la logique du jeu.
Paramètres :
  - id : paramètre détecté automatiquement.
  - opts : paramètre détecté automatiquement.
Retour : valeur calculée.
]]
function hud.addIcon(id, opts)
  local el = {
    id = id,
    type = "icon",
    x = opts.x or 0,
    y = opts.y or 0,
    img = opts.img and res.image(opts.img) or nil,
    layer = opts.layer or "props",
    w = opts.w,
    h = opts.h,
    interactive = false,
  }
  elements[id] = el
  addToLayer(id, el.layer)
  return el
end

--[[

Fonction : hud.addLabel

Rôle : Fonction « Add label » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - opts : paramètre détecté automatiquement.

Retour : valeur calculée.

]]

function hud.addLabel(id, opts)
  local el = {
    id = id,
    type = "label",
    x = opts.x or 0,
    y = opts.y or 0,
    text = opts.text or "",
    layer = opts.layer or "props",
    interactive = false,
  }
  elements[id] = el
  addToLayer(id, el.layer)
  return el
end

--[[

Fonction : hud.addBar

Rôle : Fonction « Add bar » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - opts : paramètre détecté automatiquement.

Retour : valeur calculée.

]]

function hud.addBar(id, opts)
  local el = {
    id = id,
    type = "bar",
    x = opts.x or 0,
    y = opts.y or 0,
    w = opts.w or 100,
    h = opts.h or 16,
    current = opts.current or 0,
    max = opts.max or 1,
    color = opts.color,
    border = opts.border,
    bg = opts.bg and res.image(opts.bg) or nil,
    fg = opts.fg and res.image(opts.fg) or nil,
    layer = opts.layer or "props",
    interactive = false,
  }
  elements[id] = el
  addToLayer(id, el.layer)
  return el
end

--[[

Fonction : hud.addButton

Rôle : Fonction « Add button » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - opts : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function hud.addButton(id, opts)
  local el = {
    id = id,
    type = "button",
    x = opts.x or 0,
    y = opts.y or 0,
    img = opts.img and res.image(opts.img) or nil,
    text = opts.text or "",
    tx = opts.tx or (opts.x or 0) + 10,
    ty = opts.ty or (opts.y or 0) + 10,
    onClick = opts.onClick,
    layer = opts.layer or "button",
    w = opts.w,
    h = opts.h,
    sfx = opts.sfx,
    interactive = true,
  }
  if not el.w or not el.h then
    el.w, el.h = dimsFrom(el)
  end
  elements[id] = el
  addToLayer(id, el.layer)
  return el
end

--[[

Fonction : hud.get

Rôle : Retourne une information calculée ou extraite.

Paramètres :

  - id : paramètre détecté automatiquement.

Retour : valeur calculée.

]]

function hud.get(id) return elements[id] end

--[[

Fonction : hud.setText

Rôle : Fonction « Set text » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - text : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function hud.setText(id, text)
  local el = elements[id]
  if el and el.type == "label" then el.text = tostring(text or "") end
end

--[[

Fonction : hud.setBar

Rôle : Fonction « Set bar » liée à la logique du jeu.

Paramètres :

  - id : paramètre détecté automatiquement.

  - cur : paramètre détecté automatiquement.

  - max : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function hud.setBar(id, cur, max)
  local el = elements[id]
  if el and el.type == "bar" then
    el.current = cur or el.current
    el.max = max or el.max
  end
end

-- Bottom bar background helper
--[[
Fonction : hud.setBottomBarBg
Rôle : Fonction « Set bottom bar bg » liée à la logique du jeu.
Paramètres :
  - path : paramètre détecté automatiquement.
  - x : paramètre détecté automatiquement.
  - y : paramètre détecté automatiquement.
  - h : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function hud.setBottomBarBg(path, x, y, h)
  if not elements["bottom_bar_bg"] then
    hud.addIcon("bottom_bar_bg", { img = nil, x = x or 0, y = y or 0, layer = "background" })
  end
  local el = elements["bottom_bar_bg"]
  if type(path) == "string" and path ~= "" then
    local ok, img = pcall(res.image, path)
    if ok and img then
      el.img = img
      el.h   = h or (img.getHeight and img:getHeight()) or el.h or 0
      -- if no explicit y provided, anchor footer to bottom of game resolution
      if (y == nil) then
        local gh = (responsive and responsive.gameReso and responsive.gameReso.height) or nil
        if gh and el.h then
          el.y = gh - el.h
        end
      end
    else
      el.img = nil
      _logf("[HUD] Bottom bar BG not found: %s", tostring(path))
    end
  else
    el.img = nil
  end
  if type(x) == "number" then el.x = x end
  if type(y) == "number" then el.y = y end
  if type(h) == "number" then el.h = h end
end

-- SFX (optional)
local _sfx = { hover = nil, click = nil, dragStart = nil, dragMove = nil, dragEnd = nil }
local _sfx_last = { dragMove = 0 }
local _sfx_rate = { dragMove = 0.05 }
--[[
Fonction : hud.setSfx
Rôle : Fonction « Set sfx » liée à la logique du jeu.
Paramètres :
  - tbl : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function hud.setSfx(tbl) for k, v in pairs(tbl or {}) do _sfx[k] = v end end

--[[
Fonction : play
Rôle : Fonction « Play » liée à la logique du jeu.
Paramètres :
  - name : paramètre détecté automatiquement.
  - custom : paramètre détecté automatiquement.
Retour : valeur calculée.
]]
local function play(name, custom)
  local path = custom or _sfx[name]; if not path then return end
  if name == "dragMove" then
    local t = love.timer.getTime(); if t - (_sfx_last.dragMove or 0) < (_sfx_rate.dragMove or 0.05) then return end
    _sfx_last.dragMove = t
  end
  local ok, src = pcall(res.audio, path, "static"); if ok and src then pcall(function() src:play() end) end
end
--[[
Fonction : hud.sfx
Rôle : Fonction « Sfx » liée à la logique du jeu.
Paramètres :
  - event : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function hud.sfx(event) play(event) end

--[[
Fonction : hud.drag
Rôle : Fonction « Drag » liée à la logique du jeu.
Paramètres :
  - event : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function hud.drag(event)
  if event == "start" then
    play("dragStart")
  elseif event == "move" then
    play("dragMove")
  elseif event == "end" then
    play("dragEnd")
  end
end

-- Load: auto default elements + auto footer
--[[
Fonction : hud.load
Rôle : Initialise les ressources et l'état.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function hud.load()
  -- initialize HUD defaults
  local x, y = _getCursor()
  hud.addButton('end_turn', {
    img = 'img/hud/Button-fin-de-tour.png',
    x = 1283,
    y = 1019,
    layer = 'button',
    text = 'End of Tours',
    tx = 1310,
    ty = 1035,
    --[[ onClick: appel au gameplay ]]
    onClick = function() gameplay.endTurn() end,
  })

  if not hud.get('energy_icon') then
    hud.addIcon('energy_icon', { img = 'img/hud/nombre de coup.png', x = 127, y = 745, layer = 'props' })
    -- use robust global lookup (Hero or hero) to avoid mismatched global naming
    local H = rawget(_G, "Hero") or rawget(_G, "hero")
    local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
    hud.addLabel('energy_text', { text = tostring(val), x = 158, y = 768, layer = 'props' })
  end
  if not hud.get('deck_icon') then
    hud.addIcon('deck_icon', { img = 'img/hud/nombre de carte.png', x = 127, y = 827, layer = 'props' })
    hud.addLabel('deck_count', { text = '0', x = 130, y = 830, layer = 'props' })
  end
  if not hud.get('grave_icon') then
    hud.addIcon('grave_icon', { img = 'img/hud/Carte-simetiere.png', x = 127, y = 916, layer = 'props' })
    hud.addLabel('graveyard_count', { text = '0', x = 180, y = 975, layer = 'props' })
  end
  -- Settings button (bottom-right)
  if not hud.get('settings_btn') then
    hud.addButton('settings_btn', {
      img = 'img/hud/Button-Menu.png',
      x = 1854,
      y = 1024,
      layer = 'button',
      text = '',
      w = 64,
      h = 64,
      --[[
      Fonction : onClick
      Rôle : Fonction « On click » liée à la logique du jeu.
      Paramètres :
        - (aucun)
      Retour : aucune valeur (nil).
      ]]
      onClick = function()
        if scene then scene.curent = 'menu' end
      end,
    })
  end
  -- Ensure bottom footer background is set (can be overridden by HUD_BOTTOM_BG_PATH in main.lua)
  local bottom_path = rawget(_G, "HUD_BOTTOM_BG_PATH") or 'img/hud/footer-bare.jpg'
  hud.setBottomBarBg(bottom_path, 0)
end

--[[

Fonction : hud.update

Rôle : Met à jour la logique à chaque frame.

Paramètres :

  - dt : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function hud.update(dt)
  --update label value
  local H = rawget(_G, "Hero") or rawget(_G, "hero")
  local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
  hud.updateLabel('energy_text', tostring(val))
  hud.updateLabel('deck_count', tostring(#(Card and Card.deck or {})))
  hud.updateLabel('graveyard_count', tostring(#(Card and Card.graveyard or {})))
end

hud.updateLabel = function(id, text)
  --[[ if (#elements == 0) then return end ]]
  local el = elements[id]
  if el and el.type == "label" then
    el.text = tostring(text or "")
  end
end



-- Hover handling: returns true if an interactive HUD element is under cursor. Accepts:
--  hud.hover("click") -- uses screen.mouse.X/Y and triggers click if hovered
--  hud.hover(x, y)    -- just test hover at given coords
--[[
Fonction : hud.hover
Rôle : Fonction « Hover » liée à la logique du jeu.
Paramètres :
  - a : paramètre détecté automatiquement.
  - b : paramètre détecté automatiquement.
Retour : aucune valeur (nil).
]]
function hud.hover(a, b)
  local action, x, y
  -- use central cursor helper (unified input) to get coordinates
  if type(a) == "string" then
    action = a
    x, y = _getCursor()
  elseif type(a) == "number" and type(b) == "number" then
    x, y = a, b
  else
    x, y = _getCursor()
  end

  -- check only interactive elements, from topmost layer to bottom
  local order = { "button", "card", "props", "decor", "background" }
  for _, layer in ipairs(order) do
    local lst = layers[layer] or {}
    for i = #lst, 1, -1 do
      local el = elements[lst[i]]
      if el and el.interactive then
        local w, h = dimsFrom(el)
        local hit = hud.pointInRect(x, y, el.x or 0, el.y or 0, w, h)
        el._hover = hit
        if hit then
          if action == "click" then
            if el.sfx and el.sfx.click then play("click", el.sfx.click) else play("click") end
            if el.onClick then el.onClick(el) end
            return true
          end
          return true
        end
      end
    end
  end
  return false
end

-- Drawing
--[[
Fonction : hud.drawBackground
Rôle : Fonction « Draw background » liée à la logique du jeu.
Paramètres :
  - (aucun)
Retour : valeur calculée.
]]
function hud.drawBackground()
  local el = elements["bottom_bar_bg"]
  if not el then return end

  if el.img then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(el.img, el.x or 0, el.y or 0)
    return
  end

  -- Fallback visible band
  local h = el.h or 0
  if h > 0 then
    local w = (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    local x = el.x or 0
    local y = el.y or ((screen and screen.gameReso and screen.gameReso.height and (screen.gameReso.height - h)) or 0)
    love.graphics.setColor(0.18, 0.05, 0.22, 0.85) -- fill
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.9, 0.75, 1.0, 0.8)    -- outline
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

--[[

Fonction : hud.draw

Rôle : Affiche le rendu à l'écran.

Paramètres :

  - (aucun)

Retour : aucune valeur (nil).

]]

function hud.draw()
  ensureFont()
  love.graphics.setColor(1, 1, 1, 1)
  for _, layer in ipairs(LAYERS) do
    local lst = layers[layer] or {}
    for i = 1, #lst do
      local el = elements[lst[i]]
      if el then
        if el.type == "icon" then
          if el.img then love.graphics.draw(el.img, el.x or 0, el.y or 0) end
        elseif el.type == "label" then
          love.graphics.print(el.text or "", el.x or 0, el.y or 0)
        elseif el.type == "button" then
          if el.img then love.graphics.draw(el.img, el.x or 0, el.y or 0) end
          if el.text and el.text ~= "" then love.graphics.print(el.text, el.tx or (el.x + 10), el.ty or (el.y + 10)) end
        elseif el.type == "bar" then
          local max = (el.max or 1); if max <= 0 then max = 1 end
          local ratio = math.max(0, math.min(1, (el.current or 0) / max))
          if el.border then
            love.graphics.setColor(el.border); love.graphics.rectangle("line", el.x, el.y, el.w, el.h, 4, 4); love
                .graphics.setColor(1, 1, 1, 1)
          end
          if el.bg then love.graphics.draw(el.bg, el.x, el.y) end
          if el.fg then
            local iw, ih = el.fg:getDimensions()
            local sx = (el.w * ratio) / iw; local sy = el.h / ih
            love.graphics.draw(el.fg, el.x, el.y, 0, sx, sy)
          else
            if el.color then love.graphics.setColor(el.color) end
            love.graphics.rectangle("fill", el.x, el.y, el.w * ratio, el.h, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
          end
        end
      end
    end
  end
end

function hud.drawPanel(x, y, w, h, opts)
  opts = opts or {}
  local alpha = opts.alpha or 1
  local palette = opts.palette or {}
  local content = opts.content or {}

  local parentPosition = opts.parentPosition or { x = 0, y = 0 }
  x = x + parentPosition.x
  y = y + parentPosition.y

  if (#palette > 0) then
    love.graphics.setColor(palette.background or { 0, 0, 0, alpha })
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  else
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end

  for i = 1, #content, 1 do
    if (type(content[i]) == "function") then
      content[i]()
    end
  end
end

function hud.text(text, x, y, opts)
  opts = opts or {}
  local color = opts.color or { 1, 1, 1, 1 }
  local font = opts.font or "default"

  local font_size = opts.fontSize or 12
  font_size = fixeSizeFontByResolotionGame(font_size) -- Adjust font size based on resolution

  local parentPosition = opts.parentPosition or { x = 0, y = 0 }

  x = x + parentPosition.x
  y = y + parentPosition.y

  love.graphics.setColor(color)
  local _f = love.graphics.newFont(font_size)
  love.graphics.setFont(_f)
  love.graphics.print(text, x, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(_f, 16)
end

function hud.drawCard(card, x, y, opts)
  opts = opts or {}
  local scale = opts.scale or 1
  local parentPosition = opts.parentPosition or { x = 0, y = 0 }

  if (not card) then
    _logf("[HUD] la fonction hud.drawCard n'a pas reçu de carte en paramètre")
    return
  end

  local newW = (card and card.width * scale) or card.width
  local newH = (card and card.height * scale) or card.height

  x = x + parentPosition.x
  y = y + parentPosition.y

  if card and card.canvas then
    love.graphics.draw(card.canvas, x, y, 0, newW / card.canvas:getWidth(), newH / card.canvas:getHeight())
  else
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", x, y, newW, newH)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("No Card", x + 10, y + 10)
  end
end

return hud
