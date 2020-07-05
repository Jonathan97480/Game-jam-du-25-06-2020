local giveSheld={}

giveSheld.applique = function(p_card, p_actor, p_value)

    --p_actor.state.shield = p_value;
    --[[ TODO:Play animation Shield  ]]
    p_actor.animation.playAction('shield', p_value)
end


return giveSheld;