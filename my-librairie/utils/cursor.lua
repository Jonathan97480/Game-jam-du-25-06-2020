-- Central cursor helper
local M = {}

function M.get()
    local input = _G.inputInterface or require("my-librairie/managers/inputInterface") or nil
    local _globalFunction = _G.globalFunction or require("my-librairie/utils/globalFunction") or nil

    if not input then
        _globalFunction.log.error("[cursor.lua] Cursor input interface is not available")
        return 0, 0
    end

    if input == nil or input.getCursor == nil then
        _globalFunction.log.error("[cursor.lua] Cursor input interface is not available")
        return 0, 0
    end

    local m = input.getCursor()
    return m.x, m.y
end

return M
