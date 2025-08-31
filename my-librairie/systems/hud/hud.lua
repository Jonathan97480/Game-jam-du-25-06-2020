-- Module HUD pour LÖVE2D
-- Ce module gère l'interface utilisateur avec des éléments comme des icônes, labels, boutons et barres,
-- organisés en couches pour un rendu ordonné.

local res = require("my-librairie.managers.resource_cache")
local responsive = require("my-librairie/utils/responsive")
-- optional unified input helper (mouse + joystick)

-- Layered HUD Manager
local hud = {}

-- Fonction locale pour logger des messages
-- Utilise globalFunction si disponible, sinon print
local function _logf(fmt, ...)
  local gf = rawget(_G, 'globalFunction')
  local txt = string.format(fmt, ...)
  if gf and gf.log and gf.log.info then gf.log.info(txt) else print(txt) end
end

-- Couches de rendu (draw order: background -> decor -> props -> card -> button)
local LAYERS = { "background", "decor", "props", "card", "button" }
local layer_index = { background = 1, decor = 2, props = 3, card = 4, button = 5 }

-- Registre des éléments : id -> élément
local elements = {}
-- Couches : nom de couche -> liste d'ids
local layers = { background = {}, decor = {}, props = {}, card = {}, button = {} }

-- Thème par défaut
hud.theme = { font_size = 20 }

-- Fonction locale pour ajuster la taille de la police en fonction de la résolution
-- @param size : taille de base de la police
-- @return : taille ajustée
local function fixeSizeFontByResolotionGame(size)
  local scale = responsive.getWindow.height / responsive.gameReso.height
  local fontSize = size * scale
  return fontSize
end

-- Fonction locale pour s'assurer qu'une police est définie
local function ensureFont()
  love.graphics.setFont(res.font(hud.theme.font_size))
end

-- Fonction locale pour vérifier si un point est dans un rectangle
-- @param px : position x du point
-- @param py : position y du point
-- @param x : position x du rectangle
-- @param y : position y du rectangle
-- @param w : largeur du rectangle
-- @param h : hauteur du rectangle
-- @return : true si le point est dans le rectangle, false sinon
hud.pointInRect = function(px, py, x, y, w, h)
  if type(px) ~= "number" or type(py) ~= "number" or type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then
    return false
  end
  return px >= x and py >= y and px <= x + w and py <= y + h
end

-- Fonction locale pour ajouter un élément à une couche
-- @param id : identifiant de l'élément
-- @param layer : couche cible
local function addToLayer(id, layer)
  layer = layer or "button"
  if not layers[layer] then layers[layer] = {} end
  table.insert(layers[layer], id)
end

-- Fonction locale pour obtenir les dimensions d'un élément
-- @param el : élément
-- @return : largeur, hauteur
local function dimsFrom(el)
  local w = el.w
  local h = el.h
  -- Préférer les dimensions intrinsèques mises en cache
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

-- Fonction locale pour obtenir la position du curseur
-- @return : x, y du curseur
local function _getCursor()
  local ok, cur = pcall(require, "my-librairie/cursor")
  if ok and cur and cur.get then return cur.get() end
  return 0, 0
end

-- API Publique

-- Ajoute une icône
-- @param id : identifiant unique
-- @param opts : options (x, y, img, layer, w, h, parent)
-- @return : l'élément créé
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
  -- Cache les dimensions de l'image
  if el.img and el.img.getDimensions then
    local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
    if ok and iw and ih then el.iw, el.ih = iw, ih end
  end
  elements[id] = el
  -- Enregistre comme enfant si parent fourni
  if el.parent and elements[el.parent] then
    elements[el.parent].children = elements[el.parent].children or {}
    table.insert(elements[el.parent].children, id)
  end
  addToLayer(id, el.layer)
  return el
end

-- Ajoute un label
-- @param id : identifiant unique
-- @param opts : options (x, y, text, layer, parent)
-- @return : l'élément créé
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

