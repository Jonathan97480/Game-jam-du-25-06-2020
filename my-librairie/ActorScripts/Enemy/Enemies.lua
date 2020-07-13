local Enemies = {

    curentEnemy = {},
    listeEnemies = {},

    timerAttack = 1,
    timerDefautl = 1,
    isAttack = true

};

-- REQUIRE
local actor = require("my-librairie/ActorScripts/actorManager");
local ia = require("my-librairie/ActorScripts/Enemy/ia");
-- VARIABLE

-- DECLARATION ENEMY

-- LOAD
function Enemies.load()

    local Enemy = {};
    Enemies.curentEnemy = {};

    for i = 1, 4 do

        local Enemy = actor.create('Enemy-' .. i, {
            idle = {
                'img/Actor/Enemy/Enemy-' .. i .. '.png'
            }
        }, {
            x = 1261,
            y = 400
        });

        Enemy.state.life = math.random(50, 81);
        Enemy.state.maxLife = Enemy.state.life;

        table.insert(Enemies.listeEnemies, Enemy);
    end
    --[[ Ramdon select Enemy ]]
    local NewsEnemy = math.random(1, #Enemies.listeEnemies);
    Enemies.curentEnemy = Enemies.listeEnemies[NewsEnemy];
    table.remove(Enemies.listeEnemies, NewsEnemy);
end

function Enemies.next()

    Enemies.curentEnemy = {}

    if (#Enemies.listeEnemies > 0) then
        local NewsEnemy =  #Enemies.listeEnemies;
        Enemies.curentEnemy = Enemies.listeEnemies[NewsEnemy];
        table.remove(Enemies.listeEnemies, NewsEnemy);
    else
        --[[ On definie la partie Comme terminer  ]]
        Tour = 'PartieEnd'
        print(Tour);
    end

end

-- UPDATE
function Enemies.update(dt)
    if Tour == 'Enemy' then

        ia.playTour();
    end
end

-- DRAW
function Enemies.draw()
    if Enemies.curentEnemy ~= nil and Enemies.curentEnemy.curentAnimation ~= nil then

        local animation = Enemies.curentEnemy.animation[Enemies.curentEnemy.curentAnimation];

        for i = 1, #animation do

            love.graphics.draw(animation[i], Enemies.curentEnemy.vector2.x, Enemies.curentEnemy.vector2.y);

        end
        -- Health Bar 
        myFonction.drawLifeBarStatus(Enemies.curentEnemy, 'red');

    end
end

return Enemies;
