# Exemples d'Implémentation HUD

## Exemple 1 : Menu Principal Complet

```lua
-- scene/menu/HUD/hud_main_menu.lua
local hud_main_menu = {}

local function W()
    return (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
end

local function H()
    return (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
end

function hud_main_menu.load()
    -- Nettoyer HUD précédent
    if hud.clear then hud.clear() end
    
    -- Background avec image
    hud.setPanel("menu_bg", 0, 0, W(), H(), {}, {
        type = "panel",
        bg = "img/Menu/BackGround.jpg",
        typeRender = "cover"
    })
    
    -- Logo du jeu
    hud.addIcon("game_logo", {
        img = "img/Menu/Titre.png",
        x = W()/2 - 300,
        y = 100,
        w = 600,
        h = 150,
        layer = "decor"
    })
    
    -- Boutons principaux avec images
    local btnW, btnH = 280, 80
    local btnX = W()/2 - btnW/2
    local startY = 350
    
    hud.addButton("play_btn", {
        img = "img/hud/Button-Menu.png",
        text = "Jouer",
        x = btnX,
        y = startY,
        w = btnW,
        h = btnH,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            scene:push("scene.gameplay.gameplay")
        end
    })
    
    hud.addButton("options_btn", {
        img = "img/hud/Button-Menu.png", 
        text = "Options",
        x = btnX,
        y = startY + 100,
        w = btnW,
        h = btnH,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            scene:push("scene.option.option")
        end
    })
    
    hud.addButton("credits_btn", {
        img = "img/hud/Button-Menu.png",
        text = "Crédits", 
        x = btnX,
        y = startY + 200,
        w = btnW,
        h = btnH,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            scene:push("scene.credit.credit")
        end
    })
    
    hud.addButton("quit_btn", {
        img = "img/hud/Button-Menu.png",
        text = "Quitter",
        x = btnX,
        y = startY + 300,
        w = btnW,
        h = btnH,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            love.event.quit()
        end
    })
    
    -- Version du jeu
    hud.addLabel("version", {
        text = "Version 1.0.0",
        x = W() - 150,
        y = H() - 30,
        layer = "decor",
        color = {0.7, 0.7, 0.7, 1}
    })
end

function hud_main_menu.update(dt)
    hud.update(dt)
end

function hud_main_menu.draw()
    hud.draw()
end

return hud_main_menu
```

## Exemple 2 : HUD de Combat Dynamique

```lua
-- scene/gameplay/HUD/hud_combat.lua
local hud_combat = {}

local function W()
    return (responsive and responsive.gameReso and responsive.gameReso.width) or 1920
end

local function H()
    return (responsive and responsive.gameReso and responsive.gameReso.height) or 1080
end

function hud_combat.load()
    if hud.clear then hud.clear() end
    
    -- Zone de combat (fond semi-transparent)
    hud.setPanel("combat_overlay", 0, 0, W(), H(), {}, {
        type = "panel",
        color = {0, 0, 0, 0.3}
    })
    
    -- Interface joueur (en bas)
    local playerY = H() - 200
    
    -- Santé du joueur
    hud.addIcon("player_health_icon", {
        img = "img/hud/Button-life.png",
        x = 50,
        y = playerY,
        w = 60,
        h = 60,
        layer = "props"
    })
    
    hud.addBar("player_health_bar", {
        x = 120,
        y = playerY + 15,
        w = 200,
        h = 30,
        current = 100,
        max = 100,
        layer = "props",
        border = {0.8, 0.2, 0.2, 1}  -- Rouge
    })
    
    hud.addLabel("player_health_text", {
        text = "100/100",
        x = 130,
        y = playerY + 20,
        layer = "props",
        color = {1, 1, 1, 1}
    })
    
    -- Énergie du joueur
    hud.addIcon("player_energy_icon", {
        img = "img/hud/nombre de coup.png",
        x = 50,
        y = playerY + 80,
        w = 60,
        h = 60,
        layer = "props"
    })
    
    hud.addLabel("player_energy_text", {
        text = "3",
        x = 130,
        y = playerY + 100,
        layer = "props",
        color = {0.2, 0.8, 1, 1}  -- Bleu
    })
    
    -- Interface ennemi (en haut)
    local enemyY = 50
    
    hud.addLabel("enemy_name", {
        text = "Gobelin",
        x = W()/2 - 100,
        y = enemyY,
        layer = "decor",
        color = {1, 0.8, 0.2, 1}  -- Jaune
    })
    
    hud.addBar("enemy_health_bar", {
        x = W()/2 - 150,
        y = enemyY + 40,
        w = 300,
        h = 25,
        current = 80,
        max = 100,
        layer = "props",
        border = {0.8, 0.2, 0.2, 1}
    })
    
    hud.addLabel("enemy_health_text", {
        text = "80/100",
        x = W()/2 - 30,
        y = enemyY + 45,
        layer = "props",
        color = {1, 1, 1, 1}
    })
    
    -- Boutons d'action
    local btnY = playerY - 80
    
    hud.addButton("end_turn_btn", {
        img = "img/hud/Button-fin-de-tour.png",
        text = "Fin du Tour",
        x = W() - 300,
        y = btnY,
        w = 250,
        h = 60,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            endPlayerTurn()
        end
    })
    
    hud.addButton("all_cards_btn", {
        img = "img/hud/Button-all-card.png", 
        text = "Toutes Cartes",
        x = W() - 570,
        y = btnY,
        w = 250,
        h = 60,
        layer = "button",
        textColor = {1, 1, 1, 1},
        onClick = function()
            showAllCards()
        end
    })
    
    -- Menu pause
    hud.addButton("pause_btn", {
        text = "⏸",
        x = W() - 60,
        y = 20,
        w = 40,
        h = 40,
        layer = "button",
        bgColor = {0.2, 0.2, 0.2, 0.8},
        hoverColor = {0.3, 0.3, 0.3, 0.9},
        textColor = {1, 1, 1, 1},
        cornerRadius = 20,
        onClick = function()
            scene:push("scene.pause.pause")
        end
    })
end

function hud_combat.update(dt)
    hud.update(dt)
    
    -- Mise à jour des valeurs en temps réel
    hud_combat.updateValues()
end

function hud_combat.updateValues()
    -- Récupérer données du jeu
    local player = getPlayer()  -- Fonction hypothétique
    local enemy = getCurrentEnemy()  -- Fonction hypothétique
    
    if player then
        -- Santé joueur
        hud.setBar("player_health_bar", player.health, player.maxHealth)
        hud.setText("player_health_text", player.health .. "/" .. player.maxHealth)
        
        -- Énergie joueur avec couleur conditionnelle
        hud.setText("player_energy_text", tostring(player.energy))
        
        -- Recréer le label d'énergie avec couleur si nécessaire
        if player.energy <= 1 then
            hud.remove("player_energy_text")
            hud.addLabel("player_energy_text", {
                text = tostring(player.energy),
                x = 130,
                y = playerY + 100,
                layer = "props",
                color = {1, 0.3, 0.3, 1}  -- Rouge si faible
            })
        end
    end
    
    if enemy then
        -- Ennemi
        hud.setText("enemy_name", enemy.name)
        hud.setBar("enemy_health_bar", enemy.health, enemy.maxHealth)
        hud.setText("enemy_health_text", enemy.health .. "/" .. enemy.maxHealth)
    end
end

function hud_combat.draw()
    hud.draw()
end

return hud_combat
```

