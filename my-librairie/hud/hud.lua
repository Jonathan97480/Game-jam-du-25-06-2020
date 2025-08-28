local res = require("my-librairie.resource_cache")
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

-- Footer check timer (seconds)
local _footer_check_timer = 0
local _footer_check_interval = rawget(_G, 'FOOTER_CHECK_INTERVAL') or 5 -- secs


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
  local w = el.w
  local h = el.h
  -- prefer cached intrinsic dimensions when available
  if (not w or not h) and el then
    if el.iw and el.ih then
      w = w or el.iw
      h = h or el.ih
    elseif el.img and el.img.getDimensions then
      local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
      if ok and iw and ih then
        w = w or iw
        h = h or ih
      end
    end
  end
  w = w or 0
  h = h or 0
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
    parent = opts.parent,
  }
  -- cache image dimensions when available to avoid getDimensions each frame
  if el.img and el.img.getDimensions then
    local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
    if ok and iw and ih then el.iw, el.ih = iw, ih end
  end
  elements[id] = el
  -- register as child on parent if provided
  if el.parent and elements[el.parent] then
    elements[el.parent].children = elements[el.parent].children or {}
    table.insert(elements[el.parent].children, id)
  end
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
    parent = opts.parent,
  }
  elements[id] = el
  if el.parent and elements[el.parent] then
    elements[el.parent].children = elements[el.parent].children or {}
    table.insert(elements[el.parent].children, id)
  end
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
    parent = opts.parent,
    -- Style properties for background and states - only if no image provided
    bgColor = opts.bgColor or (opts.img and nil or { 0.8, 0.8, 0.8, 1 }),         -- No default background if image
    hoverColor = opts.hoverColor or (opts.img and nil or { 0.9, 0.9, 0.9, 1 }),   -- No hover color if image
    clickColor = opts.clickColor or (opts.img and nil or { 0.7, 0.7, 0.7, 1 }),   -- No click color if image
    textColor = opts.textColor or { 1, 1, 1, 1 },                                 -- Default white text
    borderColor = opts.borderColor or (opts.img and nil or { 0.4, 0.4, 0.4, 1 }), -- No border if image
    cornerRadius = opts.cornerRadius or 8,                                        -- Rounded corners
    -- State tracking
    _isHovered = false,
    _isPressed = false
  }
  if not el.w or not el.h then
    el.w, el.h = dimsFrom(el)
  end
  -- cache image dimensions when available
  if el.img and el.img.getDimensions then
    local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
    if ok and iw and ih then el.iw, el.ih = iw, ih end
  end
  elements[id] = el
  if el.parent and elements[el.parent] then
    elements[el.parent].children = elements[el.parent].children or {}
    table.insert(elements[el.parent].children, id)
  end
  addToLayer(id, el.layer)
  return el
end

--[[
Fonction : hud.addImage
Rôle : Ajoute un élément de type 'image' (séparé de 'icon' pour clarification). Utilise
les mêmes options que hud.addIcon mais l'élément porte le type 'image'.
Paramètres :
  - id (string)
  - opts (table) : { x,y,w,h,img,layer,parent }
Retour : la table de l'élément créée
]]
function hud.addImage(id, opts)
  local el = {
    id = id,
    type = "image",
    x = opts.x or 0,
    y = opts.y or 0,
    img = opts.img and res.image(opts.img) or nil,
    layer = opts.layer or "background",
    w = opts.w,
    h = opts.h,
    interactive = false,
    parent = opts.parent,
  }
  if el.img and el.img.getDimensions then
    local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
    if ok and iw and ih then el.iw, el.ih = iw, ih end
  end
  elements[id] = el
  if el.parent and elements[el.parent] then
    elements[el.parent].children = elements[el.parent].children or {}
    table.insert(elements[el.parent].children, id)
  end
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

-- internal helper: remove id from its layer list
local function removeFromLayer(id)
  local el = elements[id]
  if not el or not el.layer then return end
  local lst = layers[el.layer]
  if not lst then return end
  for i = #lst, 1, -1 do
    if lst[i] == id then
      table.remove(lst, i); break
    end
  end
end

-- Remove an element and its children recursively
function hud.remove(id)
  local el = elements[id]
  if not el then return end
  -- remove children first
  if el.children then
    for _, cid in ipairs(el.children) do
      hud.remove(cid)
    end
  end
  removeFromLayer(id)
  elements[id] = nil
