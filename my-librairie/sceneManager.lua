-- my-librairie/sceneManager.lua

local scene = {}

--[[ =====================================================================
Options / Debug
- stackMode=false : diffuse update/draw/emit à toutes les scènes
- stackMode=true  : n’envoie qu’à la scène au sommet (pile)
===================================================================== ]]
scene.debug     = true
scene.stackMode = false
scene.color     = { 1, 1, 1, 1 } -- couleur overlay debug éventuel

--[[ =====================================================================
Helpers internes
===================================================================== ]]

-- Appelle obj[method] en essayant (self, argsList...) puis fallback (argsList...)
local function callAny(obj, methodName, argsList)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return false, "no-fn" end

    -- tentative style méthode (self en 1er)
    local ok, r1, r2, r3, r4
    if type(argsList) == "table" then
        ok, r1, r2, r3, r4 = pcall(
            fn, obj,
            argsList[1], argsList[2], argsList[3], argsList[4],
            argsList[5], argsList[6], argsList[7], argsList[8]
        )
    else
        ok, r1, r2, r3, r4 = pcall(fn, obj)
    end
    if ok then return true, r1, r2, r3, r4 end

    -- fallback sans self
    if type(argsList) == "table" then
        ok, r1, r2, r3, r4 = pcall(
            fn,
            argsList[1], argsList[2], argsList[3], argsList[4],
            argsList[5], argsList[6], argsList[7], argsList[8]
        )
    else
        ok, r1, r2, r3, r4 = pcall(fn)
    end
    if ok then return true, r1, r2, r3, r4 end

    return false, r1
end

-- Itère et appelle une méthode si elle existe (argsList est un tableau positionnel)
local function forEachScene(sceneList, methodName, argsList)
    if type(sceneList) ~= "table" then return 0 end
    local calls = 0
    for i = 1, #sceneList do
        local sc = sceneList[i]
        if type(sc) == "table" and type(sc[methodName]) == "function" then
            local ok, err = callAny(sc, methodName, argsList)
            calls = calls + 1
            if not ok and scene.debug then
                local gf = rawget(_G, 'globalFunction')
                local txt = ("[sceneManager] %s.%s failed: %s"):format(tostring(sc.name or "scene"), methodName,
                    tostring(err))
                if gf and gf.log and gf.log.error then gf.log.error(txt) else print(txt) end
            end
        end
    end
    return calls
end

