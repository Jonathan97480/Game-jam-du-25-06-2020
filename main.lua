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
dt = 0.07;
effect = require("ressources/effect");
lerp = require("my-librairie/lerp");
-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
-- VARIABLES

-- INIT
function love.load (  )

    print(dt);
    scene.load(dt);

end

-- UPDATE
function love.update()

    screen.UpdateRatio();
    scene.update();

end

-- DRAW
function love.draw()

    love.graphics.push()
    love.graphics.scale(screen.ratioScreen.width, screen.ratioScreen.height)
  
    scene.draw();
    effect.draw();
    love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    love.graphics.pop()

end
