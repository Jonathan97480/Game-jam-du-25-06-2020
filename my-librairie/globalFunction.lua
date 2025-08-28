-- globalFunction.lua (renamed from myFunction.lua)
-- Provides utility functions previously exported as myFunction.
local globalFunction = {}
local lockClick = false

local res = require("my-librairie.resource_cache")
local okcfg, config = pcall(require, "my-librairie.config")
config = okcfg and config or { logs = { maxFiles = 10, maxEntries = 200, dir = "gameLogs" } }

-- Ensure logs table exists
config.logs = config.logs or { maxFiles = 10, maxEntries = 200, dir = "gameLogs" }

-- Prepare session log path for immediate append (so file is updated while app runs)
local _log_dir = config.logs.dir or "gameLogs"
local _session_name = "session_" .. os.date("%Y%m%d_%H%M%S") .. ".log"
local _session_path = _log_dir .. "/" .. _session_name
-- try to create directory (love.filesystem if available, else os.execute mkdir)
pcall(function()
    if type(love) == 'table' and love.filesystem and type(love.filesystem.createDirectory) == 'function' then
        pcall(function() love.filesystem.createDirectory(_log_dir) end)
    else
        -- Windows friendly mkdir, safe to ignore failures
        pcall(function() os.execute('mkdir "' .. _log_dir .. '"') end)
    end
end)

-- expose session path for other tools and enable immediate write by default (configurable)
globalFunction.log = globalFunction.log or {}
globalFunction.log._sessionPath = _session_path
globalFunction.log.immediateWrite = (config.logs.immediateWrite == nil) and true or config.logs.immediateWrite

--[[ Icon Bare status load (use resource cache) ]]
local shield = res.image('img/Actor/Enemy/Hub-Shield2.png')
local epineIcon = res.image('img/icon/bonus-epine-icon.png')
local bonussAttackIcon = res.image('img/icon/bonuss-attack-icon.png')

local lifeBar = {
    red = res.image('img/Actor/Enemy/HudLifeEnemy.png'),
    bleu = res.image('img/Actor/hero/HudLifeHero.png'),
    color_red = { 1, 0, 0 },
    color_bleu = { 0, 0, 1 },

}

----------------------------------------------------------------
-- LERP STABLE (corrige les tremblements / oscillations)
-- a, b: tables {x, y}
-- t: «vitesse» (ex: 10). On le multiplie par Delta (dt global) si dispo
----------------------------------------------------------------
globalFunction.lerp = function(a, b, t)
    -- sécurité des tables
    a.x      = a.x or 0; a.y = a.y or 0
    b.x      = b.x or 0; b.y = b.y or 0

    local dt = (rawget(_G, "Delta") or 0.016)
    local k  = (t or 10) * dt
    if k > 1 then k = 1 end

    -- epsilon pour arrêter proprement sans jitter
    local EPS = 0.5
    local moved = false

    -- axe X
    local dx = b.x - a.x
    if math.abs(dx) <= EPS then
        if a.x ~= b.x then
            a.x = b.x; moved = true
        end
    else
        a.x = a.x + dx * k
        moved = true
    end

    -- axe Y
    local dy = b.y - a.y
    if math.abs(dy) <= EPS then
        if a.y ~= b.y then
            a.y = b.y; moved = true
        end
    else
        a.y = a.y + dy * k
        moved = true
    end

    return moved
end

globalFunction.mouse = {}

--[[ Hover robuste: gère scale nil / partiel ]]
globalFunction.mouse.hover = function(x, y, width, height, scale)
    local sx, sy = 1, 1
    if type(scale) == "table" then
        sx = scale.x or scale[1] or 1
        sy = scale.y or scale[2] or 1
    end
    local function _getCursor()
        local okc, cursor = pcall(require, "my-librairie/cursor")
        if okc and cursor and cursor.get then return cursor.get() end
        return 0, 0
    end
    local mx, my = _getCursor()
    return (mx >= x and mx <= x + width * sx and my >= y and my <= y + height * sy)