-- require avec fallback "." <-> "/"
local function _tryRequireAny(moduleName)
    local attempts = {}
    local function attempt(name)
        local ok, mod = pcall(require, name)
        if ok and mod then return mod end
        attempts[#attempts + 1] = string.format("require('%s') -> %s", name, tostring(mod))
        return nil
    end

    local mod = attempt(moduleName)
    if not mod then
        local alt = moduleName:gsub("%.", "/")
        if alt ~= moduleName then mod = attempt(alt) end
    end
    if not mod then
        local alt = moduleName:gsub("/", ".")
        if alt ~= moduleName then mod = attempt(alt) end
    end

    return mod, table.concat(attempts, " | ")
end

-- Appelle une fonction-constructeur avec une liste d'arguments (table), sans unpack
local function _constructWithArgs(ctorFn, argList)
    if type(argList) ~= "table" then
        return pcall(ctorFn)
    end
    return pcall(
        ctorFn,
        argList[1], argList[2], argList[3], argList[4],
        argList[5], argList[6], argList[7], argList[8]
    )
end

-- Résout la cible (string|function|table) en instance de scène
local function _resolveTarget(target, ctorArgsList)
    if type(target) == "string" then
        local mod, err = _tryRequireAny(target)
        if not mod then return nil, err end
        target = mod
    elseif type(target) == "function" then
        local ok, inst = _constructWithArgs(target, ctorArgsList)
        if not ok then return nil, "constructeur: " .. tostring(inst) end
        target = inst
    end
    if type(target) ~= "table" then
        return nil, "target invalide: " .. type(target)
    end
    target.name = target.name or target.id or target.__name or target.__type or "scene"
    return target
end


--[[ =====================================================================
API de gestion de liste/pile
===================================================================== ]]

-- Initialise le gestionnaire (liste vide).
function scene:init()
    self.list = self.list or {}
    return self
end

-- Ajoute une scène (table | string -> require | function -> constructeur)
-- ctorArgsList est un tableau d’arguments positionnels pour le constructeur.
function scene:add(sceneOrNameOrCtor, ctorArgsList)
    self.list = self.list or {}

    if sceneOrNameOrCtor == nil then
        if scene.debug then print("[sceneManager] add: argument scene nil (rien ajouté)") end
        return nil
    end

    local s = sceneOrNameOrCtor
    if type(s) == "string" then
        local mod, errLog = _tryRequireAny(s)
        if not mod then
            if scene.debug then print(("[sceneManager] add: require a échoué pour '%s' | %s"):format(s, tostring(errLog))) end
            return nil
        end
        s = mod
    elseif type(s) == "function" then
        local ok, inst = _constructWithArgs(s, ctorArgsList)
        if not ok then
            if scene.debug then print("[sceneManager] add: constructeur a échoué: " .. tostring(inst)) end
            return nil
        end
        s = inst
    end

    if type(s) ~= "table" then
        if scene.debug then print("[sceneManager] add: type invalide, attendu table/string/function, reçu " .. type(s)) end
        return nil
    end

    s.name = s.name or s.id or s.__name or s.__type or "scene"
    table.insert(self.list, s)
    if scene.debug then print(("[sceneManager] added scene: %s"):format(tostring(s.name))) end
    return s
end

-- Retire une scène précise (par instance).
function scene:remove(sceneInstance)
    if type(self.list) ~= "table" then return false end
    for i = #self.list, 1, -1 do
        if self.list[i] == sceneInstance then
            table.remove(self.list, i)
            if scene.debug then
                print(("[sceneManager] removed scene: %s"):format(tostring(sceneInstance and sceneInstance.name or
                    "unnamed")))
            end
            return true
        end
    end
    return false
end

-- Vide la pile/liste de scènes.
function scene:clear()
    self.list = {}
end

-- Retourne la scène au sommet (ou nil).
function scene:top()
    if type(self.list) ~= "table" or #self.list == 0 then return nil end
    return self.list[#self.list]
end

-- Remplace toutes les scènes par une nouvelle scène puis appelle load().
-- ctorArgsList : tableau d'arguments pour un éventuel constructeur (si target est une fonction).
function scene:switch(target, ctorArgsList)
    self.list = self.list or {}

    local tgt, err = _resolveTarget(target, ctorArgsList)
    if not tgt then
        if scene.debug then print("[sceneManager] switch: " .. tostring(err)) end
        return nil
    end

    self:clear()
    self:add(tgt)
    self:load()
    if scene.debug then print("[sceneManager] switch -> " .. tostring(tgt.name)) end
    return tgt
end

-- Empile une nouvelle scène au-dessus et appelle son load() puis enter().
-- ctorArgsList : tableau d'arguments pour un éventuel constructeur (si target est une fonction).
function scene:push(target, ctorArgsList)
    self.list = self.list or {}

    local prevTop = self.list[#self.list]
    if prevTop then callAny(prevTop, "pause") end

    local tgt, err = _resolveTarget(target, ctorArgsList)
    if not tgt then
        if scene.debug then print("[sceneManager] push: " .. tostring(err)) end
        return nil
    end

    table.insert(self.list, tgt)
    callAny(tgt, "load")
    callAny(tgt, "enter")
    if scene.debug then print("[sceneManager] push -> " .. tostring(tgt.name)) end
    return tgt
end

-- Retire n scènes du sommet (défaut 1). Appelle leave/unload, puis resume() sur la nouvelle top.
function scene:pop(count)
    self.list = self.list or {}
    count = tonumber(count) or 1
    if #self.list == 0 then
        if scene.debug then print("[sceneManager] pop: pile déjà vide") end
        return nil
    end

    for i = 1, count do
        local topScene = table.remove(self.list)
        if not topScene then break end
        callAny(topScene, "leave")
        callAny(topScene, "unload")
    end

    local newTop = self.list[#self.list]
    if newTop then
        callAny(newTop, "resume")
        if scene.debug then print("[sceneManager] pop -> " .. tostring(newTop.name)) end
    else
        if scene.debug then print("[sceneManager] pop -> pile vide") end
    end
    return newTop
end

-- alias pratique
scene.pull = scene.pop

--[[ =====================================================================
Boucle de vie (load/update/draw/emit)
- stackMode=false : broadcast à toutes
- stackMode=true  : top-only
===================================================================== ]]

-- Appelle load() sur chaque scène (à appeler depuis love.load via :  scene:load())
function scene:load()
    self.list = self.list or {}

    local calls = 0
    for i = 1, #self.list do
        local sc = self.list[i]
        if sc and type(sc.load) == "function" then
            calls = calls + 1
            local ok, err = pcall(sc.load, sc)
            if not ok then
                print(("[scene] load error in scene '%s' (index %d): %s")
                    :format(tostring(sc.name or "?"), i, tostring(err)))
            end
        end
    end

    if scene.debug then
        print(("[sceneManager] load: %d scène(s) appelées"):format(calls))
    end

    return calls
end

-- Appelle update(dt) (top-only si stackMode)
function scene:update(dt)
    self.list = self.list or {}
    if self.stackMode then
        local topScene = self.list[#self.list]
        if topScene and topScene.update then topScene:update(dt) end
        return
    end
    for i = 1, #self.list do
        local sc = self.list[i]
        if sc and sc.update then sc:update(dt) end
    end
end

-- Appelle draw() (top-only si stackMode). À appeler depuis love.draw via :  scene:draw()
function scene:draw()
    self.list = self.list or {}

    if self.stackMode then
        local topScene = self.list[#self.list]
        if topScene and type(topScene.draw) == "function" and topScene.hidden ~= true then
            local ok, err = pcall(topScene.draw, topScene)
            if not ok then
                print(("[scene] draw error in top scene '%s': %s")
                    :format(tostring(topScene.name or ("#" .. tostring(#self.list))), tostring(err)))
            end
        end
        return
    end

    for i = 1, #self.list do
        local sc = self.list[i]
        if sc and type(sc.draw) == "function" and sc.hidden ~= true then
            local ok, err = pcall(sc.draw, sc)
            if not ok then
                print(("[scene] draw error in scene '%s' (index %d): %s")
                    :format(tostring(sc.name or "?"), i, tostring(err)))
            end
        end
    end
end

-- Dispatche un évènement arbitraire (top-only si stackMode)
-- Exemple : scene:emit("mousepressed", x, y, button)
function scene:emit(eventName, p1, p2, p3, p4, p5, p6, p7, p8)
    if type(eventName) ~= "string" or eventName == "" then return end
    self.list = self.list or {}

    local function dispatch(targetScene)
        if not targetScene then return false end
        local fn = targetScene[eventName]
        if type(fn) ~= "function" then return false end

        local ok, consumed = pcall(fn, targetScene, p1, p2, p3, p4, p5, p6, p7, p8)
        if not ok then
            if scene.debug then
                print(("[sceneManager] %s.%s failed: %s")
                    :format(tostring(targetScene.name or "scene"), eventName, tostring(consumed)))
            end
            return false
        end
        return consumed == true
    end

    if scene.stackMode then
        local topScene = self.list[#self.list]
        if topScene then dispatch(topScene) end
        return
    end

    for i = #self.list, 1, -1 do
        if dispatch(self.list[i]) then
            break
        end
    end
end

function scene:mousepressed(x, y, button, istouch, presses)
    return self:emit("mousepressed", x, y, button, istouch, presses)
end

function scene:keypressed(key, scancode, isrepeat)
    return self:emit("keypressed", key, scancode, isrepeat)
end

function scene:mousemoved(x, y, dx, dy, istouch)
    return self:emit("mousemoved", x, y, dx, dy, istouch)
end

function scene:wheelmoved(dx, dy)
    return self:emit("wheelmoved", dx, dy)
end

--[[ =====================================================================
Utilitaires
===================================================================== ]]

-- Compte le nombre de scènes dans la pile
function scene:count()
    self.list = self.list or {}
    return #self.list
end

-- Retourne la table des scènes (pile)
function scene:get()
    self.list = self.list or {}
    return self.list
end

-- init par défaut à l'import
scene:init()

return scene
