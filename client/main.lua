if not FBBridge.ready() then return end
local states, props, calibrations, frozen, secured = {}, {}, {}, {}, {}
local modelNames, modelHashes = {}, {}
local currentOperation, selecting, requestBusy, debugTruck
local rampBounds
local remotes = {}
local pendingRestore = {}
local function stopRemoteAnimation()
    if Config.Remote.enabled then StopAnimTask(PlayerPedId(), Config.Remote.dict, Config.Remote.clip, 2.0) end
end
for name in pairs(Config.Models) do
    modelNames[joaat(name)] = name
    modelHashes[#modelHashes + 1] = joaat(name)
end
local function notify(text, kind)
    FBBridge.notify({ title = 'TroyScripts • Flatbed', description = text, type = kind or 'inform' })
end
local function networkEntity(id)
    if not id or not NetworkDoesEntityExistWithNetworkId(id) then return 0 end
    return NetToVeh(id)
end
local function net(entity)
    if not NetworkGetEntityIsNetworked(entity) then return nil end
    return VehToNet(entity)
end
local function state(truck) return states[net(truck)] end
local function control(entity)
    if not DoesEntityExist(entity) then return false end
    local untilTime = GetGameTimer() + Config.ControlTimeout
    repeat
        if NetworkHasControlOfEntity(entity) then return true end
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    until GetGameTimer() > untilTime or not DoesEntityExist(entity)
    return false
end
local function occupied(car)
    for seat = -1, GetVehicleMaxNumberOfPassengers(car) - 1 do
        if not IsVehicleSeatFree(car, seat, false) then return true end
    end
    return false
end
local function prepareRamp()
    local hash = joaat(Config.RampModel)
    if rampBounds and HasModelLoaded(hash) and HasCollisionForModelLoaded(hash) then return true end
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        notify('Oprijplaatmodel ontbreekt: '..Config.RampModel, 'error'); return false
    end
    local ok = pcall(lib.requestModel, hash, 5000)
    if not ok then notify('Oprijplaten konden niet geladen worden.', 'error'); return false end
    local deadline = GetGameTimer() + 5000
    repeat
        RequestCollisionForModel(hash)
        if HasCollisionForModelLoaded(hash) then break end
        Wait(0)
    until GetGameTimer() > deadline
    if not HasCollisionForModelLoaded(hash) then
        notify('Botsingsmodel van de rijplaten kon niet geladen worden.', 'error'); return false
    end
    local low, high = GetModelDimensions(hash)
    rampBounds = { low = low, high = high }
    return true
end
local function profile(truck)
    local low = GetModelDimensions(GetEntityModel(truck))
    local d = Config.Defaults
    local p = {
        rearY = low.y + d.rearInset, deckZ = low.z + d.deckHeightFromBottom,
        loadY = low.y + d.rearInset + d.loadFromRear,
        frontY = low.y + d.rearInset + d.frontFromRear,
        rampX = d.rampX, rampY = d.rampY, rampZ = d.rampZ,
        rampPitch = d.rampPitch, rampYaw = d.rampYaw
    }
    local name = modelNames[GetEntityModel(truck)]
    for k, v in pairs(Config.Profiles[name] or {}) do p[k] = v end
    for k, v in pairs(calibrations[name] or {}) do p[k] = v end
    return p
end
local function cast(a, b, flags, ignore)
    local h = StartShapeTestRay(a.x, a.y, a.z, b.x, b.y, b.z, flags, ignore or 0, 7)
    local deadline = GetGameTimer() + 500
    repeat
        local status, hit, pos, normal, ent = GetShapeTestResult(h)
        if status == 2 then return hit == 1, pos, ent end
        if status == 0 then return false end
        Wait(0)
    until GetGameTimer() > deadline
    return false
end
local function measureDeck(truck, p)
    -- Alleen zonder handmatige afstelling: meet de botsingslaag van de echte laadbak.
    local name = modelNames[GetEntityModel(truck)]
    if calibrations[name] or (Config.Profiles[name] and Config.Profiles[name].deckZ) then return end
    local a = GetOffsetFromEntityInWorldCoords(truck, 0.55, p.rearY + 1.4, p.deckZ + 3.0)
    local b = GetOffsetFromEntityInWorldCoords(truck, 0.55, p.rearY + 1.4, p.deckZ - 1.0)
    local hit, pos, ent = cast(a, b, 2, PlayerPedId())
    if hit and ent == truck then
        local offset = GetOffsetFromEntityGivenWorldCoords(truck, pos.x, pos.y, pos.z)
        if math.abs(offset.z - p.deckZ) < 1.2 then p.deckZ = offset.z end
    end
end
local function geometry(truck)
    if not prepareRamp() then return end
    local p = profile(truck)
    measureDeck(truck, p)
    local lo, hi = rampBounds.low, rampBounds.high
    local length = hi.y - lo.y
    local outside = GetOffsetFromEntityInWorldCoords(truck, 0, p.rearY - length, p.deckZ)
    local found, ground = GetGroundZFor_3dCoord(outside.x, outside.y, outside.z + 3.0, false)
    if not found then notify('Geen grond gevonden achter de vrachtwagen.', 'error'); return end
    local groundLocal = GetOffsetFromEntityGivenWorldCoords(truck, outside.x, outside.y, ground)
    local rise = p.deckZ - groundLocal.z
    if rise <= 0.1 or rise >= length * 0.65 then
        notify('Hoogteverschil ongeschikt. Zet de truck vlak of gebruik /flatbedafstellen.', 'error'); return
    end
    local angle = math.asin(rise / length) - math.atan(Config.RampNativeRise, length)
    local yaw = (Config.RampHighEnd == -1 and 180.0 or 0.0) + p.rampYaw
    local pitch = math.deg(angle) + p.rampPitch
    -- Bereken het hoogste aansluitpunt met dezelfde GTA-rotatie als het uiteindelijke object.
    local pos = GetEntityCoords(truck)
    local helper = CreateObjectNoOffset(joaat(Config.RampModel), pos.x, pos.y, pos.z + 15, false, false, false)
    if helper == 0 then notify('Oprijplaat kon niet worden gemaakt.', 'error'); return end
    SetEntityVisible(helper, false, false)
    SetEntityCollision(helper, false, false)
    SetEntityRotation(helper, pitch, 0.0, yaw, 2, true)
    local h = GetOffsetFromEntityInWorldCoords(helper, 0.0, Config.RampHighEnd == -1 and lo.y or hi.y, hi.z)
    local origin = GetEntityCoords(helper)
    local delta = h - origin
    DeleteEntity(helper)
    return {
        rearY = p.rearY, toeY = p.rearY - math.sqrt(length * length - rise * rise),
        deckZ = p.deckZ, groundZ = groundLocal.z, loadY = p.loadY, frontY = p.frontY,
        rampX = -delta.x + p.rampX, rampY = p.rearY - delta.y + p.rampY,
        rampZ = p.deckZ - delta.z + p.rampZ, rampPitch = pitch, rampYaw = yaw
    }
end
local function removeProp(id)
    if props[id] and DoesEntityExist(props[id].entity) then DeleteEntity(props[id].entity) end
    props[id] = nil
end
local function attach(car, truck, pos, pitch)
    -- -1: voertuigorigin in plaats van een modelspecifiek chassis-bot.
    AttachEntityToEntity(car, truck, -1, pos.x, pos.y, pos.z,
        pitch or 0.0, 0.0, 0.0, false, false, false, false, 2, true)
end
local function freeCar(car, origin)
    if car == 0 or not DoesEntityExist(car) then return end
    DetachEntity(car, true, true)
    SetVehicleHandbrake(car, false)
    if origin then
        SetEntityCoordsNoOffset(car, origin.x, origin.y, origin.z, false, false, false)
        SetEntityHeading(car, origin.heading)
        SetEntityVelocity(car, 0.0, 0.0, 0.0)
    end
end
RegisterNetEvent('ts_flatbed:state', function(id, data)
    -- Alleen serverberichten verwerken.
    if source ~= 65535 then return end
    states[id] = data or nil
    if data and data.target then pendingRestore[data.target] = nil end
    if data and data.liftTarget then pendingRestore[data.liftTarget] = nil end
    if not data or not data.ramps then removeProp(id) end
end)
RegisterNetEvent('ts_flatbed:calibrations', function(data)
    if source ~= 65535 then return end
    calibrations = data
end)
RegisterNetEvent('ts_flatbed:restore', function(id, origin, model)
    if source ~= 65535 then return end
    local car = networkEntity(id)
    pendingRestore[id] = { origin = origin, model = model, untilTime = GetGameTimer() + 5000 }
    if car ~= 0 and GetEntityModel(car) == model and NetworkHasControlOfEntity(car) then
        freeCar(car, origin); pendingRestore[id] = nil
    end
    secured[id] = nil
end)

local function eligible(car, truck, onBed, requireFit)
    if car == 0 or car == truck or not DoesEntityExist(car) or not net(car) then return false, 'Ongeldig voertuig.' end
    if IsEntityAttached(car) or modelNames[GetEntityModel(car)] then return false, 'Dit voertuig is al gekoppeld of zelf een flatbed.' end
    if occupied(car) then return false, 'Laat iedereen uit het voertuig stappen.' end
    if GetEntitySpeed(car) > 0.5 then return false, 'Het voertuig moet stilstaan.' end
    local cls = GetVehicleClass(car)
    if cls == 14 or cls == 15 or cls == 16 or cls == 21 then return false, 'Dit voertuigtype kan niet op de laadbak.' end
    local low, high = GetModelDimensions(GetEntityModel(car))
    local r = state(truck)
    if not r or not r.geometry then return false, 'Plaats eerst de rijplaten.' end
    local g = r.geometry
    local pos = GetEntityCoords(car)
    local offset = GetOffsetFromEntityGivenWorldCoords(truck, pos.x, pos.y, pos.z)
    if onBed then
        if math.abs(offset.x) > 0.65 or offset.y + low.y < g.rearY - 0.25
            or offset.y + high.y > g.frontY + 0.25 or math.abs(offset.z + low.z - g.deckZ) > 0.6 then
            return false, 'Zet het voertuig recht en volledig op de laadbak.'
        end
    else
        if math.abs(offset.x) > 0.8 or offset.y + high.y > g.toeY + 0.5
            or #(pos - GetEntityCoords(truck)) > Config.MaxCableLength then
            return false, 'Zet de auto recht achter de rijplaten, met de neus naar de vrachtwagen.'
        end
    end
    local heading = math.abs((GetEntityHeading(car) - GetEntityHeading(truck) + 180) % 360 - 180)
    if heading > 12 then return false, 'De auto moet dezelfde kant op wijzen als de vrachtwagen.' end
    local plan, reason = FB.cargoPlan(low, high, g, requireFit or onBed)
    if not plan then
        print(('[ts_flatbed] Model %s | %s | min %s | max %s'):format(GetEntityModel(car),reason,low,high))
        return false, reason
    end
    return true, nil, plan.z, plan.y
end
local function areaClear(truck, car, g)
    -- Vrije laadstrook; eigen truck, lading en bediener zijn uitgezonderd.
    for _, kind in ipairs({'CVehicle', 'CPed'}) do
        for _, e in ipairs(GetGamePool(kind)) do
            if e ~= truck and e ~= car and e ~= PlayerPedId() then
                local c = GetEntityCoords(e)
                local p = GetOffsetFromEntityGivenWorldCoords(truck, c.x, c.y, c.z)
                if math.abs(p.x) < 1.6 and p.y < g.frontY and p.y > g.toeY - 7
                    and math.abs(p.z - g.groundZ) < 4 then return false end
            end
        end
    end
    return true
end

local function runOperation(action, truck, reply)
    local r, token = reply.state, reply.token
    local car, id = networkEntity(r.target), r.id
    local origin
    if car ~= 0 then
        local c = GetEntityCoords(car)
        origin = { x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(car) }
    end
    currentOperation = { id = id, car = car, action = action, token = token, state = r, origin = origin }
    local success = false
    local ok, err = xpcall(function()
        if car == 0 or not control(truck) or not control(car) then error('Geen netwerkcontrole. Probeer opnieuw wanneer de bestuurder is uitgestapt.') end
        if occupied(car) or not areaClear(truck, car, r.geometry) then error('Maak de laadstrook vrij van voertuigen en personen.') end
        local g = r.geometry
        local c = GetEntityCoords(car)
        local start = GetOffsetFromEntityGivenWorldCoords(truck, c.x, c.y, c.z)
        local low, high = GetModelDimensions(GetEntityModel(car))
        local half = (high.y - low.y) * 0.32
        local endY = action == 'unload' and g.toeY - high.y - 0.75 or r.load.y
        local duration = action == 'secure' and 1400 or math.max(1800, math.abs(endY - start.y) / Config.PullSpeed * 1000)
        if duration > Config.OperationTimeout - 5000 then error('Auto te ver weg voor deze liersnelheid.') end
        if Config.Remote.enabled then
            lib.requestAnimDict(Config.Remote.dict, 5000)
            SetCurrentPedWeapon(PlayerPedId(), joaat('WEAPON_UNARMED'), true)
            TaskPlayAnim(PlayerPedId(), Config.Remote.dict, Config.Remote.clip, 3.0, 3.0, -1, 49, 0.0, false, false, false)
        end
        local started = GetGameTimer()
        local lastCheck = 0
        lib.showTextUI('[BACKSPACE] Laden/lossen afbreken', { icon = 'truck-ramp-box' })
        while true do
            Wait(0)
            local now = GetGameTimer()
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 23, true)
            if IsControlJustPressed(0, 177) then error('Lier afgebroken.') end
            if not DoesEntityExist(truck) or not DoesEntityExist(car) then error('Voertuig verdwenen.') end
            local live = states[id]
            if not live or not live.busy or live.target ~= r.target then error('Laadopdracht beëindigd door de server.') end
            if not NetworkHasControlOfEntity(car) then error('Netwerkcontrole verloren; laadpoging gestopt.') end
            if GetEntitySpeed(truck) > 0.3 or FBBridge.dead(PlayerPedId()) or IsPedRagdoll(PlayerPedId()) or IsPedInAnyVehicle(PlayerPedId(), false)
                or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(truck)) > Config.ServerDistance - 1 then error('Blijf naast de stilstaande vrachtwagen.') end
            if now - lastCheck > 300 then
                if occupied(car) or not areaClear(truck, car, g) then error('Laadstrook geblokkeerd of voertuig bezet.') end
                lastCheck = now
            end
            local t = FB.clamp((now - started) / duration, 0, 1)
            local y = FB.lerp(start.y, endY, t)
            local z, pitch = FB.pose(y, g, half, low.z)
            if action == 'secure' then
                z, pitch = FB.lerp(start.z, r.load.z, t), 0
            else
                -- Neem de bestaande veringhoogte in de eerste halve meter vloeiend over.
                local startZ = FB.pose(start.y, g, half, low.z)
                z = z + (start.z - startZ) * (1 - FB.clamp(t * 8, 0, 1))
            end
            attach(car, truck, { x = start.x * (1 - t), y = y, z = z }, pitch)
            SetVehicleHandbrake(car, true)
            if t >= 1 then break end
        end
        if action == 'unload' then
            freeCar(car)
            SetVehicleOnGroundProperly(car)
            SetEntityVelocity(car, 0, 0, 0)
        else
            attach(car, truck, r.load, 0)
        end
        success = true
    end, function(e) return tostring(e) end)
    lib.hideTextUI()
    stopRemoteAnimation()
    if not ok then
        if car ~= 0 and DoesEntityExist(car) and NetworkHasControlOfEntity(car) then
            if action == 'unload' and DoesEntityExist(truck) then attach(car, truck, r.load, 0)
            else freeCar(car, origin) end
        end
        notify(err, 'error')
    end
    TriggerServerEvent('ts_flatbed:finish', id, token, success)
    currentOperation = nil
    if success then notify(action == 'unload' and 'Voertuig afgeladen.' or 'Voertuig staat vast op de laadbak.', 'success') end
