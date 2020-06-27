-- Debug Log Enable
io.stdout:setvbuf("no")
if arg[#arg] == "-debug" then
    require("mobdebug").start()
end

-- ***********Config Window Game*************
love.window.setTitle("Tactique Cards")
love.window.setFullscreen(false)

-- REQUIRE
screen = require("my-librairie/responsive");
cardeGenerator = require("my-librairie/cardeGenerator");
hudGameplay = require("my-librairie/hud");
local scene = require("my-librairie/sceneManager");


-- VARIABLES

-- INIT
function love.load()

    scene.load();

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

    love.graphics.pop()

end
