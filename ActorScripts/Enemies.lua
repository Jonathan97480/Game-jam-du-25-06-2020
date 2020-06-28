Enemies = {
    curentEnemy = {},
    listeEnemies = {},
    healthBar = love.graphics.newImage('img/Actor/Enemy/HudLifeEnemy.png'),
    timerAttack = 1,
    timerDefautl = 1,
    isAttack = true
};
local shield = love.graphics.newImage('img/Actor/Enemy/Hub-Shield2.png');
-- REQUIRE
local actor = require("ActorScripts/actorManager");

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
end

-- UPDATE
function Enemies.update(dt)
    if Tour == 'Enemy' then
        playTour();
    end
end

function playTour()

    local shield = math.random(1, 10);
    if Enemies.isAttack then
        if shield > 2 and shield <= 4 then
            --[[ TODO:ANIMATION GIVE SHIELD ]]
            Enemies.curentEnemy.state.armor = math.random(10, 30);
            Enemies.isAttack = false;
        else
            local degat = love.math.random(20, 30);

            if hero.actor.state.armor >= degat then

                hero.actor.state.armor = hero.actor.state.armor - degat;
                degat = 0;
            else
                degat = degat - hero.actor.state.armor;
                hero.actor.state.armor = 0;
            end
            --[[ TODO:ANIMATION DE LATTACK ]]
            effect.efect.attack.vector2.x = hero.actor.vector2.x 
            effect.efect.attack.vector2.y = hero.actor.vector2.y + (hero.actor.height/2)-40
    
            effect.efect.attack.speed =0.1;
            effect.efect.attack.isplay=true
            hero.actor.state.life = hero.actor.state.life - degat;

            if hero.actor.state.life < 0 then

                hero.actor.state.life = 0;
                hero.actor.state.dead = true;

            end

            Enemies.isAttack = false;
        end
    end
    if Enemies.timerAttack <= 0 then

        Enemies.timerAttack = Enemies.timerDefautl;
        Tour = 'Player';
        Enemies.isAttack = true;
        if (hero.actor.state.dead ~= true) then
            cardeGenerator.clearHand();
            cardeGenerator.tirage(5);
            hero.actor.state.power = 8;
        else
            --[[ TODO:ADD GAME OVER ]]
            print('Your Dead');
            -- body    
        end
        return;
    else
        Enemies.timerAttack = Enemies.timerAttack - dt;
    end

end

-- DRAW
function Enemies.draw()

    local animation = Enemies.curentEnemy.animation[Enemies.curentEnemy.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], Enemies.curentEnemy.vector2.x, Enemies.curentEnemy.vector2.y);

    end
    -- Health Bar 
    drawHealthBar();
end

function drawHealthBar()

    local healtBarPosition = {
        x = Enemies.curentEnemy.vector2.x +
            ((Enemies.curentEnemy.width / 2) - (Enemies.curentEnemy.state.maxLife / 0.5)),
        y = Enemies.curentEnemy.vector2.y + Enemies.curentEnemy.height
    }

    love.graphics.setColor(0, 0, 1);

    love.graphics.rectangle('fill', healtBarPosition.x, healtBarPosition.y + 4,
                            336 * (Enemies.curentEnemy.state.life / 100) * 1.45, 10);

    love.graphics.setColor(1, 1, 1);

    love.graphics.draw(Enemies.healthBar, healtBarPosition.x, healtBarPosition.y, 0, 1.5, 2);

    love.graphics.print(Enemies.curentEnemy.state.life .. '/' .. Enemies.curentEnemy.state.maxLife,
                        Enemies.curentEnemy.vector2.x + (Enemies.curentEnemy.width / 1.8),
                        Enemies.curentEnemy.vector2.y + (Enemies.curentEnemy.height - 8));

    if Enemies.curentEnemy.state.armor > 0 then

        love.graphics.draw(shield, healtBarPosition.x - 30, healtBarPosition.y - 20, 0, 1.5, 1.5);
        love.graphics.setNewFont(40);
        love.graphics.setColor(1, 0, 1)
        love.graphics.print(Enemies.curentEnemy.state.armor, healtBarPosition.x - 12, healtBarPosition.y - 10);
        love.graphics.setColor(1, 1, 1)
    end
end
return Enemies;
