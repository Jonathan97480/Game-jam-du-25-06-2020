local giveEpine = {}

giveEpine.applique = function(p_card, p_actor, p_value)

   -- p_actor.state.epine = p_value;
    --[[ TODO:Play animation epine  ]]
    p_actor.animation.playAction('epine', p_value)
end

return giveEpine;
