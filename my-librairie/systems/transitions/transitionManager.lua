local Transition = {}
local state = "IDLE"
local t = { time = 0, dur = 0, dir = "out" }
local ctx, opts, currentScript
local sceneManager = require("my-librairie/sceneManager")
local function ease(x) return x * x * (3 - 2 * x) end
local DefaultScript = {
    durationOut = 0.35,
    durationIn = 0.35,
    maskInput = true,
    easingOut = ease,
    easingIn = ease,
    drawOut = function(p, c)
        love.graphics.push("all"); love.graphics.setColor(0, 0, 0, p)
        love.graphics.rectangle("fill", 0, 0, c.w, c.h); love.graphics.pop()
    end,
    drawIn = function(p, c)
        love.graphics.push("all"); love.graphics.setColor(0, 0, 0, 1 - p)
        love.graphics.rectangle("fill", 0, 0, c.w, c.h); love.graphics.pop()
    end
}
local function getSceneScript(sceneObj)
    if sceneObj and type(sceneObj.transition) == "table" then return sceneObj.transition end
end
function Transition.isActive() return state ~= "IDLE" and state ~= "DONE" end

local function startPhase(dir)
    t.dir = dir; t.time = 0; t.dur = (dir == "out" and (currentScript.durationOut or 0.3)) or
        (currentScript.durationIn or 0.3)
    local cb = (dir == "out" and currentScript.onStartOut) or currentScript.onStartIn; if cb then pcall(cb, ctx) end
end
local function endPhase(dir)
    local cb = (dir == "out" and currentScript.onEndOut) or currentScript.onEndIn; if cb then pcall(cb, ctx) end
end
function Transition.play(options)
    opts = options or {};
    -- resolve current scene via sceneManager:top() (sceneManager.current may be nil)
    local from = nil
    if sceneManager and type(sceneManager.top) == 'function' then
        local ok, top = pcall(function() return sceneManager:top() end)
        if ok and top then from = top end
    elseif sceneManager and sceneManager.current then
        from = sceneManager.current or sceneManager:top()
    end
    ctx = {
        fromScene = from,
        toScene = opts.target,
        params = opts.params,
        w = love.graphics.getWidth(),
        h = love
            .graphics.getHeight()
    }
    currentScript = opts.script or (from and getSceneScript(from)) or DefaultScript
    state = "OUT"; startPhase("out")
    return ctx
end

function Transition.update(dt)
    if state == "IDLE" or state == "DONE" then return end
    if dt > 0.05 then dt = 0.05 end
    t.time = t.time + dt; local donePhase = t.time >= t.dur
    if state == "OUT" then
        if donePhase then
            endPhase("out"); sceneManager:switch(ctx.toScene, ctx.params)
            ctx.fromScene = nil; ctx.toScene = sceneManager.current
            currentScript = opts.script or getSceneScript(ctx.toScene) or currentScript or DefaultScript
            state = "IN"; startPhase("in")
        end
    elseif state == "IN" then
        if donePhase then
            endPhase("in"); state = "DONE"
        end
    end
end

function Transition.draw()
    if state == "IDLE" or state == "DONE" then return end
    local progress = math.min(1, t.time / math.max(0.0001, t.dur))
    if t.dir == "out" then
        local e = currentScript.easingOut or ease; local p = e(progress)
        if currentScript.drawOut then currentScript.drawOut(p, ctx) end
    else
        local e = currentScript.easingIn or ease; local p = e(progress)
        if currentScript.drawIn then currentScript.drawIn(p, ctx) end
    end
end

function Transition.maskInput() return (currentScript and currentScript.maskInput) and Transition.isActive() end

return Transition