## Exemple 3 : Dialog/Modal Réutilisable

```lua
-- my-librairie/hud/modal_dialog.lua
local modal_dialog = {}

function modal_dialog.show(title, message, buttons)
    -- Supprimer modal existant
    modal_dialog.hide()
    
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    
    local modalW, modalH = 500, 300
    local modalX = (W - modalW) / 2
    local modalY = (H - modalH) / 2
    
    -- Overlay semi-transparent
    hud.setPanel("modal_overlay", 0, 0, W, H, {}, {
        type = "panel",
        color = {0, 0, 0, 0.7}
    })
    
    -- Boîte de dialog
    hud.setPanel("modal_box", modalX, modalY, modalW, modalH, {}, {
        type = "panel",
        color = {0.2, 0.2, 0.2, 0.95}
    })
    
    -- Titre
    hud.addLabel("modal_title", {
        text = title or "Dialog",
        x = modalX + 20,
        y = modalY + 20,
        layer = "button",  -- Au-dessus de tout
        color = {1, 1, 0.8, 1}
    })
    
    -- Message
    hud.addLabel("modal_message", {
        text = message or "",
        x = modalX + 20,
        y = modalY + 60,
        layer = "button",
        color = {1, 1, 1, 1}
    })
    
    -- Boutons
    buttons = buttons or {
        {text = "OK", callback = function() modal_dialog.hide() end}
    }
    
    local btnW = 100
    local btnSpacing = 20
    local totalBtnW = #buttons * btnW + (#buttons - 1) * btnSpacing
    local startBtnX = modalX + (modalW - totalBtnW) / 2
    local btnY = modalY + modalH - 80
    
    for i, btn in ipairs(buttons) do
        local btnX = startBtnX + (i - 1) * (btnW + btnSpacing)
        
        hud.addButton("modal_btn_" .. i, {
            text = btn.text,
            x = btnX,
            y = btnY,
            w = btnW,
            h = 40,
            layer = "button",
            bgColor = {0.3, 0.5, 0.3, 1},
            hoverColor = {0.4, 0.6, 0.4, 1},
            clickColor = {0.2, 0.4, 0.2, 1},
            textColor = {1, 1, 1, 1},
            cornerRadius = 5,
            onClick = btn.callback or function() modal_dialog.hide() end
        })
    end
end

function modal_dialog.hide()
    hud.remove("modal_overlay")
    hud.remove("modal_box")
    hud.remove("modal_title")
    hud.remove("modal_message")
    
    -- Supprimer tous les boutons
    for i = 1, 10 do  -- Maximum 10 boutons
        hud.remove("modal_btn_" .. i)
    end
end

-- Dialogs prédéfinis
function modal_dialog.confirm(title, message, onConfirm, onCancel)
    modal_dialog.show(title, message, {
        {text = "Annuler", callback = onCancel or modal_dialog.hide},
        {text = "Confirmer", callback = onConfirm or modal_dialog.hide}
    })
end

function modal_dialog.alert(title, message, onOK)
    modal_dialog.show(title, message, {
        {text = "OK", callback = onOK or modal_dialog.hide}
    })
end

return modal_dialog
```

