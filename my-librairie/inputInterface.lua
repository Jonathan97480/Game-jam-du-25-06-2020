-- my-librairie/inputInterface.lua
-- Interface unifiée pour les entrées : souris ou manette
local I = {}

local joystick = nil
local prevAction = false
local prevMouse = false
local cursor = { x = 0, y = 0 }
local activeSource = 'mouse'
local deadzone = 0.3
local sensitivity = 800 -- pixels per second for full axis

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

function I.init()
    -- initialize cursor from screen mouse or love mouse
    if rawget(_G, "screen") and screen.mouse and screen.mouse.X then
        cursor.x, cursor.y = screen.mouse.X, screen.mouse.Y
    else
        local ok, mx, my = pcall(function() return love.mouse.getPosition() end)
        if ok and mx then cursor.x, cursor.y = mx, my end
    end
end

function I.update(dt)
    -- detect joystick
    local joysticks = {}
    local ok, list = pcall(function() return love.joystick.getJoysticks() end)
    if ok and type(list) == 'table' and #list > 0 then
        joystick = list[1]
    else
        joystick = nil
    end

    -- read axes if joystick
    local ax, ay = 0, 0
    if joystick then
        local ok2, axes = pcall(function() return { joystick:getAxes() } end)
        if ok2 and type(axes) == 'table' and #axes >= 2 then
            ax, ay = axes[1] or 0, axes[2] or 0
        else
            ax, ay = 0, 0
        end
    end

    -- if joystick moved beyond deadzone, switch to gamepad and move cursor
    if math.abs(ax) > deadzone or math.abs(ay) > deadzone then
        activeSource = 'gamepad'
        cursor.x = cursor.x + ax * sensitivity * (dt or 0.016)
        cursor.y = cursor.y + ay * sensitivity * (dt or 0.016)
    else
        -- fallback to mouse position
        local okm, mx, my = pcall(function() return love.mouse.getPosition() end)
        if okm and mx then
            -- if mouse moved significantly, switch source
            if mx ~= cursor.x or my ~= cursor.y then
                activeSource = 'mouse'
            end
            cursor.x, cursor.y = mx, my
        end
    end

    -- clamp to game resolution if available
    if rawget(_G, "screen") and screen.gameReso then
        cursor.x = clamp(cursor.x, 0, screen.gameReso.width)
        cursor.y = clamp(cursor.y, 0, screen.gameReso.height)
    end

    -- action button state
    local actionDown = false
    -- mouse primary
    local okm, mdown = pcall(function() return love.mouse.isDown(1) end)
    if okm and mdown then actionDown = actionDown or mdown end
    -- gamepad A (if available)
    if joystick then
        local okb, pressed = pcall(function()
            if joystick.isGamepad and joystick:isGamepad() and joystick.isGamepadDown then
                return joystick:isGamepadDown('a')
            end
            return false
        end)
        if okb and pressed then actionDown = actionDown or pressed end
    end

    prevAction = prevAction or false
    I._lastAction = I._lastAction or false
    I._justPressed = (actionDown and not I._lastAction)
    I._justReleased = (not actionDown and I._lastAction)
    I._lastAction = actionDown
end

function I.getCursor()
    return { x = cursor.x, y = cursor.y, source = activeSource }
end

function I.isActionDown()
    return I._lastAction or false
end

function I.justPressedAction()
    return I._justPressed or false
end

function I.justReleasedAction()
    return I._justReleased or false
end

function I.getActiveSource()
    return activeSource
end

I.init()
return I
