-- my-librairie/card-librairie/ui/ux.lua
local Common = require("my-librairie/card-librairie/core/common")
local screen = rawget(_G, "screen") or require("my-librairie/responsive")
local function getCard() return rawget(_G, "Card") end
local function _safeRequire(name)
    local ok, mod = pcall(require, name)
    if ok then return mod end
    return nil
end
local myFonction = rawget(_G, "myFonction") or _safeRequire("my-librairie/myFunction")

local M = {}

local function _mousePos()
    local mx = (screen and screen.mouse and screen.mouse.X) or
        (love and love.mouse and ({ love.mouse.getPosition() })[1]) or 0
    local my = (screen and screen.mouse and screen.mouse.Y) or
        (love and love.mouse and ({ love.mouse.getPosition() })[2]) or 0
    return mx, my
end

local function _hoverRect(x, y, w, h, scale)
    local mx, my = _mousePos()
    local sx = (type(scale) == "table" and (scale.x or 1)) or 1
    local sy = (type(scale) == "table" and (scale.y or 1)) or 1
    local ww, hh = (w or 0) * sx, (h or 0) * sy
    return mx >= x and mx <= x + ww and my >= y and my <= y + hh
end

local function _justClicked(isDown, wasDown)
    return (not isDown) and wasDown
end

local function _lerpTable(vec2, target, speed, dt)
    local a = math.min(1, (dt or 0.016) * (speed or 10))
    vec2.x = vec2.x + (target.x - vec2.x) * a
    vec2.y = vec2.y + (target.y - vec2.y) * a
end

function M.UX_hover(x, y, w, h, scale)
    if myFonction and myFonction.mouse and myFonction.mouse.hover then
        return myFonction.mouse.hover(x, y, w, h, scale)
    end
    return _hoverRect(x, y, w, h, scale)
end

function M.UX_click(isDown, wasDown)
    if myFonction and myFonction.mouse and myFonction.mouse.click then
        return myFonction.mouse.click()
    end
    return _justClicked(isDown, wasDown)
end

function M.UX_lerp(vec, target, speed, dt)
    if myFonction and myFonction.lerp then
        return myFonction.lerp(vec, target, speed)
    end
    return _lerpTable(vec, target, speed, dt)
end

function M.isMouseOverHUD()
    local hud = rawget(_G, "hud")
    local mx, my = _mousePos()

    if hud then
        if type(hud.isMouseOver) == "function" then
            local ok, r = pcall(hud.isMouseOver, mx, my)
            if ok and r ~= nil then return r and true or false end
        end
        if type(hud.hitTest) == "function" then
            local ok, r = pcall(hud.hitTest, mx, my)
            if ok and r ~= nil then return r and true or false end
        end
        if type(hud.bounds) == "table" then
            local function inRect(ptx, pty, r)
                return ptx >= (r.x or 0) and ptx <= (r.x or 0) + (r.w or 0)
                    and pty >= (r.y or 0) and pty <= (r.y or 0) + (r.h or 0)
            end
            if hud.bounds.x then
                return inRect(mx, my, hud.bounds)
            else
                for _, r in ipairs(hud.bounds) do
                    if inRect(mx, my, r) then return true end
                end
            end
        end
    end

    local R = rawget(_G, "HUD_ACTIVE_RECT")
    local function inRect(ptx, pty, r)
        return ptx >= (r.x or 0) and ptx <= (r.x or 0) + (r.w or 0)
            and pty >= (r.y or 0) and pty <= (r.y or 0) + (r.h or 0)
    end
    if type(R) == "table" then
        if R.x then
            return inRect(mx, my, R)
        else
            for _, r in ipairs(R) do
                if inRect(mx, my, r) then return true end
            end
        end
    end

    local fallbackH = rawget(_G, "HUD_FALLBACK_HEIGHT") or 220
    return my >= (screen.gameReso.height - fallbackH)
end

return M