## Exemple 4 : Système de Notifications

```lua
-- my-librairie/hud/notification_system.lua
local notifications = {}
local notification_queue = {}
local next_id = 1

function notifications.show(message, type, duration)
    type = type or "info"  -- info, success, warning, error
    duration = duration or 3  -- secondes
    
    local id = "notification_" .. next_id
    next_id = next_id + 1
    
    local W = love.graphics.getWidth()
    local notifW, notifH = 400, 60
    local notifX = W - notifW - 20
    
    -- Calculer Y en fonction des notifications existantes
    local notifY = 20
    for _, existing in ipairs(notification_queue) do
        notifY = notifY + notifH + 10
    end
    
    -- Couleur selon le type
    local colors = {
        info = {0.2, 0.6, 1, 0.9},
        success = {0.2, 0.8, 0.2, 0.9}, 
        warning = {1, 0.8, 0.2, 0.9},
        error = {0.8, 0.2, 0.2, 0.9}
    }
    
    -- Créer notification
    hud.setPanel(id, notifX, notifY, notifW, notifH, {}, {
        type = "panel",
        color = colors[type] or colors.info
    })
    
    hud.addLabel(id .. "_text", {
        text = message,
        x = notifX + 15,
        y = notifY + 20,
        layer = "button",
        color = {1, 1, 1, 1}
    })
    
    -- Bouton fermer
    hud.addButton(id .. "_close", {
        text = "×",
        x = notifX + notifW - 30,
        y = notifY + 5,
        w = 20,
        h = 20,
        layer = "button",
        bgColor = {1, 1, 1, 0.3},
        hoverColor = {1, 1, 1, 0.5},
        textColor = {0, 0, 0, 1},
        cornerRadius = 10,
        onClick = function()
            notifications.hide(id)
        end
    })
    
    -- Ajouter à la queue
    table.insert(notification_queue, {
        id = id,
        startTime = love.timer.getTime(),
        duration = duration
    })
end

function notifications.hide(id)
    hud.remove(id)
    hud.remove(id .. "_text")
    hud.remove(id .. "_close")
    
    -- Retirer de la queue et réorganiser
    for i, notif in ipairs(notification_queue) do
        if notif.id == id then
            table.remove(notification_queue, i)
            break
        end
    end
    
    notifications.reorganize()
end

function notifications.reorganize()
    -- Réorganiser les positions Y
    for i, notif in ipairs(notification_queue) do
        local newY = 20 + (i - 1) * 70
        local el = hud.get(notif.id)
        if el then
            el.y = newY
            -- Mettre à jour aussi le texte et bouton
            local textEl = hud.get(notif.id .. "_text") 
            local closeEl = hud.get(notif.id .. "_close")
            if textEl then textEl.y = newY + 20 end
            if closeEl then closeEl.y = newY + 5 end
        end
    end
end

function notifications.update(dt)
    local currentTime = love.timer.getTime()
    
    -- Vérifier expiration
    for i = #notification_queue, 1, -1 do
        local notif = notification_queue[i]
        if currentTime - notif.startTime >= notif.duration then
            notifications.hide(notif.id)
        end
    end
end

-- Fonctions de convenance
function notifications.info(message, duration)
    notifications.show(message, "info", duration)
end

function notifications.success(message, duration) 
    notifications.show(message, "success", duration)
end

function notifications.warning(message, duration)
    notifications.show(message, "warning", duration)
end

function notifications.error(message, duration)
    notifications.show(message, "error", duration)
end

return notifications
```

## Usage des Exemples

### Dans une scène :

```lua
-- Utiliser le menu principal
local hud_menu = require("scene.menu.HUD.hud_main_menu")

function MenuScene:enter()
    hud_menu.load()
end

function MenuScene:update(dt)
    hud_menu.update(dt)
end

function MenuScene:draw()
    hud_menu.draw()
end
```

### Utiliser les modals :

```lua
local modal = require("my-librairie.hud.modal_dialog")

-- Dialog simple
modal.alert("Information", "Jeu sauvegardé !")

-- Dialog de confirmation
modal.confirm("Quitter", "Êtes-vous sûr de vouloir quitter ?", 
    function() love.event.quit() end)
```

### Utiliser les notifications :

```lua
local notifications = require("my-librairie.hud.notification_system")

-- Dans love.update()
notifications.update(dt)

-- Déclencher notifications
notifications.success("Niveau terminé !")
notifications.error("Pas assez d'énergie")
notifications.warning("Santé faible")
```

Ces exemples montrent comment créer des interfaces complètes et réutilisables avec le système HUD.
