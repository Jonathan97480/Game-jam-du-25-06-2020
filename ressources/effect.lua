local effects = {}
effects.efect = {};
effects.efect.attack = {}
effects.efect.attack = {
    animation = nil,
    curentFrame = 1,
    speed = 1,
    curentTime = 0,
    scale = {
        x = 1,
        y = 1
    },
    rotation = 0,
    vector2 = {
        x = 0,
        y = 0
    },
    isplay = false
}

function effects.load()
    effects.efect.attack.animation = AddEffect({
        "img/effect/attaque-base/frame-0.png",
        "img/effect/attaque-base/frame-1.png",
        "img/effect/attaque-base/frame-2.png",
        "img/effect/attaque-base/frame-3.png",
        "img/effect/attaque-base/frame-4.png",
        "img/effect/attaque-base/frame-5.png",
        "img/effect/attaque-base/frame-6.png",
        "img/effect/attaque-base/frame-7.png"
    });

end

--[[ Frame is Array  ]]
function AddEffect(frame)
    local animation = {}
    for i = 1, #frame do
        local value = frame[i];
        local frame = love.graphics.newImage(value)
        table.insert(animation, frame);
    end

    return animation
end

function effects.draw()

    local value = effects.efect.attack;
    if value.isplay then
        value.curentTime = value.curentTime + dt;
        if value.curentTime >= value.speed then
            value.curentTime = 0;
            if value.curentFrame < #value.animation then

                value.curentFrame = value.curentFrame + 1;
                value.curentTime = 0;
            else

                value.curentFrame = 1;
                value.curentTime = 0;
                value.isplay = false;
            end
        end
        love.graphics.draw(value.animation[value.curentFrame], value.vector2.x, value.vector2.y, value.rotation,
                           value.scale.x, value.scale.y);
    end
    -- end
    

end

return effects
