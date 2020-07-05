local heal = {}

function heal.give(p_card, p_actor, p_value)

    local value = p_value;
    local actorCurentLife = p_actor.state.maxLife - p_actor.state.life;

    --[[ si cest egal a zero cest que l'acteur a toute sa vie
    si actorCurentLife est inferieure a la value cest que le soin est trop
     important donc on reduit le soin  ]]
    if actorCurentLife == 0 or actorCurentLife < value then

        value = actorCurentLife;

    end

    --[[ TODO:Play animation heal  ]]
    p_actor.animation.playAction('heal', value)
end

return heal;
