 hero = {};
local debug = {};

function debug.table(p_table)

    for index, value in ipairs(p_table) do

        print(index .. '/ ' .. value .. '/n');

    end
end
-- REQUIRE
local actor = require("ActorScripts/actorManager");

-- VARIABLE

-- DECLARATION HERO
hero = actor.create('jouer', {
    idle = {
        'img/Actor/hero/Hero.png'
    }
}, {
    x = 466,
    y = 523
});

-- LOAD
function hero.load()

end

-- UPDATE
function hero.update()

end

-- DRAW
function hero.draw()

    local animation = hero.animation[hero.curentAnimation];

    for i = 1, #animation do

        love.graphics.draw(animation[i], hero.vector2.x, hero.vector2.y);

    end
    -- BARE DE VIE 
    love.graphics.setColor(0, 0, 1);
    local centerBar = hero.vector2.x + ((hero.width / 2) - (hero.state.life / 2));
	love.graphics.rectangle('fill', centerBar, hero.vector2.y + hero.height, 3 * hero.state.life, 10);
	love.graphics.setColor(1,1,1);
	love.graphics.print(hero.state.life..'/'..hero.state.maxLife,hero.vector2.x + (hero.width/1.5),hero.vector2.y + (hero.height-8));
 
    -- POWER DRAW TEXT
	hudGameplay.object.energie.value[1].text = hero.state.power;
	hudGameplay.object.Deffence.value[1].text = hero.state.armor;
end

return hero;
