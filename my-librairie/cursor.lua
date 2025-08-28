-- Central cursor helper
local M = {}

function M.get()
    -- prefer inputInterface if present
    local ok, iface = pcall(require, "my-librairie/inputInterface")
    if ok and iface and iface.getCursor then
        local c = iface.getCursor(); return c.x or 0, c.y or 0
    end

    -- fallback to screen.mouse if available
    local screen = rawget(_G, "screen")
    if screen and screen.mouse and screen.mouse.X then return screen.mouse.X, screen.mouse.Y end

    -- fallback to love.mouse.getPosition via pcall
    local ok2, x, y = pcall(function() return love.mouse.getPosition() end)
    if ok2 then return x or 0, y or 0 end

    return 0, 0
end

return M
