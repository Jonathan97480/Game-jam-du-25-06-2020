local heal = require("my-librairie/card-librairie/cardEffect/heal");
local attack = require("my-librairie/card-librairie/cardEffect/attack");
local epine = require("my-librairie/card-librairie/cardEffect/giveEpine");
local shield = require("my-librairie/card-librairie/cardEffect/giveSheld");

local action = {};
local listeAction = {};
local ongoingAction = false;

function action.Apllique(p_card, p_newValue)
    --[[ POWER USE  ]]
  
    if p_newValue == nil then

        p_newValue = p_card.PowerBlowCard;

    end

    if hero.actor.state.power < p_newValue then

        return false;
    end

    hero.actor.state.power = hero.actor.state.power - p_newValue;
    table.insert(listeAction, p_card);
    return true
end

function action.update()

    if ongoingAction == false and listeAction[1] ~= nil and effect.efect.attack.isplay == false then

        if hero.actor.animation.isPlay == false and Enemies.curentEnemy.animation.isPlay == false then

            ongoingAction = true;
            action.play(listeAction[1])
        end

    end

end

function action.play(p_card)
    --[[ 
                            ----------------------
                                    HEAL
                            ----------------------
                         ]]


    --[[ HERO-HEAL ]]
    if (p_card.effect.Hero.heal ~= nil) then

        heal.give(p_card, hero.actor, p_card.effect.Hero.heal);
    end
    --[[ ENEMY-HEAL ]]
    if (p_card.effect.Enemy.heal ~= nil) then

        heal.give(p_card, Enemies.curentEnemy, p_card.effect.Enemy.heal);
    end
    --[[ 
                            ----------------------
                                    SHIELD
                            ----------------------
                         ]]

    --[[ HERO-SHIELD ]]
    if p_card.effect.Hero.shield ~= nil then

        shield.applique(p_card, hero.actor, p_card.effect.Hero.shield);

    end
    --[[ ENEMY-SHIELD ]]
    if p_card.effect.Enemy.shield ~= nil then

        shield.applique(p_card, Enemies.curentEnemy, p_card.effect.Enemy.shield);

    end
    --[[ 
                            ----------------------
                                    ATTACK
                            ----------------------
                         ]]

    --[[Hero  ATTACK ]]
    if p_card.effect.Enemy.attack ~= nil then

        attack.applique(p_card, hero.actor, Enemies.curentEnemy, p_card.effect.Enemy.attack);

    end
    --[[ Henemy ATTACK ]]
    if p_card.effect.Hero.attack ~= nil then

        attack.applique(p_card, Enemies.curentEnemy, hero.actor, p_card.effect.Hero.attack);

    end
    --[[ 
                            ----------------------
                                    EPINE
                            ----------------------
                         ]]
    --[[ Henemy EPINE ]]
    if p_card.effect.Enemy.Epine ~= nil then

        epine.applique(p_card, Enemies.curentEnemy, p_card.effect.Enemy.Epine);

    end
    --[[ Hero EPINE ]]
    if p_card.effect.Hero.Epine ~= nil then

        epine.applique(p_card, hero.actor, p_card.effect.Hero.Epine);

    end
    --[[ 
                            ----------------------
                            CHANCE ENEMY PASS TOUR
                            ----------------------
                         ]]
    if p_card.effect.Enemy.chancePassedTour ~= nil then

        Enemies.curentEnemy.state.chancePassTour = Enemies.curentEnemy.state.chancePassTour +
                                                       p_card.effect.Enemy.chancePassedTour;

    end

    if (p_card.effect.action ~= nil) then
        p_card.effect.action();


    end
    --[[ on retire la card des action a faire est on hotorise une nouvelle action  ]]
    table.remove(listeAction, 1);


    p_card.vector2.x = screen.gameReso.width;
    p_card.vector2.y = screen.gameReso.height - p_card.height / 2;

    --[[ On enleve la  carde de la main du jouer et on la met dans le simetiere  ]]
    table.insert(card.Graveyard, p_card);
   
    --[[ est on reposition les carte restant dans la main du jouer  ]]
    card.positioneHand();
    ongoingAction = false;
end
return action;
