local hero = {};

local res = require("my-librairie.managers.resource_cache")
local shield = res.image('img/Actor/hero/Hub-Shield2.png')
local debug = {}
local backGround = res.image("img/BackGround/zonedeConbat-1.png")
hero.actor = {}

--[[

Fonction : debug.table

Rôle : Fonction « Table » liée à la logique du jeu.

Paramètres :

  - p_table : paramètre détecté automatiquement.

Retour : aucune valeur (nil).

]]

function debug.table(p_table)
  for index, value in ipairs(p_table) do
    print(index .. '/ ' .. value .. '/n');
  end
end

-- REQUIRE
local actor = _G.actorManager or require("my-librairie/managers/actorManager");

-- VARIABLE

-- LOAD
--[[
Fonction : hero.load
Rôle : Initialise les ressources et l'état.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function hero.load()
  -- DECLARATION HERO
  hero.actor = {}
  hero.actor = actor.create('jouer', {
    idle = {
      'img/Actor/hero/Hero.png'
    }
  }, {
    x = 383,
    y = 500
  });
  hero.actor.state.life = 80;
  hero.actor.state.maxLife = hero.actor.state.life;
  hero.actor.lifeBarConfig = {
    x = (hero.actor.vector2 and hero.actor.vector2.x) or 0,
    y = (hero.actor.vector2 and hero.actor.vector2.y) - 50 or 0,
    w = 150,
    h = 25,
    position = {
      x = (((hero.actor.vector2 and hero.actor.vector2.x + 35) + (hero.actor.width / 2)) - (150 / 2)) or 0,
      y = (hero.actor.vector2 and hero.actor.vector2.y) - 50 or 0
    },
    size = {
      w = 150,
      h = 25
    }
  }
end

--[[
Fonction : hero.rezet
Rôle : Fonction « Rezet » liée à la logique du jeu.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function hero.rezet()
  hero.actor.state.life = hero.actor.state.maxLife;
  hero.actor.state.shield = 0;
  hero.actor.state.power = 8;
  hero.actor.state.dead = false;
  hero.actor.state.epine = 0
end

-- UPDATE
--[[
Fonction : hero.update
Rôle : Met à jour la logique à chaque frame.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function hero.update()

end

-- DRAW
--[[
Fonction : hero.draw
Rôle : Affiche le rendu à l'écran.
Paramètres :
  - (aucun)
Retour : aucune valeur (nil).
]]
function hero.draw()
  --[[ bakcground ]]
  love.graphics.draw(backGround, 0, 0);

  local animation = hero.actor.animation[hero.actor.curentAnimation];

  for i = 1, #animation do
    love.graphics.draw(animation[i], hero.actor.vector2.x, hero.actor.vector2.y);
  end
  -- BARE DE VIE

  local gf = rawget(_G, "globalFunction") or rawget(_G, "myFonction") or rawget(_G, "myFunction")
  if gf and type(gf.drawLifeBarStatus) == "function" then pcall(function() gf.drawLifeBarStatus(hero.actor, 'bleu') end) end

  -- POWER DRAW TEXT
  hud.setText('energy_text', hero.actor.state.power);
end

return hero;
