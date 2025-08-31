-- Central cursor helper
local M = {}

function M.get()
    local input = _G.inputInterface or require("my-librairie/managers/inputInterface") or nil

    if input == nil or input.getCursor == nil then
        _G.globalFunction.log.error("[cursor.lua] Cursor input interface is not available")
        return 0, 0
    end
    local m = input.getCursor()
    return m.x, m.y
end

return M
