local Enemies = {
    curentEnemy = {},
    listeEnemies = {},

    timerAttack = 1,
    timerDefautl = 1,
    isAttack = true
};
local shield = love.graphics.newImage('img/Actor/Enemy/Hub-Shield2.png');
-- REQUIRE
local actor = require("ActorScripts/actorManager");
local ia = require("ActorScripts/Enemy/ia");
-- VARIABLE

-- DECLARATION ENEMY

-- LOAD
function Enemies.load()

    local Enemy = {};
    Enemies.curentEnemy = {};

    for i = 1, 3 do

        local Enemy = actor.create('Enemy-' .. i, {
            idle = {
                'img/Actor/Enemy/Enemy-' .. i .. '.png'
            }
        }, {
            x = 1261,
            y = 740
        });

        Enemy.state.life = math.random(50, 81);
        Enemy.state.maxLife = Enemy.state.life;

        table.insert(Enemies.listeEnemies, Enemy);
    end
    --[[ Ramdon select Enemy ]]
    Enemies.curentEnemy = Enemies.listeEnemies[math.random(1, #Enemies.listeEnemies)];
    Enemies.curentEnemy.state.chancePassTour = 0;
end

function Enemies.next()

    Enemies.rezet();
    Enemies.curentEnemy = Enemies.listeEnemies[math.random(1, #Enemies.listeEnemies)];

end
function Enemies.rezet()
    Enemies.curentEnemy.state.life = Enemies.curentEnemy.state.maxLife;
    Enemies.curentEnemy.state.shield = 0;
    Enemies.curentEnemy.state.chancePassTour = 0;
    Enemies.curentEnemy.state.dead = false;

end
-- UPDATE
function Enemies.update(dt)
    if Tour == 'Enemy' then
        ia.playTour();
    end
end



-- DRAW
function Enemies.draw()

    local animation = Enemies.curentEnemy.animation[Enemies.curentEnemy.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], Enemies.curentEnemy.vector2.x, Enemies.curentEnemy.vector2.y);

    end
    -- Health Bar 
    myFonction.drawLifeBarStatus(Enemies.curentEnemy,'red');
end


return Enemies;
