local actor = {};
actor.get = {};
actor.set = {};

function actor.create(p_name, p_animation, p_vector2)

    local newActor = {};

    newActor.name = p_name;
    newActor.nameDeck = "";

    newActor.vector2 = p_vector2;

    newActor.animation = {};
    newActor.animation.isPlay = false;
    newActor.curentAnimation = 'idle';

    newActor.width = 0;
    newActor.height = 0;

    newActor.state = {

        life = 80,
        maxLife = 80,
        power = 8,
        degat = 0,
        shield = 0,
        dead = false,
        epine = 0,
        chancePassTour = 0
    };

    newActor.sound = {
        sfx = {},
        music = {}
    }

    actor.addAnimation(newActor.animation, p_animation);

    actor.get.size(newActor);

    newActor.animation.playAction = function(p_type, p_value, p_actorB)

        if p_type == 'attack' and p_actorB == nil then

            return;
        end

        if p_type == 'attack' then
            effect.play({
                name = 'attack',
                vector2 = {
                    x = p_actorB.vector2.x,
                    y = p_actorB.vector2.y + (p_actorB.height / 2) - 40
                }
            });

            p_actorB.state.life = p_actorB.state.life - p_value;
            if (p_actorB.state.life <= 0) then
                p_actorB.state.life = 0;
                p_actorB.state.dead = true;
            end
        elseif p_type == 'heal' then
            effect.play({
                name = 'heal',
                vector2 = {
                    x = newActor.vector2.x,
                    y = newActor.vector2.y
                }
            });

            -- TODO: play heal animation and effect
            newActor.state.life = newActor.state.life + p_value;


        elseif p_type == 'shield' then

            -- TODO: play shield animation and effect
            newActor.state.shield = newActor.state.shield + p_value;


        elseif p_type == 'epine' then

            effect.play({
                name = 'epine',
                vector2 = {
                    x = newActor.vector2.x ,
                    y = newActor.vector2.y 
                }
            });
            -- TODO: play Epine animation and effect
            newActor.state.epine = newActor.state.epine + p_value;


        end

    end
    return newActor;

end

function actor.get.size(p_actor)

    for key, value in pairs(p_actor.animation) do

        if (value ~= nil and value ~= false) then

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
