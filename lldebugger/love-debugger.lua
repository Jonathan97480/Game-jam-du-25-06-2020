-- https://github.com/slembcke/love-debugger/blob/master/love-debugger.lua
-- Version adaptée pour intégration directe

local dbg = require 'debugger'
dbg.auto_where = 2

dbg.enable_color()

local gfx = love.graphics
local dbg_cursor = { x = 0, y = 0 }
local dbg_color = { 1, 1, 1, 1 }
local dbg_font = gfx.newFont("VeraMono.ttf", 12)
local dbg_canvas = gfx.newCanvas(gfx.getDimensions())
dbg_canvas:renderTo(function() gfx.clear(0, 0, 0, 1) end)

function dbg_render_to(canvas, func)
    gfx.push(); gfx.origin()
    local _canvas = gfx.getCanvas()
    local _font = gfx.getFont()
    local _color = { gfx.getColor() }
    gfx.setCanvas(canvas)
    gfx.setFont(dbg_font)
    gfx.setColor(unpack(dbg_color))
    func()
    gfx.setCanvas(_canvas)
    gfx.setFont(_font)
    gfx.setColor(unpack(_color))
    gfx.pop()
end

local function newline()
    dbg_cursor.x = 0
    local line_height = dbg_font:getHeight()
    dbg_cursor.y = dbg_cursor.y + line_height
    if dbg_cursor.y > dbg_canvas:getHeight() - line_height then
        local canvas = gfx.newCanvas(dbg_canvas:getDimensions())
        gfx.setCanvas(canvas)
        gfx.clear(0, 0, 0, 1)
        gfx.setColor(1, 1, 1, 1)
        gfx.draw(dbg_canvas, 0, -line_height)
        dbg_canvas:release()
        dbg_canvas = canvas
        dbg_cursor.y = dbg_cursor.y - line_height
    end
end

local function dbg_putc(char)
    if char == "\n" then
        newline()
    else
        local width = dbg_font:getWidth(char)
        if dbg_cursor.x + width > dbg_canvas:getWidth() then
            newline()
        end
        gfx.print(char, dbg_cursor.x, dbg_cursor.y)
        dbg_cursor.x = dbg_cursor.x + width
    end
end

function dbg.write(str)
    dbg_render_to(dbg_canvas, function()
        local i = 1; while i <= #str do
            local char = str:sub(i, i)
            if char == string.char(27) then
                i = i + 1 -- skip color codes
            else
                dbg_putc(char)
            end
            i = i + 1
        end
    end)
end

function love.errorhandler(msg)
    love.errhand(msg)
    dbg.error(msg, 3)
end

return dbg
