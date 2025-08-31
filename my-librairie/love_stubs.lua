-- my-librairie/love_stubs.lua
-- Minimal LÖVE API stubs to help the Lua language server understand signatures.
-- These functions are no-ops and only provide signatures for static analysis.
love = love or {}
love.graphics = love.graphics or {}

function love.graphics.setColor(r, g, b, a) end

function love.graphics.getColor() return 1, 1, 1, 1 end

function love.graphics.rectangle(mode, x, y, w, h) end

function love.graphics.print(text, x, y) end

function love.graphics.circle(mode, x, y, radius) end

function love.graphics.line(...) end

function love.graphics.getFont() end

function love.graphics.setFont(f) end

function love.mouse.getX() return 0 end

function love.mouse.getY() return 0 end

function love.mouse.getPosition() return 0, 0 end

-- audio stubs
love.audio = love.audio or {}
function love.audio.newSource(path, type) return nil end

-- image/font helpers
function love.graphics.newImage(path) return nil end

function love.graphics.newFont(pathOrSize, size) return nil end

return love
