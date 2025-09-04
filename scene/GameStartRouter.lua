local gameStarterRouter = {}

--[[ REQUIREMENTS ]] --
local sceneIntro = require("scene.gameplay.intro.intro")
local sceneHubVillage = require("scene.gameplay.villageHub.hubVillage")
local saveManager = require("my-librairie.save-system.saveManager")
local sceneManager = require("my-librairie.core.sceneManager")
local IdSave = rawget(_G, "IdSave") or "default_save"

gameStarterRouter.name = "GameStartRouter"
local currentScene = nil
local isFirstLaunch = false

gameStarterRouter.load = function()
    local saveData = saveManager.loadSave(IdSave)
    if not saveData or not saveData.hasLaunchedBefore then
        isFirstLaunch = true
        currentScene = sceneIntro
    else
        currentScene = sceneHubVillage
    end

    sceneManager.changeScene(currentScene)
end




gameStarterRouter.update = function(dt)

end



gameStarterRouter.draw = function()

end