-- Ajoute une barre
-- @param id : identifiant unique
-- @param opts : options (x, y, w, h, current, max, color, border, bg, fg, layer)
-- @return : l'élément créé
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

-- Ajoute un bouton
-- @param id : identifiant unique
-- @param opts : options (x, y, img, text, tx, ty, onClick, layer, w, h, sfx, parent, bgColor, hoverColor, clickColor, textColor, borderColor, cornerRadius)
-- @return : l'élément créé
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
    bgColor = opts.bgColor or (opts.img and nil or { 0.8, 0.8, 0.8, 1 }),
    hoverColor = opts.hoverColor or (opts.img and nil or { 0.9, 0.9, 0.9, 1 }),
    clickColor = opts.clickColor or (opts.img and nil or { 0.7, 0.7, 0.7, 1 }),
    textColor = opts.textColor or { 1, 1, 1, 1 },
    borderColor = opts.borderColor or (opts.img and nil or { 0.4, 0.4, 0.4, 1 }),
    cornerRadius = opts.cornerRadius or 8,
    _isHovered = false,
    _isPressed = false
  }
  if not el.w or not el.h then
    el.w, el.h = dimsFrom(el)
  end
  -- Cache les dimensions de l'image
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

-- Ajoute une image
-- @param id : identifiant unique
-- @param opts : options (x, y, w, h, img, layer, parent)
-- @return : l'élément créé
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

-- Obtient un élément par id
-- @param id : identifiant
-- @return : l'élément ou nil
function hud.get(id) return elements[id] end

-- Définit le texte d'un label
-- @param id : identifiant du label
-- @param text : nouveau texte
function hud.setText(id, text)
  local el = elements[id]
  if el and el.type == "label" then el.text = tostring(text or "") end
end

-- Définit les valeurs d'une barre
-- @param id : identifiant de la barre
-- @param cur : valeur actuelle
-- @param max : valeur maximale
function hud.setBar(id, cur, max)
  local el = elements[id]
  if el and el.type == "bar" then
    el.current = cur or el.current
    el.max = max or el.max
  end
end

-- Fonction locale pour supprimer un élément de sa couche
-- @param id : identifiant
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

-- Supprime un élément et ses enfants
-- @param id : identifiant
function hud.remove(id)
  local el = elements[id]
  if not el then return end
  -- Supprime les enfants d'abord
  if el.children then
    for _, cid in ipairs(el.children) do
      hud.remove(cid)
    end
  end
  removeFromLayer(id)
  elements[id] = nil
end

-- Vide tous les éléments HUD
function hud.clear()
  elements = {}
  for layerName, _ in pairs(layers) do
    layers[layerName] = {}
  end
end

-- Définit un panel
-- @param id : identifiant
-- @param x, y, w, h : position et dimensions
-- @param opts : options supplémentaires
-- @param options : alias pour opts
-- @return : l'élément panel
function hud.setPanel(id, x, y, w, h, opts, options)
  opts = opts or {}
  if options and (options.bg or options.img) then
    opts.img = options.bg or options.img
  end
  opts.x = x or (opts.x or 0)
  opts.y = y or (opts.y or 0)
  opts.w = w or opts.w
  opts.h = h or opts.h
  opts.layer = opts.layer or 'background'
  if elements[id] then hud.remove(id) end
  hud.addIcon(id, opts)
  local panelEl = elements[id]
  if panelEl then
    panelEl._is_panel = true
    panelEl._render = not (options and options.type == 'container')
    if options and options.color then panelEl.color = options.color end
    panelEl._panel_type = options and options.type or 'panel'
    panelEl._render_mode = (options and options.typeRender) or 'contain'
    if panelEl.img and panelEl.img.getDimensions then
      local ok, iw, ih = pcall(function() return el.img:getDimensions() end)
      if ok and iw and ih then panelEl.iw, panelEl.ih = iw, ih end
    end
  end
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
        hud.addIcon(cid, copts)
      end
    end
  end
  return elements[id]