end

local function action(name, truck, target)
    if requestBusy or currentOperation then return end
    requestBusy = true
    local ok, err = xpcall(function()
        if not DoesEntityExist(truck) or not net(truck) then return end
        if IsPedInAnyVehicle(PlayerPedId(), false) then notify('Stap eerst uit.', 'error'); return end
        if GetEntitySpeed(truck) > 0.3 then notify('Zet de vrachtwagen stil.', 'error'); return end
        local data
        if name == 'rampsOn' then
            if math.abs(GetEntityPitch(truck)) > Config.MaxSlope or math.abs(GetEntityRoll(truck)) > Config.MaxSlope then
                notify('Zet de vrachtwagen op een vlakke plek.', 'error'); return
            end
            data = geometry(truck)
            if not data then return end
            if not FB.validGeometry(data) then notify('Afstelling ongeldig. Gebruik /flatbedafstellen.', 'error'); return end
        elseif name == 'rampsOff' then
            local r = state(truck)
            if r and not areaClear(truck, networkEntity(r.target), r.geometry) then
                notify('Er staat iemand of een voertuig bij de rijplaten.', 'error'); return
            end
        elseif name == 'hook' or name == 'secure' then
            local valid, reason, z, y = eligible(target, truck, name == 'secure', name == 'secure')
            if not valid then notify(reason, 'error'); return end
            data = { z = z, y = y }
        elseif name == 'load' then
            local r = state(truck)
            if not r then return end
            local valid, reason, z, y = eligible(networkEntity(r.target), truck, false, true)
            if not valid then notify(reason, 'error'); return end
            data = { z = z, y = y }
        end
        if name == 'rampsOn' or name == 'rampsOff' or name == 'hook' then
            if not FBBridge.progress({ duration = 1800, label = name == 'hook' and 'Lier aansluiten' or 'Rijplaten verplaatsen',
                position = 'bottom', canCancel = true, disable = { move = true, car = true, combat = true },
                anim = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base' } }) then return end
        end
        local reply = lib.callback.await('ts_flatbed:action', false, name, net(truck), target and net(target), data)
        if not reply or not reply.ok then notify(reply and reply.message or 'Server reageert niet.', 'error'); return end
        if reply.token then
            states[net(truck)] = reply.state
            runOperation(name, truck, reply)
        else
            local messages = { rampsOn = 'Rijplaten geplaatst. De vrachtwagen staat vast.', rampsOff = 'Rijplaten opgeborgen.',
                hook = 'Lier aangesloten. Kies nu Lier binnenhalen op de vrachtwagen.', unhook = 'Lier losgemaakt.', release = 'Voertuig losgemaakt op de laadbak.' }
            notify(messages[name] or 'Gereed.', 'success')
        end
    end, function(e) return tostring(e) end)
    requestBusy = false
    if not ok then print('[ts_flatbed] '..err); notify('Actie mislukt. Zie F8 voor details.', 'error') end
end
local function selectCar(truck, secure)
    selecting = { truck = truck, secure = secure, at = GetGameTimer() }
    lib.showTextUI('[ALT] Kies het voertuig • [BACKSPACE] Annuleren', { icon = 'link' })
end
local function showMenu(truck)
    local r = state(truck) or {}
    lib.registerContext({ id = 'ts_flatbed_menu', title = 'TroyScripts • Flatbed', options = {
        { title = r.ramps and 'Rijplaten opbergen' or 'Rijplaten plaatsen', icon = 'truck-ramp-box', disabled = r.busy or r.lift or (r.target and r.stage ~= 'loaded'),
            onSelect = function() action(r.ramps and 'rampsOff' or 'rampsOn', truck) end },
        { title = 'Lier aansluiten op voertuig', icon = 'link', disabled = not r.ramps or r.target ~= nil or r.busy,
            onSelect = function() selectCar(truck, false) end },
        { title = 'Lier binnenhalen / voertuig laden', icon = 'angles-up', disabled = r.stage ~= 'hooked' or r.busy,
            onSelect = function() action('load', truck) end },
        { title = 'Lier losmaken', icon = 'link-slash', disabled = r.stage ~= 'hooked' or r.busy,
            onSelect = function() action('unhook', truck) end },
        { title = 'Voertuig op laadbak vastzetten', icon = 'lock', disabled = not r.ramps or r.target ~= nil or r.busy,
            onSelect = function() selectCar(truck, true) end },
        { title = 'Voertuig met lier afladen', icon = 'angles-down', disabled = not r.ramps or r.stage ~= 'loaded' or r.busy,
            onSelect = function() action('unload', truck) end },
        { title = 'Voertuig losmaken op laadbak', description = 'Voor zelf achteruit afrijden.', icon = 'unlock',
            disabled = not r.ramps or r.stage ~= 'loaded' or r.busy, onSelect = function() action('release', truck) end },
        { title = 'Lepel voor tweede auto', description = 'Uitklappen, koppelen en losmaken.', icon = 'truck-pickup',
            disabled = not Config.WheelLift.enabled or r.ramps or r.busy,
            onSelect = function() FBWheel.menu(truck) end }
    } })
    lib.showContext('ts_flatbed_menu')
end

local function closestTruck()
    local best, dist = nil, Config.ServerDistance
    for _, v in ipairs(GetGamePool('CVehicle')) do
        if modelNames[GetEntityModel(v)] then
            local d = #(GetEntityCoords(v) - GetEntityCoords(PlayerPedId()))
            if d < dist then best, dist = v, d end
        end
    end
    return best
end
RegisterCommand('flatbed', function()
    local truck = closestTruck()
    if truck then showMenu(truck) else notify('Geen ondersteunde flatbed in de buurt.', 'error') end
end, false)
RegisterCommand('flatbedafstellen', function()
    local truck = closestTruck()
    if not truck or not net(truck) then notify('Ga naast de flatbed staan.', 'error'); return end
    local auth = lib.callback.await('ts_flatbed:admin', false, net(truck))
    if not auth or not auth.ok then notify(auth and auth.message or 'Geen antwoord.', 'error'); return end
    local p = profile(truck)
    measureDeck(truck, p)
    local fields = {
        {'rearY', 'Achterrand laadbak (Y)'}, {'deckZ', 'Bovenkant laadbak (Z)'},
        {'loadY', 'Midden geladen auto (Y)'}, {'frontY', 'Voorrand laadbak (Y)'},
        {'rampX', 'Correctie rijplaten links/rechts'}, {'rampY', 'Correctie rijplaten voor/achter'},
        {'rampZ', 'Correctie rijplaten hoogte'}, {'rampPitch', 'Correctie hellingshoek'}, {'rampYaw', 'Correctie draairichting'}
    }
    local inputs = {}
    for _, f in ipairs(fields) do inputs[#inputs+1] = { type = 'number', label = f[2], default = p[f[1]], required = true, precision = 3, step = 0.05 } end
    local values = FBBridge.input('Flatbed afstellen • meters / graden', inputs)
    if not values then return end
    local data = {}
    for i, f in ipairs(fields) do data[f[1]] = values[i] end
    local saved = lib.callback.await('ts_flatbed:admin', false, net(truck), data)
    notify(saved and saved.ok and 'Afstelling opgeslagen. Plaats de rijplaten opnieuw.' or (saved and saved.message or 'Geen antwoord.'), saved and saved.ok and 'success' or 'error')
end, false)
RegisterCommand('flatbedmeten', function()
    local truck = closestTruck()
    if not truck then notify('Geen flatbed in de buurt.', 'error'); return end
    local auth = lib.callback.await('ts_flatbed:admin', false, net(truck))
    if not auth or not auth.ok then notify('Geen afstelrechten.', 'error'); return end
    debugTruck = debugTruck == truck and nil or truck
    local lo, hi = GetModelDimensions(GetEntityModel(truck))
    print(('[ts_flatbed] Model: %s | min: %s | max: %s'):format(modelNames[GetEntityModel(truck)], lo, hi))
    notify(debugTruck and 'Meetweergave aan. Rode marker: achterrand; groen: laadpositie. /flatbedmeten schakelt uit.' or 'Meetweergave uit.')
end, false)

CreateThread(function()
    FBBridge.addVehicle({{
        name = 'ts_flatbed_control', label = 'Flatbed bedienen', icon = 'fa-solid fa-truck-ramp-box',
        distance = Config.InteractionDistance,
        canInteract = function(e) return modelNames[GetEntityModel(e)] ~= nil and not currentOperation and not selecting and not IsPedInAnyVehicle(PlayerPedId(), false) end,
        onSelect = function(data) showMenu(data.entity) end
    }})
    FBBridge.addVehicle({{
        name = 'ts_flatbed_select', label = 'Dit voertuig koppelen', icon = 'fa-solid fa-link', distance = Config.InteractionDistance,
        canInteract = function(e) return selecting ~= nil and e ~= selecting.truck end,
        onSelect = function(data)
            local choice = selecting
            selecting = nil; lib.hideTextUI()
            if choice then action(choice.secure and 'secure' or 'hook', choice.truck, data.entity) end
        end
    }})
    local snapshot = lib.callback.await('ts_flatbed:snapshot', false)
    if snapshot then
        calibrations = snapshot.calibrations or {}
        for id, r in pairs(snapshot.records or {}) do
            id = tonumber(id)
            if not states[id] or (states[id].revision or 0) <= (r.revision or 0) then states[id] = r end
        end
    end
    while true do
        Wait(400)
        local here, wanted, wantFrozen, wantSecured = GetEntityCoords(PlayerPedId()), {}, {}, {}
        for id, r in pairs(states) do
            local truck = networkEntity(id)
            if truck ~= 0 and modelNames[GetEntityModel(truck)] == r.model and #(GetEntityCoords(truck) - here) < Config.StreamDistance then
                if r.ramps then
                    wanted[id], wantFrozen[truck] = true, true
                    FreezeEntityPosition(truck, true)
                    if props[id] and (not DoesEntityExist(props[id].entity) or props[id].truck ~= truck) then removeProp(id) end
                    if not props[id] and prepareRamp() then
                        local pos, g = GetEntityCoords(truck), r.geometry
                        local obj = CreateObjectNoOffset(joaat(Config.RampModel), pos.x, pos.y, pos.z, false, false, false)
                        if obj ~= 0 then
                            SetEntityAsMissionEntity(obj, true, true)
                            AttachEntityToEntity(obj, truck, -1, g.rampX, g.rampY, g.rampZ, g.rampPitch, 0.0, g.rampYaw, false, false, false, false, 2, true)
                            -- Gebruik de attachment alleen voor de exacte wereldtransformatie.
                            -- De truck staat stil: de plaat kan zelfstandig collision dragen.
                            ProcessEntityAttachments(truck)
                            DetachEntity(obj, false, true)
                            SetEntityCollision(obj, true, true)
                            SetEntityLoadCollisionFlag(obj, true)
                            FreezeEntityPosition(obj, true)
                            props[id] = { entity = obj, truck = truck }
                        end
                    end
                end
                if r.target then
                    local car = networkEntity(r.target)
                    if car ~= 0 and r.stage == 'loaded' then
                        wantSecured[r.target] = { car = car, truck = truck, revision = r.revision }
                        if NetworkHasControlOfEntity(car) then
                            if not IsEntityAttachedToEntity(car, truck) or not secured[r.target] or secured[r.target].revision ~= r.revision then attach(car, truck, r.load, 0) end
                            SetVehicleHandbrake(car, true)
                        end
                    elseif car ~= 0 and r.stage == 'moving' then
                        -- Niet losmaken terwijl een andere client de laadanimatie uitvoert.
                        wantSecured[r.target] = { car = car, truck = truck, revision = r.revision }
                    end
                end
            end
        end
        for id, prop in pairs(props) do if not wanted[id] or not DoesEntityExist(prop.truck) then removeProp(id) end end
        for truck in pairs(frozen) do if not wantFrozen[truck] and DoesEntityExist(truck) then FreezeEntityPosition(truck, false) end end
        for id, pair in pairs(secured) do
            if not wantSecured[id] and DoesEntityExist(pair.car) and NetworkHasControlOfEntity(pair.car)
                and IsEntityAttachedToEntity(pair.car, pair.truck) then freeCar(pair.car) end
        end
        frozen, secured = wantFrozen, wantSecured
        for id, pending in pairs(pendingRestore) do
            local car = networkEntity(id)
            if GetGameTimer() > pending.untilTime then pendingRestore[id] = nil
            elseif car ~= 0 and GetEntityModel(car) == pending.model and NetworkHasControlOfEntity(car) then
                freeCar(car, pending.origin); pendingRestore[id] = nil
            end
        end
    end
end)

-- Iedereen maakt lokaal één visuele afstandsbediening voor de server-bevestigde
-- bediener. Geen dubbele netwerkprops en ook zichtbaar voor latere toeschouwers.
CreateThread(function()
    if not Config.Remote.enabled then return end
    local cfg, hash = Config.Remote, joaat(Config.Remote.model)
    while true do
        Wait(250)
        local wanted = {}
        for _, r in pairs(states) do
            if (r.busy or r.remoteActive) and r.operator then
                local player = GetPlayerFromServerId(r.operator)
                if player ~= -1 then
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) and not IsEntityDead(ped) and #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) < Config.StreamDistance then
                        wanted[r.operator] = ped
                    end
                end
            end
        end
        for actor, obj in pairs(remotes) do
            if not wanted[actor] or not IsEntityAttachedToEntity(obj, wanted[actor]) then
                if DoesEntityExist(obj) then DeleteEntity(obj) end
                remotes[actor] = nil
            end
        end
        for actor, ped in pairs(wanted) do
            if not remotes[actor] and IsModelInCdimage(hash) and pcall(lib.requestModel, hash, 2000) then
                local pos = GetEntityCoords(ped)
                local obj = CreateObjectNoOffset(hash, pos.x, pos.y, pos.z, false, false, false)
                if obj ~= 0 then
                    local o, rot = cfg.offset, cfg.rotation
                    SetEntityCollision(obj, false, false)
                    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, cfg.bone), o.x,o.y,o.z,rot.x,rot.y,rot.z,false,false,false,true,2,true)
                    remotes[actor] = obj
                end
                SetModelAsNoLongerNeeded(hash)
            end
        end
    end
end)

