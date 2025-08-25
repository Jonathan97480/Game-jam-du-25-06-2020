-- my-librairie/ai/telegraph.lua
-- Couche VISUELLE : affiche l'intention/carte IA et attend avant d'appeler ai:resume()

local responsive = require("my-librairie/responsive")
local Hud = require("my-librairie/hud/hudManager")

local M = {
    enabled           = true, -- activer/désactiver complètement le visuel
    delay             = 0.30, -- fallback si le contrôleur ne fournit pas de valeur
    _timer            = 0,
    _card             = nil,
    _ai               = nil,
    _shownOnce        = false, -- pour éviter le spam de logs si aucune API d'affichage
    DEBUG             = true,
    MAX_ACTIONS_SAVED = 3,
    _cardSaved        = {}
}




-- appelé par la logique : prépare l'affichage + timer
function M:onTelegraph(card, seconds, ai)
    if not self.enabled then
        -- visuel coupé -> on reprend immédiatement
        if ai and ai.resume then ai:resume() end
        return
    end
    self._ai    = ai
    self._card  = card
    self._timer = tonumber(seconds) or self.delay

    -- essai d'affichage
    local res   = setmetatable(card, {})
    table.insert(self._cardSaved, 1, res)
    if (#self._cardSaved > self.MAX_ACTIONS_SAVED) then
        table.remove(self._cardSaved, self.MAX_ACTIONS_SAVED + 1)
    end

    if not ok then
        -- même si pas d'API visuelle, on garde un tout petit délai (facultatif)
        if self._timer < 0.05 then self._timer = 0.05 end
    end
end

function M:update(dt)
    if not self.enabled then return end
    if not self._ai or not self._card then return end

    self._timer = (self._timer or 0) - (tonumber(dt) or 0)
    if self._timer <= 0 then
        -- signaler à la logique de continuer
        local ai = self._ai
        self._ai, self._card, self._timer = nil, nil, 0
        if ai and ai.resume then ai:resume() end
    end
end

function M:draw()
    if not self.enabled then return end
    --[[ if not self._card then return end ]]
    if (#self._cardSaved <= 0) then return end

    local panelInformation = {
        position = { x = responsive.gameReso.width - 300, y = 0 },
        width = 300,
        height = responsive.gameReso.height
    }
    hud.drawPanel(panelInformation.position.x, panelInformation.position.y, panelInformation.width,
        panelInformation.height, {
            alpha = 0.5,
            palette = {
                background = { 0, 0, 0, 0.5 },
            },
            content = {
                hud.text(self.MAX_ACTIONS_SAVED .. " dernières actions", 20, 20,
                    {
                        color = { 1, 1, 1, 1 },
                        font = "default",
                        parentPosition = panelInformation.position,
                        fontSize = 10
                    }),
                -- fonction pour dessiner les cartes

                function()
                    for i = 1, #self._cardSaved do
                        --detecter si la sourie survole la carte
                        local mouseX = screen.mouse.X
                        local mouseY = screen.mouse.Y
                        local cardX = 50 + panelInformation.position.x
                        local cardY = 120 + (i - 1) * 240 + panelInformation.position.y
                        local cardW = self._cardSaved[i].width * 0.5
                        local cardH = self._cardSaved[i].height * 0.5

                        if hud.pointInRect(mouseX, mouseY, cardX, cardY, cardW, cardH) then
                            --Affiche la carte en scale 1 au centre de l'écran
                            hud.drawCard(self._cardSaved[i], (responsive.gameReso.width - cardW) / 2,
                                (responsive.gameReso.height - cardH) / 2,
                                { scale = 1 })
                        end

                        hud.drawCard(self._cardSaved[i], 50, 120 + (i - 1) * 240,
                            { scale = 0.5, parentPosition = panelInformation.position })
                    end
                end
            }
        });
end

function M:clear()
    self._cardSaved = {}
end

-- configuration optionnelle
function M:setEnabled(v) self.enabled = not not v end

function M:setDelay(sec) self.delay = tonumber(sec) or self.delay end

return M