end

-- Vide un panel
-- @param id : identifiant du panel
function hud.clearPanel(id)
  hud.remove(id)
end

-- Définit l'arrière-plan de la barre inférieure
-- @param path : chemin de l'image
-- @param x, y, h : position et hauteur
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
      local gw = (screen and screen.gameReso and screen.gameReso.width) or
          (responsive and responsive.gameReso and responsive.gameReso.width) or love.graphics.getWidth()
      el.x     = 0
      el.w     = gw
      if (y == nil) then
        local gh = (screen and screen.gameReso and screen.gameReso.height) or
            (responsive and responsive.gameReso and responsive.gameReso.height) or nil
        if gh and el.h then
          el.y = gh - el.h
        end
      end
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

-- Sons pour les interactions
local _sfx = { hover = nil, click = nil, dragStart = nil, dragMove = nil, dragEnd = nil }
local _sfx_last = { dragMove = 0 }
local _sfx_rate = { dragMove = 0.05 }

-- Définit les sons
-- @param tbl : table des sons
function hud.setSfx(tbl) for k, v in pairs(tbl or {}) do _sfx[k] = v end end

-- Joue un son
-- @param name : nom du son
-- @param custom : chemin personnalisé
local function play(name, custom)
  local path = custom or _sfx[name]; if not path then return end
  if name == "dragMove" then
    local t = love.timer.getTime(); if t - (_sfx_last.dragMove or 0) < (_sfx_rate.dragMove or 0.05) then return end
    _sfx_last.dragMove = t
  end
  local ok, src = pcall(res.audio, path, "static"); if ok and src then pcall(function() src:play() end) end
end

-- Joue un son d'événement
-- @param event : événement
function hud.sfx(event) play(event) end

-- Gère les sons de drag
-- @param event : événement de drag
function hud.drag(event)
  if event == "start" then
    play("dragStart")
  elseif event == "move" then
    play("dragMove")
  elseif event == "end" then
    play("dragEnd")
  end
end

-- Initialise le HUD
function hud.load()
end

-- Met à jour le HUD
-- @param dt : delta time
function hud.update(dt)
  for id, el in pairs(elements) do
    if el and el.interactive and el.type == "button" then
      local isInside = _G.globalFunction.mouse.hover(el.x, el.y, el.w, el.h)
      el._isHovered = isInside
      el._isPressed = isInside and _G.globalFunction.mouse.click()
    end
  end
end

-- Met à jour le texte d'un label
-- @param id : identifiant
-- @param text : nouveau texte
function hud.updateLabel(id, text)
  local el = elements[id]
  if el and el.type == "label" then
    el.text = tostring(text or "")
  end
end

-- Gère le survol et les clics
-- @param a : action ou x
-- @param b : y ou nil
-- @param c : nil ou y si coords fournies
-- @return : true si interaction
function hud.hover(a, b, c)
  local action, x, y
  if type(a) == "string" then
    action = a
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
            return true
          end
          return true
        end
      end
    end
  end
  return false
end

