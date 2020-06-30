hero = {};
local healthBar = love.graphics.newImage('img/Actor/hero/HudLifeHero.png');
local shield = love.graphics.newImage('img/Actor/hero/Hub-Shield2.png');
local debug = {};
local backGround = love.graphics.newImage("img/BackGround/zonedeConbat-1.png");
 hero.actor ={}

function debug.table(p_table)

    for index, value in ipairs(p_table) do

        print(index .. '/ ' .. value .. '/n');

    end
end
-- REQUIRE
local actor = require("ActorScripts/actorManager");

-- VARIABLE

-- LOAD
function hero.load()
    -- DECLARATION HERO
    hero.actor={}
    hero.actor = actor.create('jouer', {
        idle = {
            'img/Actor/hero/Hero.png'
        }
    }, {
        x = 383,
        y = 638
    });
    hero.actor.state.life = 80;
    hero.actor.state.maxLife = hero.actor.state.life;
end
function hero.rezet()
    hero.actor.state.life =  hero.actor.state.maxLife;
    hero.actor.state.armor = 0;
    hero.actor.state.power = 8;
    hero.actor.state.dead = false;
    
end
-- UPDATE
function hero.update()

end

-- DRAW
function hero.draw()

    --[[ bakcground ]]
    love.graphics.draw(backGround,0,0);

    local animation = hero.actor.animation[hero.actor.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], hero.actor.vector2.x, hero.actor.vector2.y);

    end
    -- BARE DE VIE 

    local healtBarPosition = {
        x = hero.actor.vector2.x + ((hero.actor.width / 2) - (hero.actor.state.maxLife / 0.5)),
        y = hero.actor.vector2.y + hero.actor.height
    }

    love.graphics.setColor(0, 0, 1);

    love.graphics
        .rectangle('fill', healtBarPosition.x, healtBarPosition.y + 4, 336 * (hero.actor.state.life / 100) * 1.25, 10);

    love.graphics.setColor(1, 1, 1);

    love.graphics.draw(healthBar, healtBarPosition.x, healtBarPosition.y, 0, 1.5, 2);

    love.graphics.print(hero.actor.state.life .. '/' .. hero.actor.state.maxLife, hero.actor.vector2.x + (hero.actor.width / 1.8),
                        hero.actor.vector2.y + (hero.actor.height - 8));

    if hero.actor.state.armor > 0 then

        love.graphics.draw(shield, healtBarPosition.x - 30, healtBarPosition.y - 20, 0, 1.5, 1.5);
        love.graphics.setNewFont(40);
        love.graphics.setColor(1, 0, 1)
        love.graphics.print(hero.actor.state.armor, healtBarPosition.x - 12, healtBarPosition.y - 10);
        love.graphics.setColor(1, 1, 1)
    end
    -- POWER DRAW TEXT
    hud.object.energie.value[1].text = hero.actor.state.power;

    --[[ GAME OVER ]]
    if hero.actor.state.dead ~= false then

        love.graphics.setNewFont(80);
        love.graphics.print('GAME OVER', 700, 100);
        love.graphics.setNewFont(50);
        love.graphics.print('Would you like to start over', 600, 190);
        love.graphics.setNewFont(15);

        for key, value in pairs(hud.object) do
            if key == 'btnNewPartie' or key == 'btnQuiter' then

                love.graphics.draw(value.img, value.vector2.x, value.vector2.y);
                love.graphics.setNewFont(20);

                for i, info in pairs(value.value) do

                    if info ~= nil and info.text ~= '' then

                        love.graphics.print(info.text, info.vector2.x, info.vector2.y);

                    end
                end
            end
        end
    end
end
function drawHealthBar()

end
return hero;
