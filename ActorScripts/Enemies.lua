Enemies = {};

-- REQUIRE
local actor = require("ActorScripts/actorManager");

-- VARIABLE

-- DECLARATION ENEMY
Enemies = actor.create('Glob', {
    idle = {
        'img/Actor/Enemy/enemy.png'
    }
}, {
    x = 1261,
    y = 450
});
Enemies.state.life = 100;
-- LOAD
function Enemies.load()

end

-- UPDATE
function Enemies.update()

end

-- DRAW
function Enemies.draw()

    local animation = Enemies.animation[Enemies.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], Enemies.vector2.x, Enemies.vector2.y);

    end
    -- BARE DE VIE 
    love.graphics.setColor(0, 0, 1);
    local centerBar = Enemies.vector2.x + ((Enemies.width / 2) - (Enemies.state.life));
    love.graphics.rectangle('fill', centerBar, Enemies.vector2.y + Enemies.height, 3 * Enemies.state.life, 10);
    love.graphics.setColor(1, 1, 1);
    love.graphics.print(Enemies.state.life .. '/' .. Enemies.state.maxLife, Enemies.vector2.x + (Enemies.width / 1.8),
    Enemies.vector2.y + (Enemies.height - 8));

end
return Enemies;
