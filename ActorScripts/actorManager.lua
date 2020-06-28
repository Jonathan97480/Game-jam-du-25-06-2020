local actor = {};
actor.get = {};
actor.set = {};

function actor.create(p_name, p_animation, p_vector2)

    local newActor = {

        name = p_name,
        nameDeck = "",

        vector2 = p_vector2,

        animation = {},
        curentAnimation = 'idle',

        width = 0,
        height = 0,

        state = {

            life = 80,
            maxLife = 80;
            power = 8,
            degat = 0,
            armor = 0,
            dead = false

        },

        sfx = {},
        sound = {}

    };
    for key, value in pairs(p_animation) do

        newActor.animation[key] = {}

        for n, patch in pairs(value) do

            local img = love.graphics.newImage(patch);

            table.insert(newActor.animation[key], img);

        end
    end

    actor.get.size(newActor);

    return newActor;

end

function actor.get.size(p_actor)

    for key, value in pairs(p_actor.animation) do

        if (value ~= nil) then

            p_actor.width, p_actor.height = value[1]:getDimensions()
            return;
        end

    end

end

return actor