-- Dessine l'arrière-plan
function hud.drawBackground()
  local el = elements["bottom_bar_bg"]
  if not el then return end

  if el.img then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = 0, 0
    if el.img.getDimensions then iw, ih = el.img:getDimensions() end
    local sx_img, sy_img = 1, 1
    if el.w and iw and iw > 0 then sx_img = (el.w / iw) end
    if el.h and ih and ih > 0 then sy_img = (el.h / ih) end
    love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
    if not rawget(_G, "_footer_check_done") then
      rawset(_G, "_footer_check_done", true)
      pcall(function()
        local f = io.open("gameLogs/footer_check.log", "w")
        if f then
          local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
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
  local h = el.h or 0
  if h > 0 then
    local w = el.w or (screen and screen.gameReso and screen.gameReso.width) or love.graphics.getWidth()
    local x = el.x or 0
    local y = el.y or ((screen and screen.gameReso and screen.gameReso.height and (screen.gameReso.height - h)) or 0)
    love.graphics.setColor(0.18, 0.05, 0.22, 0.85)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(0.9, 0.75, 1.0, 0.8)
    love.graphics.rectangle("line", x, y, w, h)
    love.graphics.setColor(1, 1, 1, 1)
  end
  if not rawget(_G, "_footer_check_done") then
    rawset(_G, "_footer_check_done", true)
    pcall(function()
      local f = io.open("gameLogs/footer_check.log", "w")
      if f then
        local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
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

-- Dessine le HUD
function hud.draw()
  local hasElements = false
  for _, layer in ipairs(LAYERS) do
    local lst = layers[layer] or {}
    if #lst > 0 then
      hasElements = true
      break
    end
  end
  if not hasElements then return end

  ensureFont()
  if screen and type(screen.UpdateRatio) == 'function' then pcall(screen.UpdateRatio) end

  love.graphics.push()
  local sx = (screen and screen.ratioScreen and screen.ratioScreen.width) or
      (responsive and responsive.ratioScreen and responsive.ratioScreen.width) or 1
  local sy = (screen and screen.ratioScreen and screen.ratioScreen.height) or
      (responsive and responsive.ratioScreen and responsive.ratioScreen.height) or 1

  love.graphics.setColor(1, 1, 1, 1)

  for _, layer in ipairs(LAYERS) do
    local lst = layers[layer] or {}
    for i = 1, #lst do
      local el = elements[lst[i]]
      if el then
        if el.type == "icon" or el.type == "image" then
          if el._is_panel then
            if el._render then
              if el.img then
                local iw, ih = 0, 0
                if el.img.getDimensions then iw, ih = el.img:getDimensions() end
                local w, h = el.w or iw, el.h or ih
                local mode = el._render_mode or 'contain'
                if mode == 'native' or (not iw or iw == 0) or (not ih or ih == 0) then
                  love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, iw and 1 or 1, ih and 1 or 1)
                else
                  local scale = 1
                  if mode == 'contain' then
                    scale = math.min((w / iw), (h / ih))
                  elseif mode == 'cover' then
                    scale = math.max((w / iw), (h / ih))
                  else
                    local sx_img = (w / iw)
                    local sy_img = (h / ih)
                    love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
                  end
                  local drawW = iw * scale
                  local drawH = ih * scale
                  local dx = (el.x or 0) + math.floor(((w - drawW) / 2) + 0.5)
                  local dy = (el.y or 0) + math.floor(((h - drawH) / 2) + 0.5)
                  love.graphics.draw(el.img, dx, dy, 0, scale, scale)
                end
              else
                local col = el.color or { 0.18, 0.05, 0.22, 0.85 }
                love.graphics.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
                local x = tonumber(el.x) or 0
                local y = tonumber(el.y) or 0
                local w = tonumber(el.w) or 0
                local h = tonumber(el.h) or 0
                love.graphics.rectangle("fill", x, y, w, h)
                love.graphics.setColor(0.9, 0.75, 1.0, 0.8)
                love.graphics.rectangle("line", x, y, w, h)
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
              if el.w and not el.h and ih and ih > 0 then sy_img = sx_img end
              if el.h and not el.w and iw and iw > 0 then sx_img = sy_img end
              love.graphics.draw(el.img, el.x or 0, el.y or 0, 0, sx_img, sy_img)
            end
          end
        elseif el.type == "label" then
          love.graphics.print(el.text or "", el.x or 0, el.y or 0)
        elseif el.type == "button" then
          if not el.img then
            local bgColor = el.bgColor
            if el._isPressed then
              bgColor = el.clickColor
            elseif el._isHovered then
              bgColor = el.hoverColor
            end
            if bgColor then
              love.graphics.setColor(bgColor[1] or 1, bgColor[2] or 1, bgColor[3] or 1, bgColor[4] or 1)
              love.graphics.rectangle("fill", el.x or 0, el.y or 0, el.w or 0, el.h or 0, el.cornerRadius or 8)
            end
            if el.borderColor then
              love.graphics.setColor(el.borderColor[1] or 1, el.borderColor[2] or 1, el.borderColor[3] or 1,
                el.borderColor[4] or 1)
              love.graphics.setLineWidth(2)
              love.graphics.rectangle("line", el.x or 0, el.y or 0, el.w or 0, el.h or 0, el.cornerRadius or 8)
            end
          end
          love.graphics.setColor(1, 1, 1, 1)
          if el.img then
            local iw, ih = 0, 0
            if el.img.getDimensions then iw, ih = el.img:getDimensions() end
            local sx_img = 1
            local sy_img = 1
            if el.w and iw and iw > 0 then sx_img = (el.w / iw) end
            if el.h and ih and ih > 0 then sy_img = (el.h / ih) end
            if el.w and not el.h and ih and ih > 0 then sy_img = sx_img end
            if el.h and not el.w and iw and iw > 0 then sx_img = sy_img end
            if el._isPressed and el.clickColor then
              love.graphics.setColor(el.clickColor[1] or 1, el.clickColor[2] or 1, el.clickColor[3] or 1,
                el.clickColor[4] or 1)
            elseif el._isHovered and el.hoverColor then
              love.graphics.setColor(el.hoverColor[1] or 1, el.hoverColor[2] or 1, el.hoverColor[3] or 1,
                el.hoverColor[4] or 1)
            else
              love.graphics.setColor(1, 1, 1, 1)
            end
            local offsetX = el._isPressed and 2 or 0
            local offsetY = el._isPressed and 2 or 0
            love.graphics.draw(el.img, (el.x or 0) + offsetX, (el.y or 0) + offsetY, 0, sx_img, sy_img)
            love.graphics.setColor(1, 1, 1, 1)
          end
          if el.text and el.text ~= "" then
            if el.textColor then
              love.graphics.setColor(el.textColor[1] or 1, el.textColor[2] or 1, el.textColor[3] or 1,
                el.textColor[4] or 1)
            end
            local offsetX = el._isPressed and 2 or 0
            local offsetY = el._isPressed and 2 or 0
            local font = love.graphics.getFont()
            local textWidth = 0
            local textHeight = 0
            if font then
              textWidth = font:getWidth(el.text)
              textHeight = font:getHeight()
            end
            local textX, textY
            if el.tx and el.tx ~= (el.x + 10) then
              textX = el.tx
            else
              textX = (el.x or 0) + ((el.w or 0) - textWidth) / 2
            end
            if el.ty and el.ty ~= (el.y + 10) then
              textY = el.ty
            else
              textY = (el.y or 0) + ((el.h or 0) - textHeight) / 2
            end
            love.graphics.print(el.text, textX + offsetX, textY + offsetY)
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
      pcall(function()
        local g = io.open("gameLogs/footer_check.log", "w")
        if g then
          local window_w, window_h = love.graphics.getWidth(), love.graphics.getHeight()
          local footer = elements["bottom_bar_bg"]
          local eff_w = 0
          if footer then
            local sx_local = sx or 1
            eff_w = (footer.w or footer.iw or 0) * sx_local
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

-- Dessine un panel
-- @param x, y, w, h : position et dimensions
-- @param opts : options
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

-- Définit du texte a afficher
-- @param text : texte à afficher
-- @param x, y : position
-- @param opts : options
function hud.text(text, x, y, opts)
  opts = opts or {}
  local color = opts.color or { 1, 1, 1, 1 }
  local font = opts.font or "default"

  local font_size = opts.fontSize or 12
  font_size = fixeSizeFontByResolotionGame(font_size)

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

-- Dessine une carte
-- @param card : objet carte
-- @param x, y : position
-- @param opts : options
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

-- Accès debug aux couches
-- @return : les couches
function hud._getLayers()
  return layers
end

return hud
