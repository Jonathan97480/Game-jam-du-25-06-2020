-- my-librairie/transition/templateCombatTransition.lua
-- Version corrigée : utilise overlay_start pour le draft initial (overlay_deckdraft supprimé)

local function SM() return rawget(_G, 'scene') or require('my-librairie/sceneManager') end
local function AM() return rawget(_G, 'actorManager') or require('my-librairie/actorManager') end
local function EN() return rawget(_G, 'Enemies') or require('my-librairie/ActorScripts/Enemy/Enemies') end
local function HERO() return rawget(_G, 'Hero') or require('my-librairie/ActorScripts/player/Hero') end
local function AI() return rawget(_G, 'AI') or require('my-librairie/ai/controller') end
local function CARD() return require('my-librairie/card-librairie/card') end

local GameFlags = rawget(_G, "GameFlags") or {}; rawset(_G, "GameFlags", GameFlags)

local DefaultConfig = {
    overlays = {
        start      = "scene.overlay_start.overlay_start",
        initiative = "scene.overlay_initiative.overlay_initiative",
        reward     = "scene.overlay_reward.overlay_reward",
        gameover   = "scene.overlay_gameover.overlay_gameover",
    }
}

local CT = {}; CT.__index = CT

function CT.new(cfg)
    local self = setmetatable({}, CT)
    self.cfg = cfg or DefaultConfig
    self.state = "boot"
    return self
end

function CT:startEncounter()
    if not GameFlags.first_draft_done then
        self.state = "first_draft"
        -- diagnostic: log attempt to push start overlay and GameFlags
        pcall(function()
            local f = io.open("gameLogs/transition_debug.log", "a")
            if f then
                f:write(os.date("%Y-%m-%d %H:%M:%S") ..
                    " - CT:startEncounter -> pushing start overlay (GameFlags.first_draft_done=" ..
                    tostring(GameFlags.first_draft_done) .. ")\n")
                f:close()
            end
        end)
        if self.cfg.overlays.start then SM():push(self.cfg.overlays.start) end
        return
    end
    self.state = "player_turn"
end

function CT:confirmStartOverlay()
    if self.state == "first_draft" then
        GameFlags.first_draft_done = true
        if SM().pop then SM():pop() end
        self.state = "player_turn"
    else
        self.state = "player_turn"
    end
end

function CT:canDeal() return self.state == "player_turn" end

local Singleton  = CT.new(DefaultConfig)
Singleton.load   = function(self) return self:startEncounter() end
Singleton.update = function(self, dt) end
Singleton.draw   = function(self) end

-- Compatibility aliases expected by overlays
function Singleton.continueFromStartOverlay(self)
    -- call the template method if available
    if CT and type(CT.confirmStartOverlay) == 'function' then
        pcall(CT.confirmStartOverlay, self)
    end
end

function Singleton.announceContinue(self)
    -- overlays expect announceContinue; map to confirmStartOverlay by default
    if CT and type(CT.confirmStartOverlay) == 'function' then
        pcall(CT.confirmStartOverlay, self)
    end
end

function Singleton.getInitiative(self)
    -- try to return the global Tour or nil
    return rawget(_G, 'Tour')
end

local M = setmetatable({ new = function(cfg) return CT.new(cfg) end }, { __index = Singleton })
rawset(_G, "Transition", M)
return M
