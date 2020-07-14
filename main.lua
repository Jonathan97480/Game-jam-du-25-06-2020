-- ***********Config Window Game*************
love.window.setTitle("Tactique Cards")

-- REQUIRE System 
json = require("my-librairie/json");
hud = require("my-librairie/hud/hudManager");
card = require("my-librairie/card-librairie/cardFunctionAcces");
screen = require("my-librairie/responsive");
scene = require("my-librairie/sceneManager");
effect = require("ressources/effect");
myFonction = require("my-librairie/myFunction");

-- Returns the distance between two points.
function math.dist(x1, y1, x2, y2)

    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5

end

-- VARIABLES
--[[ global ]]
delta = 0;
DefaultColor = love.graphics.getColor();
--[[ Local ]]

-- INIT
function love.load()

    scene.load(dt);
    

end

-- UPDATE
function love.update(dt)

    delta = dt
    scene.update(dt);
    screen.UpdateRatio(dt);

    effect.update();
    if love.keyboard.isDown('p') then
        card.positioneHand();
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