end

-- Create a panel (transparent icon) and return it. If panel exists it will be replaced.
--[[
Fonction : hud.setPanel
Rôle : Crée ou remplace un "panel" HUD (élément de type icon utilisé comme conteneur
       ou comme zone de rendu) et, optionnellement, crée ses enfants en un seul appel.

Paramètres :
  - id (string) : identifiant du panel dans le registry HUD (ex : 'game_panel').
  - x, y (number) : position en unités de jeu (gameReso) où placer le panel (coin supérieur gauche).
  - w, h (number) : largeur et hauteur du panel en unités de jeu.
  - opts (table) : options transmises à hud.addIcon pour le panel (par ex. layer). Si une image
      est souhaitée via les options globales, `opts.img` sera set automatiquement.
    - opts.children (table) : liste d'enfants à créer automatiquement. Chaque enfant est une table
      { id = 'child_id', type = 'icon'|'label'|'button', opts = { ... } } ; `opts` supporte
      les mêmes champs que hud.addIcon/hud.addLabel/hud.addButton. Les enfants recevront
      automatiquement la propriété `parent = id`.
  - options (table) : paramètres additionnels pour le comportement du panel :
    - type (string) : 'panel' (par défaut) ou 'container'. 'container' => panel non rendu, seuls
        ses enfants sont dessinés. 'panel' => le panel est rendu (rectangle coloré ou image).
    - color (table) : couleur RGBA {r,g,b,a} utilisée pour dessiner le fond si aucune image fournie.
    - bg or img (string) : chemin de ressource image utilisé comme fond du panel (étiré ou rendu
        selon typeRender).
    - typeRender (string) : mode de rendu de l'image de fond :
        * 'contain' (par défaut) : l'image est mise à l'échelle pour tenir entièrement dans le panel
          (pas de rognage), centrée.
        * 'cover' : l'image couvre entièrement le panel (peut être rognée), centrée.
        * 'native' : l'image est dessinée à sa taille native (pas de mise à l'échelle).

Retour :
  - retourne la table interne de l'élément panel créé (équivalent à hud.get(id)).

Effets de bord / comportements :
  - Si un élément portant le même `id` existe déjà, il sera supprimé (avec tous ses enfants)
    avant la création du nouveau panel.
  - Les enfants créés automatiquement seront enregistrés comme enfants (champ `children`) et
    seront supprimés si vous appelez `hud.clearPanel(id)` ou `hud.remove(id)`.

Exemples :
  -- container sans rendu, enfants seulement
  hud.setPanel('game_panel', 0,0, 1920,1080, { children = {...} }, { type = 'container' })

  -- panel rendu avec image de fond en cover
  hud.setPanel('game_panel', 0,0, 1920,1080, { children = {...} }, { type = 'panel', bg = 'img/bg.png', typeRender = 'cover' })

]]
function hud.setPanel(id, x, y, w, h, opts, options)
  opts = opts or {}
  -- allow panel background image via options.bg or options.img
  if options and (options.bg or options.img) then
    opts.img = options.bg or options.img
  end
  opts.x = x or (opts.x or 0)
  opts.y = y or (opts.y or 0)
  opts.w = w or opts.w
  opts.h = h or opts.h
  opts.layer = opts.layer or 'background'
  -- remove existing panel if present
  if elements[id] then hud.remove(id) end
  hud.addIcon(id, opts)
  -- mark as panel and store options (color, type)
  local panelEl = elements[id]
  if panelEl then
    panelEl._is_panel = true
    -- default: render unless explicitly type == 'container'
    panelEl._render = not (options and options.type == 'container')
    if options and options.color then panelEl.color = options.color end
    panelEl._panel_type = options and options.type or 'panel'
    -- render mode for image backgrounds: 'contain'|'cover'|'native'
    panelEl._render_mode = (options and options.typeRender) or 'contain'
    -- if image provided via opts.img, cache dimensions like addIcon would
    if panelEl.img and panelEl.img.getDimensions then
      local ok, iw, ih = pcall(function() return panelEl.img:getDimensions() end)
      if ok and iw and ih then panelEl.iw, panelEl.ih = iw, ih end
    end
  end
  -- create children if provided
  if opts.children and type(opts.children) == 'table' then
    for _, child in ipairs(opts.children) do
      local ctype = child.type or 'icon'
      local cid = child.id
      local copts = child.opts or {}
      copts.parent = id
      if ctype == 'icon' then
        hud.addIcon(cid, copts)
      elseif ctype == 'image' then
        hud.addImage(cid, copts)
      elseif ctype == 'label' then
        hud.addLabel(cid, copts)
      elseif ctype == 'button' then
        hud.addButton(cid, copts)
      else
        -- unknown, fallback to icon
        hud.addIcon(cid, copts)
      end
    end
  end
  return elements[id]