-- Kleine interne interface voor de lepelmodule, geen externe framework-bridge.
FlatbedClient = {
    entity=networkEntity, net=net, state=state, profile=profile, control=control,
    notify=notify, occupied=occupied, closestTruck=closestTruck, freeCar=freeCar, attachCargo=attach,
    states=function() return states end,
    setState=function(id, value) states[id]=value end
}

CreateThread(function()
    while true do
        local sleep = 400
        if selecting then
            sleep = 0
            if IsControlJustPressed(0, 177) or GetGameTimer() - selecting.at > 60000
                or not DoesEntityExist(selecting.truck) or IsEntityDead(PlayerPedId()) then selecting = nil; lib.hideTextUI() end
        end
        for id, r in pairs(states) do
            if r.target and (r.stage == 'hooked' or r.stage == 'moving') then
                local truck, car = networkEntity(id), networkEntity(r.target)
                if truck ~= 0 and car ~= 0 and #(GetEntityCoords(truck) - GetEntityCoords(PlayerPedId())) < Config.StreamDistance then
                    sleep = 0
                    local g = r.geometry
                    local _, high = GetModelDimensions(GetEntityModel(car))
                    local a = GetOffsetFromEntityInWorldCoords(truck, 0.0, g.frontY - 0.25, g.deckZ + 0.25)
                    local b = GetOffsetFromEntityInWorldCoords(car, 0.0, high.y - 0.15, 0.0)
                    for _, z in ipairs({0.0, 0.008, -0.008}) do DrawLine(a.x,a.y,a.z+z,b.x,b.y,b.z+z,75,75,75,255) end
                end
            end
        end
        if debugTruck and DoesEntityExist(debugTruck) then
            sleep = 0
            local active = state(debugTruck)
            local p = active and active.geometry or profile(debugTruck)
            for i, y in ipairs({p.rearY, p.loadY, p.frontY}) do
                local c = GetOffsetFromEntityInWorldCoords(debugTruck, 0, y, p.deckZ + 0.08)
                DrawMarker(28,c.x,c.y,c.z,0,0,0,0,0,0,0.16,0.16,0.16,i==1 and 255 or 0,i==2 and 255 or 0,i==3 and 255 or 0,200,false,false,2,false,nil,nil,false)
            end
            local feet = GetPedBoneCoords(PlayerPedId(), 14201, 0,0,0)
            local o = GetOffsetFromEntityGivenWorldCoords(debugTruck, feet.x,feet.y,feet.z)
            SetTextFont(0); SetTextScale(0.0,0.33); SetTextColour(255,255,255,255); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(('Flatbed meten | linkervoet X %.3f / Y %.3f / Z %.3f~n~Rood: achterrand | Groen: laadpositie | Blauw: voorrand'):format(o.x,o.y,o.z))
            EndTextCommandDisplayText(0.02,0.78)
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    lib.hideTextUI()
    stopRemoteAnimation()
    for _, obj in pairs(remotes) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    if GetResourceState('ox_target') == 'started' then
        FBBridge.removeVehicle('ts_flatbed_control')
        FBBridge.removeVehicle('ts_flatbed_select')
    end
    for id in pairs(props) do removeProp(id) end
    for truck in pairs(frozen) do if DoesEntityExist(truck) then FreezeEntityPosition(truck, false) end end
    if currentOperation then
        local op = currentOperation
        if DoesEntityExist(op.car) and NetworkHasControlOfEntity(op.car) then freeCar(op.car, op.action ~= 'unload' and op.origin or nil) end
    end
    for _, pair in pairs(secured) do
        if DoesEntityExist(pair.car) and NetworkHasControlOfEntity(pair.car) then freeCar(pair.car) end
    end
    for _, r in pairs(states) do
        local car = networkEntity(r.target)
        if car ~= 0 and NetworkHasControlOfEntity(car) and IsEntityAttachedToEntity(car, networkEntity(r.id)) then freeCar(car) end
    end
end)
