local actor = {};
actor.get = {};
actor.set = {};

function actor.create(p_name, p_animation, p_vector2)

    local newActor = {};

    newActor.name = p_name;
    newActor.nameDeck = "";

    newActor.vector2 = p_vector2;

    newActor.animation = {};
    newActor.animation.isplay = false;
    newActor.curentAnimation = 'idle';

    newActor.width = 0;
    newActor.height = 0;

    newActor.state = {

        life = 80,
        maxLife = 80,
        power = 8,
        degat = 0,
        armor = 0,
        dead = false,
        chancePassTour = 0
    };

    newActor.sound = {
        sfx = {},
        music = {}
    }

    actor.addAnimation(newActor.animation, p_animation);

    actor.get.size(newActor);

    return newActor;

end

function actor.get.size(p_actor)

    for key, value in pairs(p_actor.animation) do

        if (value ~= nil and value~=false) then

            p_actor.width, p_actor.height = value[1]:getDimensions()
            return;
        end

    end

end
--[[ Permet d'ajouter des animation lier a des action basique
 in game l'attack le soin et le rajout d'armure 
les diferent type 'animation' possible seront Attack ,Heal  Shield
le tableau danimation doit resembler a sa {Attack={patch1,..etc},Attack={patch2,..etc},Attack={patch3,..etc}}  ]]
function actor.addAnimation(p_objet, p_animation)
    --[[ p_objet correspont a la table ou sera stoker l'animation ]]
    for key, value in pairs(p_animation) do

        p_objet[key] = {}

        for n, patch in pairs(value) do

            local img = love.graphics.newImage(patch);

            table.insert(p_objet[key], img);

        end

    end

end

return actor
