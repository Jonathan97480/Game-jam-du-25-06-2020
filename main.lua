--permet davoir le debug 
io.stdout:setvbuf("no")

  --***********Paramétrage fenêtre de jeux*************
  love.window.setTitle("BerouteEngine")
  love.window.setMode(1280,720)

if arg[#arg] == "-debug" then require("mobdebug").start() end



love.window.getTitle("player Animation & Mouvements")

cardeGenerator = require("my-librairie/cardeGenerator")


--variables
--Systeme
resolution ={wiedth = 1280,height = 720}
--Object

print ('salut');