end

--[[ Click «front edge» compatible avec l'existant ]]
globalFunction.mouse.click = function()
    local down = false
    local okInp, inp = pcall(require, "my-librairie/inputManager")
    if okInp and inp and inp.state then
        local s = inp.state(); down = (s == 'pressed' or s == 'held')
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            down = iface.isActionDown()
        else
            -- no provider available: default to false
            down = false
        end
    end
    if down and lockClick == false then
        lockClick = true
        return true -- front-edge (press)
    elseif (not down) and lockClick == true then
        -- fin du clic : on relâche le verrou mais on ne renvoie RIEN
        lockClick = false
        return nil -- (évite de renvoyer false)
    end
    return nil
end

-- (Optionnel) États de clic si besoin plus tard (pressed/held/released/idle)
globalFunction.mouse.state = function()
    local down = false
    local okInp, inp = pcall(require, "my-librairie/inputManager")
    if okInp and inp and inp.state then
        local s = inp.state()
        if s == 'pressed' or s == 'held' then down = true end
    else
        local okI, iface = pcall(require, "my-librairie/inputInterface")
        if okI and iface and iface.isActionDown then
            down = iface.isActionDown()
        else
            down = false
        end
    end
    if down and not lockClick then
        lockClick = true
        return "pressed"
    elseif down and lockClick then
        return "held"
    elseif (not down) and lockClick then
        lockClick = false
        return "released"
    else
        return "idle"
    end
end
--[[
    Just pressed mouse button (front-edge)
    Renvoie true uniquement lors de la première pression
]]
globalFunction.mouse.justPressed = function()
    local s = globalFunction.mouse.state()
    return s == "pressed"
end

--[[
    Just released mouse button (front-edge)
    Renvoie true uniquement lors de la première relâche
]]
globalFunction.mouse.justReleased = function()
    local s = globalFunction.mouse.state()
    return s == "released"
end

--[[ End Turn hotkeys
    E ou Return ou Space pendant le tour joueur.
]]
globalFunction.endTurnHotkeys = function()
    if _G.Tour ~= 'player' then return end
    if love.keyboard.isDown('e') or love.keyboard.isDown('return') or love.keyboard.isDown('space') then
        if Transition and Transition.requestEndTurn then
            Transition.requestEndTurn()
        end
    end
end

--[[ Draw Life bar status ]]
function globalFunction.drawLifeBarStatus(p_actor, p_Colorbar)
    if type(p_actor) ~= 'table' or type(p_actor.state) ~= 'table' then return end
    local maxLife = tonumber(p_actor.state.maxLife) or 1
    if maxLife <= 0 then maxLife = 1 end
    local life     = math.max(0, math.min(tonumber(p_actor.state.life) or 0, maxLife))

    local color    = lifeBar.color_red
    local colorBar = 'red'
    if p_Colorbar == "bleu" then
        colorBar = p_Colorbar
        color = lifeBar.color_bleu
    end

    local lifeBarConfig = p_actor.lifeBarConfig
    if not lifeBarConfig then
        local baseX = (p_actor.vector2 and p_actor.vector2.x) or 0
        local baseY = (p_actor.vector2 and p_actor.vector2.y) or 0
        lifeBarConfig = {
            x = baseX,
            y = baseY,
            w = p_actor.width or 0,
            h = p_actor.height or 0,
            position = {
                x = baseX + 25,
                y = baseY - 50
            },
            size = {
                w = 336,
                h = 10
            }
        }
    end

    local vx = lifeBarConfig.x or 0
    local vy = lifeBarConfig.y or 0
    local w = lifeBarConfig.w or 0
    local h = lifeBarConfig.h or 0
    local position = lifeBarConfig.position or { x = vx, y = vy }

    -- compute target draw width (safe parentheses)
    local targetW = (lifeBarConfig.size and lifeBarConfig.size.w) or 336
    local targetH = (lifeBarConfig.size and lifeBarConfig.size.h) or 10
    local drawW = math.max(0, targetW * (life / maxLife))

    love.graphics.setColor(color)
    love.graphics.rectangle('fill', position.x, position.y + 4, drawW, targetH)
    love.graphics.setColor(1, 1, 1)

    -- draw the life bar image scaled to target size (safe-get dimensions)
    local img = lifeBar[colorBar]
    local imgW, imgH = 1, 1
    if img and type(img.getDimensions) == 'function' then
        local ok, iw, ih = pcall(img.getDimensions, img)
        if ok and iw and ih then imgW, imgH = iw, ih end
    end
    local newScale = { w = targetW / math.max(1, imgW), h = targetH / math.max(1, imgH) }
    if img then pcall(function() love.graphics.draw(img, position.x, position.y, 0, newScale.w, newScale.h) end) end

    love.graphics.print(life .. '/' .. maxLife, vx + (w / 1.8), vy - 48)

    drawBonus(p_actor, color, position)
end

--[[ Draw bonus (shield, épine, bonus-attack) ]]
function drawBonus(p_actor, color, position)
    if not (p_actor and p_actor.state) then return end
    -- Shield icon
    if (p_actor.state.shield or 0) > 0 then
        love.graphics.draw(shield, position.x - 30, position.y - 20, 0, 1.5, 1.5)
        local oldFont = love.graphics.getFont()
        local f40 = res.font(40)
        love.graphics.setFont(f40)
        love.graphics.print(p_actor.state.shield, position.x - 12, position.y - 10)
        love.graphics.setFont(oldFont)
    end
    -- Epine icon
    if (p_actor.state.epine or 0) > 0 then
        love.graphics.draw(epineIcon, position.x + 30, position.y + 20, 0, 1.5, 1.5)
    end
    -- Bonus attack icon
    if (p_actor.state.degat or 0) > 0 then
        love.graphics.draw(bonussAttackIcon, position.x + 80, position.y + 20, 0, 1.5, 1.5)
    end
end

--[[ Deep copy table (clone) ]
    Renvoie une copie profonde d'une table
    @param orig La table d'origine à copier
    @param seen Une table pour suivre les références circulaires (optionnelle)
    @return Une nouvelle table clonée
]]
local function _table_clone(orig, seen)
    if type(orig) ~= "table" then
        return orig
    end
    if seen and seen[orig] then
        return seen[orig]
    end

    local copy = {}
    seen = seen or {}
    seen[orig] = copy

    for k, v in pairs(orig) do
        copy[_table_clone(k, seen)] = _table_clone(v, seen)
    end

    return setmetatable(copy, getmetatable(orig))
end

-- Expose clone via module
globalFunction.clone = _table_clone

-- Ensure legacy code using table.clone still works: provide a safe fallback
if type(table) == 'table' and type(table.clone) ~= 'function' then
    table.clone = _table_clone
end

-- Try to load centralized input manager and delegate mouse helpers to it.
local ok, input = pcall(require, "my-librairie/inputManager")
if ok and type(input) == 'table' then
    globalFunction.mouse = globalFunction.mouse or {}
    globalFunction.mouse.hover = input.hover
    globalFunction.mouse.click = input.click
    globalFunction.mouse.state = input.state
    globalFunction.mouse.justPressed = input.justPressed
    globalFunction.mouse.justReleased = input.justReleased
    globalFunction.endTurnHotkeys = input.endTurnHotkeys
end

-- Aliases globaux pour compat (certains scripts utilisent "myFonction")
rawset(_G, "globalFunction", globalFunction)
rawset(_G, "myFunction", globalFunction)
rawset(_G, "myFonction", globalFunction)

-- ============================
-- Centralized logging utility
-- ============================
globalFunction.log = {}

-- config
globalFunction.log.maxEntries = config.logs.maxEntries or 200
globalFunction.log.show = false -- toggle on/off
globalFunction.log.entries = {} -- circular buffer

local LEVEL = { OK = 0, INFO = 1, WARN = 2, ERROR = 3 }
local LEVEL_NAME = { [0] = "OK", [1] = "INFO", [2] = "WARN", [3] = "ERROR" }
local LEVEL_COLOR = {
    [0] = { 1, 1, 1 },       -- OK = white
    [1] = { 0.6, 0.9, 0.6 }, -- INFO = greenish
    [2] = { 1, 0.65, 0 },    -- WARN = orange
    [3] = { 1, 0.2, 0.2 }    -- ERROR = red
}

local function _pushLog(level, text)
    local info = debug.getinfo(3, "nSl") or {}
    local src = tostring(info.short_src or info.source or "?")
    local func = tostring(info.name or "?")
    local entry = { t = os.time(), level = level, text = tostring(text), src = src, func = func }
    table.insert(globalFunction.log.entries, entry)
    -- trim
    if #globalFunction.log.entries > globalFunction.log.maxEntries then
        table.remove(globalFunction.log.entries, 1)
    end
    -- also print to console for convenience
    local prefix = string.format("[%s][%s:%s] ", LEVEL_NAME[level], src, func)
    if level == LEVEL.ERROR then
        print(prefix .. "ERROR: " .. tostring(text))
    else
        print(prefix .. tostring(text))
    end
    -- Immediate append to session file if configured (so logs are readable while app runs)
    if globalFunction.log and globalFunction.log.immediateWrite and globalFunction.log._sessionPath then
        local okf, fh = pcall(function()
            return io.open(globalFunction.log._sessionPath, "a")
        end)
        if okf and fh then
            pcall(function()
                local timestr = os.date('%Y-%m-%d %H:%M:%S', entry.t)
                local line = string.format("%s [%s] [%s:%s] %s\n", timestr, LEVEL_NAME[level], src, func, tostring(text))
                fh:write(line)
                fh:close()
            end)
        end
    end
end

function globalFunction.log.ok(text) _pushLog(LEVEL.OK, text) end

function globalFunction.log.info(text) _pushLog(LEVEL.INFO, text) end

function globalFunction.log.warn(text) _pushLog(LEVEL.WARN, text) end

function globalFunction.log.error(text) _pushLog(LEVEL.ERROR, text) end

function globalFunction.log.clear() globalFunction.log.entries = {} end

function globalFunction.log.toggle() globalFunction.log.show = not globalFunction.log.show end

-- Draw logs on screen (call from love.draw when desired)
function globalFunction.drawLogs(opts)
    opts = opts or {}
    if not globalFunction.log.show then return end

    -- prefer game-space resolution when available (makes the panel readable)
    local screen = rawget(_G, 'screen')
    local gw = (screen and screen.gameReso and screen.gameReso.width) or 800
    local gh = (screen and screen.gameReso and screen.gameReso.height) or 600

    local x = opts.x or 10
    local y = opts.y or 40
    local w = opts.w or (gw - 20)
    local h = opts.h or math.min(300, gh - y - 20)
    local bg = opts.bg or { 0, 0, 0, 0.6 }

    love.graphics.push()
    -- background
    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", x - 6, y - 6, w + 12, h + 12)
    love.graphics.setColor(1, 1, 1)

    -- cached font for logs (avoid re-creating every frame)
    globalFunction._logFont = globalFunction._logFont or res.font(16)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(globalFunction._logFont)

    local lineH = opts.lineHeight or globalFunction._logFont:getHeight()
    local maxLines = math.floor(h / lineH)
    local start = math.max(1, #globalFunction.log.entries - maxLines + 1)
    local idx = 0
    for i = start, #globalFunction.log.entries do
        idx = idx + 1
        local e = globalFunction.log.entries[i]
        local col = LEVEL_COLOR[e.level] or { 1, 1, 1 }
        love.graphics.setColor(col)
        local timestr = os.date('%H:%M:%S', e.t)
        local text = string.format("%s [%s:%s] %s", timestr, e.src, e.func, e.text)
        love.graphics.print(text, x, y + (idx - 1) * lineH)
    end

    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.pop()
end

-- Export logs to a file (returns true on success)
function globalFunction.log.exportToFile(path)
    -- ensure target directory exists
    local dir = config.logs.dir or "gameLogs"
    pcall(function()
        if type(love) == 'table' and love.filesystem and type(love.filesystem.createDirectory) == 'function' then
            love.filesystem.createDirectory(dir)
        end
    end)

    path = path or (dir .. "/" .. "game_logs_" .. os.date("%Y%m%d_%H%M%S") .. ".log")

    -- prune old files in gameLogs: keep at most 10 files, else delete the oldest half
    local function pruneGameLogs()
        -- try os.* functions first
        local ok, files
        ok, files = pcall(function()
            local t = {}
            for fname in io.popen('dir "' .. dir .. '" /b 2>nul'):lines() do
                table.insert(t, fname)
            end
            return t
        end)
        if not ok or not files then
            -- fallback: try love.filesystem (may be in sandbox)
            if type(love) == 'table' and love.filesystem and type(love.filesystem.getDirectoryItems) == 'function' then
                local succ, items = pcall(love.filesystem.getDirectoryItems, dir)
                if succ and type(items) == 'table' then files = items end
            end
        end
        if not files or #files == 0 then return end

        -- sort by name (timestamp suffix assumed) to get oldest first
        table.sort(files)
        local maxFiles = config.logs.maxFiles or 10
        if #files > maxFiles then
            local toRemove = math.floor(#files / 2)
            for i = 1, toRemove do
                local fname = files[i]
                local fpath = dir .. "/" .. fname
                pcall(function()
                    -- try normal io removal first
                    os.remove(fpath)
                end)
                -- try love.filesystem removal as fallback
                if type(love) == 'table' and love.filesystem and type(love.filesystem.remove) == 'function' then
                    pcall(function() love.filesystem.remove(fpath) end)
                end
            end
        end
    end

    pruneGameLogs()

    -- try normal io.open first
    local ok, f = pcall(function() return io.open(path, "w") end)
    if not ok or not f then
        -- fallback to love.filesystem.write when available (useful in sandboxed runtimes)
        if type(love) == 'table' and love.filesystem and type(love.filesystem.write) == 'function' then
            local content = {}
            for i = 1, #globalFunction.log.entries do
                local e = globalFunction.log.entries[i]
                local timestr = os.date('%Y-%m-%d %H:%M:%S', e.t)
                local line = string.format("%s [%s] [%s:%s] %s\n", timestr, LEVEL_NAME[e.level], e.src, e.func, e.text)
                content[#content + 1] = line
            end
            local joined = table.concat(content)
            local succ, serr = pcall(function() love.filesystem.write(path, joined) end)
            if succ then
                print("[LOG] exported " .. tostring(#globalFunction.log.entries) .. " entries to " .. tostring(path))
                return true
            else
                print("[LOG] cannot write to file via love.filesystem: " .. tostring(serr))
                return false
            end
        end
        print("[LOG] cannot open file for writing: " .. tostring(path))
        return false
    end

    for i = 1, #globalFunction.log.entries do
        local e = globalFunction.log.entries[i]
        local timestr = os.date('%Y-%m-%d %H:%M:%S', e.t)
        local line = string.format("%s [%s] [%s:%s] %s\n", timestr, LEVEL_NAME[e.level], e.src, e.func, e.text)
        f:write(line)
    end
    f:close()
    print("[LOG] exported " .. tostring(#globalFunction.log.entries) .. " entries to " .. tostring(path))
    return true
end

globalFunction.tstr = function(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    local parts = {}
    for k, v in pairs(tbl) do
        parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end
globalFunction.safecall = function(fn, ...)
    local status, result = pcall(fn, ...)
    if not status then
        globalFunction.log.error("Error in safecall: " .. tostring(result))
    end
    return result
end

-- =====================================================================
-- MATH UTILITIES (éviter la duplication de patterns math courants)
-- =====================================================================

-- Clamp: force une valeur dans un intervalle [min, max]
globalFunction.clamp = function(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Map: transforme une valeur d'un intervalle à un autre
-- mapRange(5, 0, 10, 0, 100) -> 50 (5 sur [0,10] devient 50 sur [0,100])
globalFunction.mapRange = function(value, inMin, inMax, outMin, outMax)
    local inRange = inMax - inMin
    if inRange == 0 then return outMin end
    return outMin + (value - inMin) * (outMax - outMin) / inRange
end

-- Lerp numérique simple (pour valeurs simples, pas tables)
globalFunction.lerpNum = function(a, b, t)
    return a + (b - a) * math.max(0, math.min(1, t))
end

-- Clamp delta time: protège contre les valeurs nil et limite les gros dt
-- Utile pour éviter les bugs avec dt nil et limiter les sauts temporels
globalFunction.clampDt = function(dt)
    if not dt or type(dt) ~= "number" then return 0 end
    return (dt > 0.05) and 0.05 or dt
end

-- Progression sécurisée (évite division par zéro)
globalFunction.progress = function(current, max)
    if max <= 0 then return 0 end
    return math.max(0, math.min(1, current / max))
end

-- Distance rapide sans racine carrée (pour comparaisons)
globalFunction.distSqr = function(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return dx * dx + dy * dy
end

-- =====================================================================
-- TABLE UTILITIES (helpers courants pour manipuler les tables)
-- =====================================================================

-- Vérifie si une table contient une valeur
globalFunction.contains = function(tbl, value)
    if type(tbl) ~= "table" then return false end
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

-- Trouve l'index d'une valeur dans une table array
globalFunction.indexOf = function(tbl, value)
    if type(tbl) ~= "table" then return nil end
    for i = 1, #tbl do
        if tbl[i] == value then return i end
    end
    return nil
end

-- Filtre une table avec un prédicat
globalFunction.filter = function(tbl, predicate)
    local result = {}
    if type(tbl) ~= "table" then return result end
    for i, v in ipairs(tbl) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

-- Map une table avec une fonction de transformation
globalFunction.map = function(tbl, transform)
    local result = {}
    if type(tbl) ~= "table" then return result end
    for i, v in ipairs(tbl) do
        result[i] = transform(v, i)
    end
    return result
end

-- =====================================================================
-- STRING UTILITIES (helpers pour manipulation de chaînes)
-- =====================================================================

-- Split une chaîne sur un délimiteur
globalFunction.split = function(str, delimiter)
    if type(str) ~= "string" then return {} end
    delimiter = delimiter or "%s"
    local result = {}
    for part in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        table.insert(result, part)
    end
    return result
end

-- Trim les espaces en début/fin
globalFunction.trim = function(str)
    if type(str) ~= "string" then return "" end
    return str:match("^%s*(.-)%s*$")
end

-- Pad une chaîne à gauche ou droite
globalFunction.pad = function(str, length, char, right)
    str = tostring(str)
    char = char or " "
    local padding = string.rep(char, math.max(0, length - #str))
    return right and (str .. padding) or (padding .. str)
end

-- =====================================================================
-- VALIDATION UTILITIES (helpers pour vérification de données)
-- =====================================================================

-- Vérifie si une valeur est un nombre valide
globalFunction.isNumber = function(value)
    return type(value) == "number" and value == value -- exclut NaN
end

-- Vérifie si une table a des champs requis
globalFunction.hasFields = function(tbl, fields)
    if type(tbl) ~= "table" then return false end
    for _, field in ipairs(fields) do
        if tbl[field] == nil then return false end
    end
    return true
end

-- Retourne une valeur par défaut si la valeur est nil
globalFunction.default = function(value, defaultValue)
    return value ~= nil and value or defaultValue
end

-- auto init log entry
globalFunction.log.info("Logger initialized")

return globalFunction
