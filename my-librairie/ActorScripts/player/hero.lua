local hero = {};

local shield = love.graphics.newImage('img/Actor/hero/Hub-Shield2.png');
local debug = {};
local backGround = love.graphics.newImage("img/BackGround/zonedeConbat-1.png");
hero.actor = {}

function debug.table(p_table)

    for index, value in ipairs(p_table) do

        print(index .. '/ ' .. value .. '/n');

    end
end
-- REQUIRE
local actor = require("my-librairie/ActorScripts/actorManager");

-- VARIABLE

-- LOAD
function hero.load()
    -- DECLARATION HERO
    hero.actor = {}
    hero.actor = actor.create('jouer', {
        idle = {
            'img/Actor/hero/Hero.png'
        }
    }, {
        x = 383,
        y = 400
    });
    hero.actor.state.life = 80;
    hero.actor.state.maxLife = hero.actor.state.life;
end
function hero.rezet()
    hero.actor.state.life = hero.actor.state.maxLife;
    hero.actor.state.shield = 0;
    hero.actor.state.power = 8;
    hero.actor.state.dead = false;
    hero.actor.state.epine = 0

end
-- UPDATE
function hero.update()

end

-- DRAW
function hero.draw()

    --[[ bakcground ]]
    love.graphics.draw(backGround, 0, 0);

    local animation = hero.actor.animation[hero.actor.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], hero.actor.vector2.x, hero.actor.vector2.y);

    end
    -- BARE DE VIE 

    myFonction.drawLifeBarStatus(hero.actor, 'bleu');

    -- POWER DRAW TEXT
    hud.object.energie.value.text = hero.actor.state.power;

    --[[ GAME OVER ]]
    if hero.actor.state.dead  then
        if myFonction.mouse.click() then

            hud.hover("click");

        end
        love.graphics.setNewFont(80);
        love.graphics.print('GAME OVER', 700, 100);
        love.graphics.setNewFont(50);
        love.graphics.print('Would you like to start over', 600, 190);
        love.graphics.setNewFont(15);

        for key, value in pairs(hud.object) do

            if key == 'btnNewPartie' or key == 'btnQuiter' then

                local info = value.value;

                love.graphics.draw(value.img, value.vector2.x, value.vector2.y);
                love.graphics.setNewFont(20);

                love.graphics.print(info.text, info.vector2.x, info.vector2.y);

            end
        end
    end
end
function drawHealthBar()

end
return hero;
