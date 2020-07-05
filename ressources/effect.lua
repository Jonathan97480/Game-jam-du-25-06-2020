local effects = {}
effects.efect = {};
effects.liste = {};
effects.efect.attack = {};
effects.efect.attack = {};

function effects.load()
    effects.efect.attack = addEffect({
        "img/effect/Attaque-base/frame-",
        5
    });
    effects.efect.heal = addEffect({
        "img/effect/heal/bonuss-heal-",
        4
    });
    effects.efect.heal.speed =0.2;
    effects.efect.epine = addEffect({
        "img/effect/epine/bonuss-epine-",
        5
    });
    effects.efect.bonusAttack = addEffect({
        "img/effect/degat/bonuss-degat-",
        5
    });

end
effects.play = function(p_NamEffect)

    table.insert(effects.liste, p_NamEffect)

end

function effects.update()
    if #effects.liste ~= 0 then

        if effects.efect[effects.liste[1].name].isplay ~= true then

            effects.efect[effect.liste[1].name].vector2 = effect.liste[1].vector2;
            effects.efect[effect.liste[1].name].isplay = true;

        end
    end
end

function addEffect(p_patchImg)
    local myeffect = {}
    myeffect.animation = nil;
    myeffect.curentFrame = 1;
    myeffect.speed = 0.1;
    myeffect.curentTime = 0;
    myeffect.scale = {
        x = 1,
        y = 1
    }
    myeffect.rotation = 0;
    myeffect.vector2 = {
        x = 0,
        y = 0
    }
    myeffect.isplay = false;
    myeffect.animation = AddFrame(p_patchImg);
    return myeffect;
end

--[[ Frame is Array  ]]
function AddFrame(p_frame)
    local animation = {}

    for i = 1, p_frame[2] do

        local frame = love.graphics.newImage(p_frame[1] .. i .. '.png')

        table.insert(animation, frame);

    end

    return animation
end

function effects.draw()

    for key, value in pairs(effect.efect) do
     
        if  effect.efect[key].isplay then
        
            effect.efect[key].curentTime = effect.efect[key].curentTime + delta;
            if effect.efect[key].curentTime >= effect.efect[key].speed then
                effect.efect[key].curentTime = 0;
                if effect.efect[key].curentFrame < #effect.efect[key].animation then

                    effect.efect[key].curentFrame = effect.efect[key].curentFrame + 1;
                    effect.efect[key].curentTime = 0;
                else

                    effect.efect[key].curentFrame = 1;
                    effect.efect[key].curentTime = 0;
                    effect.efect[key].isplay = false;
                end
            end
            if  effect.efect[key].isplay then
                love.graphics.draw(effect.efect[key].animation[effect.efect[key].curentFrame], effect.efect[key].vector2.x, effect.efect[key].vector2.y, effect.efect[key].rotation,
                effect.efect[key].scale.x, effect.efect[key].scale.y);
            else
                table.remove(effects.liste, 1);
            end
        end
    end
end

return effects