end

-- Clear panel and all its child elements
function hud.clearPanel(id)
  hud.remove(id)
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
      el.img   = img
      el.h     = h or (img.getHeight and img:getHeight()) or el.h or 0
      -- ensure footer spans full game resolution width
      local gw = (screen and screen.gameReso and screen.gameReso.width) or
          (responsive and responsive.gameReso and responsive.gameReso.width) or love.graphics.getWidth()
      el.x     = 0
      el.w     = gw
      -- if no explicit y provided, anchor footer to bottom of game resolution
      if (y == nil) then
        -- prefer global `screen` when available (keeps consistent naming with repo)
        local gh = (screen and screen.gameReso and screen.gameReso.height) or
            (responsive and responsive.gameReso and responsive.gameReso.height) or nil
        if gh and el.h then
          el.y = gh - el.h
        end
      end
      -- cache image intrinsic dimensions and precompute draw scales
      if el.img and el.img.getDimensions then
        local ok2, iw, ih = pcall(function() return el.img:getDimensions() end)
        if ok2 and iw and ih and iw > 0 and ih > 0 then
          el.iw, el.ih = iw, ih
          el._draw_sx = (el.w and iw and iw > 0) and (el.w / iw) or 1
          el._draw_sy = (el.h and ih and ih > 0) and (el.h / ih) or 1
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
  -- ensure bottom bar is available first so other elements can be anchored to it
  local bottom_path = rawget(_G, "HUD_BOTTOM_BG_PATH") or 'img/hud/footer-bare.jpg'
  hud.setBottomBarBg(bottom_path, 0)
  -- determine footer anchor (in gameReso coords)
  local gh = (screen and screen.gameReso and screen.gameReso.height) or
      (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
  local footer_el = elements["bottom_bar_bg"]
  local footer_y = (footer_el and footer_el.y) or (gh - (footer_el and footer_el.h or 65))
  -- compute conversion helpers: desired window pixels -> gameReso units
  local sx = (screen and screen.gameReso and screen.gameReso.width) or
      (responsive and responsive.gameReso and responsive.gameReso.width) or 1
  local sy = (screen and screen.gameReso and screen.gameReso.height) or
      (responsive and responsive.gameReso and responsive.gameReso.height) or 1
  local function winToGameW(px) return math.ceil(px / sx) end
  local function winToGameH(px) return math.ceil(px / sy) end
  do
    local end_w = winToGameW(260)
    local end_h = winToGameH(70)
    hud.addButton('end_turn', {
      img = 'img/hud/Button-fin-de-tour.png',
      x = 1283,
      -- larger end_turn button and anchored above footer
      w = end_w,
      h = end_h,
      y = footer_y - end_h - 8,
      layer = 'button',
      text = 'End of Tours',
      tx = 1310,
      ty = footer_y - math.ceil(end_h / 2),
    })
  end


  if not hud.get('energy_icon') then
    -- anchor icons to left above the footer
    do
      local icon_w = winToGameW(140)
      local icon_h = winToGameH(140)
      hud.addIcon('energy_icon',
        {
          img = 'img/hud/nombre de coup.png',
          x = 127,
          y = (footer_y - icon_h - 18),
          w = icon_w,
          h = icon_h,
          layer =
          'props'
        })
      hud.addLabel('energy_text', { text = tostring(val), x = 158, y = (footer_y - icon_h + 20), layer = 'props' })
    end
    -- use robust global lookup (Hero or hero) to avoid mismatched global naming
    local H = rawget(_G, "Hero") or rawget(_G, "hero")
    local val = (H and H.actor and H.actor.state and H.actor.state.power) or 0
    hud.addLabel('energy_text', { text = tostring(val), x = 158, y = (footer_y - 110), layer = 'props' })
  end
  if not hud.get('deck_icon') then
    do
      local icon_w = winToGameW(120)
      local icon_h = winToGameH(120)
      hud.addIcon('deck_icon',
        {
          img = 'img/hud/nombre de carte.png',
          x = 127,
          y = (footer_y - icon_h - 60),
          w = icon_w,
          h = icon_h,
          layer =
          'props'
        })
      hud.addLabel('deck_count', { text = '0', x = 130, y = (footer_y - icon_h + 55), layer = 'props' })
    end
  end
  if not hud.get('grave_icon') then
    do
      local icon_w = winToGameW(120)
      local icon_h = winToGameH(120)
      hud.addIcon('grave_icon',
        {
          img = 'img/hud/Carte-simetiere.png',
          x = 127,
          y = (footer_y - icon_h - 4),
          w = icon_w,
          h = icon_h,
          layer =
          'props'
        })
      hud.addLabel('graveyard_count', { text = '0', x = 180, y = (footer_y - icon_h + 90), layer = 'props' })
    end
  end
  -- Settings button (bottom-right)
  if not hud.get('settings_btn') then
    do
      local sb_w = winToGameW(96)
      local sb_h = winToGameH(96)
      hud.addButton('settings_btn', {
        img = 'img/hud/Button-Menu.png',
        -- anchor to right side near footer (bigger)
        x = 1854,
        w = sb_w,
        h = sb_h,
        y = footer_y - sb_h - 8,
        layer = 'button',
        text = '',
        sfx = nil,
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
  end
  -- bottom footer already set earlier
end

--[[

Fonction : hud.update

Rôle : Met à jour la logique à chaque frame.

Paramètres :

  - dt : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function hud.update(dt)
  -- periodic footer check writer
  _footer_check_timer = (_footer_check_timer or 0) + (dt or 0)
  if _footer_check_timer >= (_footer_check_interval or 5) then
    _footer_check_timer = 0
    pcall(function()
      local f = io.open("gameLogs/footer_check.log", "w")
      if f then
        local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
        local footer = elements["bottom_bar_bg"]
        local sx_local = (screen and screen.ratioScreen and screen.ratioScreen.width) or
            (responsive and responsive.ratioScreen and responsive.ratioScreen.width) or 1
        local eff_w = (footer and footer.w or 0) * sx_local
        f:write(string.format("footer_eff_width=%.1f\n", eff_w))
        f:write(string.format("window_width=%.1f\n", window_w))
        f:close()
      end
    end)
  end

  -- Update button states (hover/press detection)
  local mx, my = 0, 0
  local mouseDown = false

  -- Get mouse position safely
  if love and love.mouse and love.mouse.getPosition then
    local ok, x, y = pcall(love.mouse.getPosition)
    if ok then mx, my = x or 0, y or 0 end
  end

  -- Get mouse state safely
  if love and love.mouse and love.mouse.isDown then
    local ok, down = pcall(love.mouse.isDown, 1)
    if ok then mouseDown = down end
  end

  -- Update all interactive elements (buttons)
  for id, el in pairs(elements) do
    if el and el.interactive and el.type == "button" then
      local isInside = mx >= (el.x or 0) and mx <= (el.x or 0) + (el.w or 0) and
          my >= (el.y or 0) and my <= (el.y or 0) + (el.h or 0)

      -- Update hover state
      el._isHovered = isInside

      -- Update press state
      el._isPressed = isInside and mouseDown
    end
  end

  -- update label values
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
function hud.hover(a, b, c)
  local action, x, y
  -- use central cursor helper (unified input) to get coordinates
  if type(a) == "string" then
    action = a
    -- support hud.hover("click", x, y) when coords are provided
    if type(b) == "number" and type(c) == "number" then
      x, y = b, c
    else
      x, y = _getCursor()
    end
  elseif type(a) == "number" and type(b) == "number" then
    x, y = a, b
  else
    x, y = _getCursor()
  end

  -- check only interactive elements, from topmost layer to bottom
  -- Diagnostic: log click/hover attempts to file to help debugging
  pcall(function()
    if action == "click" then
      local f = io.open("gameLogs/hud_clicks.log", "a")
      if f then
        f:write(string.format("CLICK -> action=%s x=%.1f y=%.1f\n", tostring(action), tostring(x), tostring(y))); f
            :close()
      end
    end
  end)

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
            -- click handled (visual debug removed)
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
    -- Draw background image in game coordinates (main.lua already scales to window)
    love.graphics.setColor(1, 1, 1, 1)
    -- draw stretched to el.w/el.h if provided
    local iw, ih = 0, 0
    if el.img.getDimensions then iw, ih = el.img:getDimensions() end
    local sx_img, sy_img = 1, 1
    if el.w and iw and iw > 0 then sx_img = (el.w / iw) end
    if el.h and ih and ih > 0 then sy_img = (el.h / ih) end
    love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
    -- write footer check log only once (avoid per-frame IO)
    if not rawget(_G, "_footer_check_done") then
      rawset(_G, "_footer_check_done", true)
      pcall(function()
        local f = io.open("gameLogs/footer_check.log", "w")
        if f then
          local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
          -- effective footer width in window pixels: convert game units to window using screen.ratioScreen
          local sx = (screen and screen.ratioScreen and screen.ratioScreen.width) or
              (responsive and responsive.ratioScreen and responsive.ratioScreen.width) or 1
          local eff_w = (el.w or 0) * sx
          f:write(string.format("footer_eff_width=%.1f\n", eff_w))
          f:write(string.format("window_width=%.1f\n", window_w))
          f:close()
        end
      end)
    end
    return
  end
  -- Fallback visible band (draw in game coordinates)
  local h = el.h or 0
  if h > 0 then
    local w = el.w or (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    local x = el.x or 0
    local y = el.y or ((screen and screen.gameReso and screen.gameReso.height and (screen.gameReso.height - h)) or 0)
    love.graphics.setColor(0.18, 0.05, 0.22, 0.85) -- fill
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.9, 0.75, 1.0, 0.8)    -- outline
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end
  -- fallback footer check log (only once)
  if not rawget(_G, "_footer_check_done") then
    rawset(_G, "_footer_check_done", true)
    pcall(function()
      local f = io.open("gameLogs/footer_check.log", "w")
      if f then
        local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
        -- robust footer width detection: prefer explicit w, then cached iw, then image dimensions
        local eff_w = 0
        if el then
          eff_w = el.w or el.iw or 0
          if eff_w == 0 and el.img and el.img.getDimensions then
            local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
            if ok and iw then eff_w = iw end
          end
          local sx = (screen and screen.ratioScreen and screen.ratioScreen.width) or
              (responsive and responsive.ratioScreen and responsive.ratioScreen.width) or 1
          eff_w = eff_w * (sx or 1)
        end
        f:write(string.format("footer_eff_width=%.1f\n", eff_w))
        f:write(string.format("window_width=%.1f\n", window_w))
        f:close()
      end
    end)
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
  -- ensure screen ratio is up-to-date so HUD scaling uses correct values
  if screen and type(screen.UpdateRatio) == 'function' then pcall(screen.UpdateRatio) end

  love.graphics.push()
  local sx = (screen and screen.ratioScreen and screen.ratioScreen.width) or
      (responsive and responsive.ratioScreen and responsive.ratioScreen.width) or 1
  local sy = (screen and screen.ratioScreen and screen.ratioScreen.height) or
      (responsive and responsive.ratioScreen and responsive.ratioScreen.height) or 1

  -- hud scaling is performed globally in main.lua; avoid local scaling here
  love.graphics.setColor(1, 1, 1, 1)

  for _, layer in ipairs(LAYERS) do
    local lst = layers[layer] or {}
    for i = 1, #lst do
      local el = elements[lst[i]]
      if el then
        if el.type == "icon" or el.type == "image" then
          -- Panels: special handling (may be containers without rendering)
          if el._is_panel then
            if el._render then
              -- if the panel has an image, draw it stretched to w/h like footer
              if el.img then
                local iw, ih = 0, 0
                if el.img.getDimensions then iw, ih = el.img:getDimensions() end
                local w, h = el.w or iw, el.h or ih
                -- choose rendering strategy
                local mode = el._render_mode or 'contain'
                if mode == 'native' or (not iw or iw == 0) or (not ih or ih == 0) then
                  -- native: draw at natural size at el.x, el.y
                  love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, iw and 1 or 1, ih and 1 or 1)
                else
                  local scale = 1
                  if mode == 'contain' then
                    scale = math.min((w / iw), (h / ih))
                  elseif mode == 'cover' then
                    scale = math.max((w / iw), (h / ih))
                  else
                    -- fallback: stretch to fill
                    local sx_img = (w / iw)
                    local sy_img = (h / ih)
                    love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
                  end
                  -- center the image inside the panel
                  local drawW = iw * scale
                  local drawH = ih * scale
                  local dx = (el.x or 0) + math.floor(((w - drawW) / 2) + 0.5)
                  local dy = (el.y or 0) + math.floor(((h - drawH) / 2) + 0.5)
                  love.graphics.draw(el.img, dx, dy, 0, scale, scale)
                end
              else
                -- draw a filled rect as panel background, prefer el.color or default
                local col = el.color or { 0.18, 0.05, 0.22, 0.85 }
                love.graphics.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
                love.graphics.rectangle("fill", el.x or 0, el.y or 0, el.w or 0, el.h or 0)
                -- optional outline
                love.graphics.setColor(0.9, 0.75, 1.0, 0.8)
                love.graphics.rectangle("line", el.x or 0, el.y or 0, el.w or 0, el.h or 0)
                love.graphics.setColor(1, 1, 1, 1)
              end
            end
          else
            if el.img then
              local iw, ih = 0, 0
              if el.img.getDimensions then iw, ih = el.img:getDimensions() end

              local sx_img = 1
              local sy_img = 1
              if el.w and iw and iw > 0 then sx_img = (el.w / iw) end
              if el.h and ih and ih > 0 then sy_img = (el.h / ih) end
              -- if only one dimension is provided, keep aspect ratio
              if el.w and not el.h and ih and ih > 0 then sy_img = sx_img end
              if el.h and not el.w and iw and iw > 0 then sx_img = sy_img end
              love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
            end
          end
        elseif el.type == "label" then
          love.graphics.print(el.text or "", el.x or 0, el.y or 0)
        elseif el.type == "button" then
          -- Draw button background with hover/click states (only if no image)
          if not el.img then
            local bgColor = el.bgColor
            if el._isPressed then
              bgColor = el.clickColor
            elseif el._isHovered then
              bgColor = el.hoverColor
            end

            -- Draw background rectangle
            if bgColor then
              love.graphics.setColor(bgColor[1] or 1, bgColor[2] or 1, bgColor[3] or 1, bgColor[4] or 1)
              love.graphics.rectangle("fill", el.x or 0, el.y or 0, el.w or 0, el.h or 0, el.cornerRadius or 8)
            end

            -- Draw border
            if el.borderColor then
              love.graphics.setColor(el.borderColor[1] or 1, el.borderColor[2] or 1, el.borderColor[3] or 1,
                el.borderColor[4] or 1)
              love.graphics.setLineWidth(2)
              love.graphics.rectangle("line", el.x or 0, el.y or 0, el.w or 0, el.h or 0, el.cornerRadius or 8)
            end
          end

          -- Reset color for image/text
          love.graphics.setColor(1, 1, 1, 1)

          -- Draw button image if available
          if el.img then
            local iw, ih = 0, 0
            if el.img.getDimensions then iw, ih = el.img:getDimensions() end
            local sx_img = 1
            local sy_img = 1
            if el.w and iw and iw > 0 then sx_img = (el.w / iw) end
            if el.h and ih and ih > 0 then sy_img = (el.h / ih) end
            if el.w and not el.h and ih and ih > 0 then sy_img = sx_img end
            if el.h and not el.w and iw and iw > 0 then sx_img = sy_img end

            -- Apply hover/click effects to image (tint or opacity)
            if el._isPressed and el.clickColor then
              -- Tint image with click color
              love.graphics.setColor(el.clickColor[1] or 1, el.clickColor[2] or 1, el.clickColor[3] or 1,
                el.clickColor[4] or 1)
            elseif el._isHovered and el.hoverColor then
              -- Tint image with hover color
              love.graphics.setColor(el.hoverColor[1] or 1, el.hoverColor[2] or 1, el.hoverColor[3] or 1,
                el.hoverColor[4] or 1)
            else
              -- Normal image color
              love.graphics.setColor(1, 1, 1, 1)
            end

            -- Apply click offset for pressed effect
            local offsetX = el._isPressed and 2 or 0
            local offsetY = el._isPressed and 2 or 0
            love.graphics.draw(el.img, (el.x or 0) + offsetX, (el.y or 0) + offsetY, 0, sx_img, sy_img)

            -- Reset color for text
            love.graphics.setColor(1, 1, 1, 1)
          end

          -- Draw button text
          if el.text and el.text ~= "" then
            -- Set text color
            if el.textColor then
              love.graphics.setColor(el.textColor[1] or 1, el.textColor[2] or 1, el.textColor[3] or 1,
                el.textColor[4] or 1)
            end

            -- Apply click offset for pressed effect and center text properly
            local offsetX = el._isPressed and 2 or 0
            local offsetY = el._isPressed and 2 or 0

            -- Get text dimensions for proper centering
            local font = love.graphics.getFont()
            local textWidth = 0
            local textHeight = 0
            if font then
              textWidth = font:getWidth(el.text)
              textHeight = font:getHeight()
            end

            -- Calculate centered position or use custom tx/ty if provided
            local textX, textY
            if el.tx and el.tx ~= (el.x + 10) then
              -- Custom position provided
              textX = el.tx
            else
              -- Auto-center horizontally
              textX = (el.x or 0) + ((el.w or 0) - textWidth) / 2
            end

            if el.ty and el.ty ~= (el.y + 10) then
              -- Custom position provided
              textY = el.ty
            else
              -- Auto-center vertically
              textY = (el.y or 0) + ((el.h or 0) - textHeight) / 2
            end

            love.graphics.print(el.text, textX + offsetX, textY + offsetY)

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
          end
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
            local sx2 = (el.w * ratio) / iw; local sy2 = el.h / ih
            love.graphics.draw(el.fg, el.x, el.y, 0, sx2, sy2)
          else
            if el.color then love.graphics.setColor(el.color) end
            love.graphics.rectangle("fill", el.x, el.y, el.w * ratio, el.h, 4, 4)
            love.graphics.setColor(1, 1, 1, 1)
          end
        end
      end
    end
  end

  -- draw on-screen debug click message (2s)
  if hud._lastClickMsg and hud._lastClickTime then
    local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.time()
    if now - hud._lastClickTime < 2 then
      local msg = hud._lastClickMsg
      love.graphics.push()
      love.graphics.origin()
      love.graphics.setColor(1, 1, 0, 1)
      love.graphics.print(msg, 10, 10)
      love.graphics.pop()
    end
  end

  -- one-time debug dump: write scaled positions to gameLogs/hud_scaled_snapshot.log
  if not rawget(_G, "_hud_scaled_dump_done") then
    rawset(_G, "_hud_scaled_dump_done", true)
    pcall(function()
      local f = io.open("gameLogs/hud_scaled_snapshot.log", "w")
      if not f then return end
      f:write("SCALED HUD POSITIONS\n")
      f:write(string.format("ratio: sx=%.3f sy=%.3f\n", sx, sy))
      for _, layer2 in ipairs(LAYERS) do
        local lst2 = layers[layer2] or {}
        for j = 1, #lst2 do
          local e = elements[lst2[j]]
          if e then
            local w, h = dimsFrom(e)
            local sxp, syp = (e.x or 0) * sx, (e.y or 0) * sy
            f:write(string.format("%s | type=%s | x=%.1f | y=%.1f | w=%s | h=%s | layer=%s | text=%s\n",
              tostring(e.id), tostring(e.type), sxp, syp, tostring(w), tostring(h), tostring(e.layer), tostring(e.text)))
          end
        end
      end
      f:close()
      -- also write footer check here (safer: this dump runs reliably)
      pcall(function()
        local g = io.open("gameLogs/footer_check.log", "w")
        if g then
          local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
          local footer = elements["bottom_bar_bg"]
          local eff_w = 0
          if footer then
            local sx_local = sx or 1
            -- simple detection: prefer explicit w then cached iw
            eff_w = (footer and (footer.w or footer.iw or 0) or 0) * sx_local
          end
          g:write(string.format("footer_eff_width=%.1f\n", eff_w))
          g:write(string.format("window_width=%.1f\n", window_w))
          g:close()
        end
      end)
    end)
  end
  love.graphics.pop()
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
  local _f = res.font(font_size)
  love.graphics.setFont(_f)
  love.graphics.print(text, x, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(_f)
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

-- Debug accessor (not for production) to inspect internal layers
function hud._getLayers()
  return layers
end

return hud
