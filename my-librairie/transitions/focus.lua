local M = { durationOut = 0.5, durationIn = 0.6, maskInput = true }
local function easeInOutQuad(x) return x < 0.5 and 2 * x * x or 1 - ((-2 * x + 2) ^ 2) / 2 end
M.easingOut = easeInOutQuad; M.easingIn = easeInOutQuad
function M.drawOut(p, ctx) love.graphics.setColor(0, 0, 0, p * 0.85); love.graphics.rectangle("fill", 0, 0, ctx.w, ctx.h) end
function M.drawIn(p, ctx) love.graphics.setColor(0, 0, 0, (1 - p) * 0.85); love.graphics.rectangle("fill", 0, 0, ctx.w, ctx.h) end
return M
