-- Debug Log Enable
io.stdout:setvbuf("no")
if arg[#arg] == "-debug" then
    require("mobdebug").start()
end

-- ***********Config Window Game*************
love.window.setTitle("Tactique Cards")
love.window.setFullscreen(false)

-- REQUIRE
hudGameplay = require("my-librairie/hud");
cardeGenerator = require("my-librairie/cardeGenerator");
screen = require("my-librairie/responsive");
scene = require("my-librairie/sceneManager");
delta = 0;
effect = require("ressources/effect");
lerp = require("my-librairie/lerp");
-- Returns the distance between two points.
function math.dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- VARIABLES
local timerTransition = 0;
-- INIT
function love.load()

    scene.load(dt);
    local a = -50;

end

-- UPDATE
function love.update(dt)

    delta = dt
    scene.update(dt);
    screen.UpdateRatio(dt);
    
    if Tour == 'transition' and timerTransition >= 1.5 then
        timerTransition = 0;
        Tour = 'player'
    elseif Tour == 'transition' then
        timerTransition = timerTransition + delta;
    end

end

-- DRAW
function love.draw()

    love.graphics.push()

    love.graphics.scale(screen.ratioScreen.width, screen.ratioScreen.height)

    scene.draw();
    effect.draw();
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)

    love.graphics.pop()

end
