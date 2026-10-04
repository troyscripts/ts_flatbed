if not FBBridge.ready() then return end
local records, cargoOwners, limits, calibrations = {}, {}, {}, {}
local serial = 0
local models = {}
for name in pairs(Config.Models) do models[joaat(name)] = name end
local raw = LoadResourceFile(GetCurrentResourceName(), 'calibration.json')
if raw then
    local ok, value = pcall(json.decode, raw)
    if ok and type(value) == 'table' then calibrations = value end
end

local function entity(id)
    if not FB.finite(id, 1, 65535) or id % 1 ~= 0 then return 0 end
    local e = NetworkGetEntityFromNetworkId(id)
    return e ~= 0 and DoesEntityExist(e) and e or 0
end
local function allowed(src)
    if Config.UseAce and not IsPlayerAceAllowed(src, Config.UseAce) then return false end
    if Config.Jobs then
        local job = FBBridge.job(src)
        local grade = job and Config.Jobs[job.name]
        return grade ~= nil and tonumber(job.grade) >= grade
    end
    return true
end
local function near(src, truck)
    local ped = GetPlayerPed(src)
    return ped ~= 0 and DoesEntityExist(ped) and GetEntityHealth(ped) > 0
        and GetPlayerRoutingBucket(src) == GetEntityRoutingBucket(truck)
        and #(GetEntityCoords(ped) - GetEntityCoords(truck)) <= Config.ServerDistance
        and GetVehiclePedIsIn(ped, false) == 0
end
local function empty(car)
    -- Ook NPC-passagiers uitsluiten; niet alleen de bestuurder.
    for _, ped in ipairs(GetAllPeds()) do
        if GetVehiclePedIsIn(ped, false) == car then return false end
    end
    return true
end
local function offset(truck, car)
    local d = GetEntityCoords(car) - GetEntityCoords(truck)
    local h = math.rad(GetEntityHeading(truck))
    return d.x * math.cos(h) + d.y * math.sin(h), -d.x * math.sin(h) + d.y * math.cos(h), d.z
end
local function public(r)
    return { id = r.id, ramps = r.ramps, target = r.target, stage = r.stage,
        geometry = r.geometry, load = r.load, busy = r.busy and true or false,
        model = r.model, revision = r.revision, operator = r.busy and r.busy.actor or r.liftOperator,
        lift = r.lift, liftTarget = r.liftTarget, liftData = r.liftData, liftGeometry = r.liftGeometry,
        remoteActive = r.liftOperator ~= nil }
end
local function sync(r)
    r.revision = (r.revision or 0) + 1
    TriggerClientEvent('ts_flatbed:state', -1, r.id, public(r))
end
local function restore(r, atOrigin)
    if not r.target then return end
    local car = entity(r.target)
    if car == 0 or car ~= r.targetEntity then return end
    local origin = atOrigin and r.origin or nil
    TriggerClientEvent('ts_flatbed:restore', -1, r.target, origin, GetEntityModel(car))
    if car ~= 0 and origin then
        SetEntityCoords(car, origin.x, origin.y, origin.z, false, false, false, false)
        SetEntityHeading(car, origin.heading)
    end
end
local function clearTarget(r)
    if r.target then cargoOwners[r.target] = nil end
    r.target, r.stage, r.load, r.origin, r.busy, r.targetEntity = nil, nil, nil, nil, nil, nil
end
local function clearLift(r)
    if r.liftTarget then
        local car = entity(r.liftTarget)
        if car ~= 0 and car == r.liftEntity then
            TriggerClientEvent('ts_flatbed:restore', -1, r.liftTarget, nil, GetEntityModel(car))
        end
        cargoOwners[r.liftTarget] = nil
    end
    r.liftTarget, r.liftEntity, r.liftData = nil, nil, nil
end
local function abort(r)
    -- Een onderbroken laadpoging gaat terug naar het startpunt.
    -- Een onderbroken lossing keert terug naar de vastgezette laadpositie.
    local unloading = r.busy and r.busy.action == 'unload'
    if unloading then
        r.stage = 'loaded'
        r.busy = nil
    else
        restore(r, true)
        clearTarget(r)
    end
    sync(r)
end
local function fail(msg) return { ok = false, message = msg } end
local function validTruck(src, id)
    local truck = entity(id)
    if truck == 0 or GetEntityType(truck) ~= 2 or not models[GetEntityModel(truck)] then return end
    if not allowed(src) or not near(src, truck) then return end
    return truck
end
local function rate(src, delay)
    local now = GetGameTimer()
    if limits[src] and now - limits[src] < delay then return false end
    limits[src] = now
    return true
end

lib.callback.register('ts_flatbed:snapshot', function(src)
    if not rate(src, 300) then return { records = {}, calibrations = calibrations } end
    local result = {}
    for id, r in pairs(records) do result[tostring(id)] = public(r) end
    return { records = result, calibrations = calibrations }
end)

lib.callback.register('ts_flatbed:action', function(src, action, id, target, data)
    if type(action) ~= 'string' or not rate(src, 350) then return fail('Even wachten.') end
    local truck = validTruck(src, id)
    if not truck then return fail('Geen toegang of je staat te ver van de vrachtwagen.') end
    if GetEntitySpeed(truck) > 0.3 then return fail('Zet de vrachtwagen eerst stil.') end
    local r = records[id]
    if r and r.entity ~= truck then
        restore(r, false); clearTarget(r); clearLift(r); records[id] = nil; r = nil
    end
    if r and (r.busy or r.liftOperator) then return fail('De flatbed is al in gebruik.') end
    if action == 'rampsOn' then
        if r and r.lift then return fail('Maak de tweede auto los en berg eerst de lepel op.') end
        if r and r.ramps then return fail('De rijplaten liggen er al.') end
        if not FB.validGeometry(data) then return fail('Ongeldige afstelling of terrein te steil.') end
        r = r or { id = id, entity = truck, model = models[GetEntityModel(truck)] }
        r.ramps, r.geometry = true, data
        records[id] = r
        FreezeEntityPosition(truck, true)
        sync(r)
        return { ok = true }
    end
    if not r then return fail('Plaats eerst de rijplaten.') end
    if action == 'rampsOff' then
        if not r.ramps then return fail('De rijplaten zijn al opgeborgen.') end
        if r.target and r.stage ~= 'loaded' then return fail('Maak eerst de lier los.') end
        r.ramps = false
        FreezeEntityPosition(truck, false)
        sync(r)
        return { ok = true }
    end
    if action == 'hook' or action == 'secure' then
        if not r.ramps or r.target then return fail('Plaats de rijplaten en maak de vorige auto eerst los.') end
        local car = entity(target)
        if car == 0 or car == truck or GetEntityType(car) ~= 2 or cargoOwners[target] or records[target] then
            return fail('Dit voertuig kan niet worden gekoppeld.')
        end
        if GetEntityRoutingBucket(car) ~= GetEntityRoutingBucket(truck)
            or #(GetEntityCoords(car) - GetEntityCoords(truck)) > Config.MaxCableLength
            or GetEntitySpeed(car) > 0.6 or not empty(car) then
            return fail('Voertuig te ver weg, in beweging of nog bezet.')
        end
        if type(data) ~= 'table' or not FB.finite(data.z, -2, 5) then return fail('Ongeldige laadhoogte.') end
        local x, y, z = offset(truck, car)
        local heading = math.abs((GetEntityHeading(car) - GetEntityHeading(truck) + 180) % 360 - 180)
        if math.abs(x) > 1.5 or heading > 15 then return fail('Zet het voertuig recht achter of op de laadbak.') end
        if action == 'hook' and (y > r.geometry.toeY + 0.5 or y < r.geometry.toeY - 12) then
            return fail('Zet het voertuig achter de rijplaten.')
        end
        if action == 'secure' and (y < r.geometry.rearY or y > r.geometry.frontY or math.abs(z - data.z) > 0.6) then
            return fail('Zet het voertuig eerst op de laadbak.')
        end
        local c = GetEntityCoords(car)
        r.origin = { x = c.x, y = c.y, z = c.z, heading = GetEntityHeading(car) }
        r.target, r.stage, r.load = target, 'hooked', { x = 0, y = r.geometry.loadY, z = data.z }
        r.targetEntity = car
        cargoOwners[target] = id
        if action == 'secure' then
            -- Alleen dichtbij de door de server bewaarde laadpositie vastzetten.
            local tc = GetEntityCoords(truck)
            if #(c - tc) > 9 or math.abs(c.z - tc.z - data.z) > 1 then
                clearTarget(r); return fail('Zet het voertuig eerst op de laadbak.')
            end
        else
            sync(r); return { ok = true }
        end
    elseif action == 'unhook' then
        if r.stage ~= 'hooked' then return fail('Er is geen losse lierkabel aangesloten.') end
        clearTarget(r); sync(r); return { ok = true }
    elseif action == 'release' then
        if r.stage ~= 'loaded' or not r.ramps then return fail('Plaats de rijplaten voor het losmaken.') end
        restore(r, false); clearTarget(r); sync(r); return { ok = true }
    elseif action ~= 'load' and action ~= 'unload' then
        return fail('Onbekende actie.')
    end
    if not r.ramps or not r.target then return fail('Plaats de rijplaten en sluit een voertuig aan.') end
    if action == 'load' and r.stage ~= 'hooked' then return fail('Sluit eerst de lier aan.') end
    if action == 'unload' and r.stage ~= 'loaded' then return fail('Geen vastgezet voertuig aanwezig.') end
    local car = entity(r.target)
    if car == 0 or car ~= r.targetEntity or not empty(car) then return fail('Voertuig verdwenen of nog bezet.') end
    if #(GetEntityCoords(car) - GetEntityCoords(truck)) > Config.MaxCableLength + 2 then
        clearTarget(r); sync(r); return fail('Voertuig staat te ver weg; kabel losgemaakt.')
    end
    serial = serial + 1
    r.busy = { actor = src, token = serial, at = GetGameTimer(), action = action }
    r.stage = 'moving'
    sync(r)
    return { ok = true, token = serial, state = public(r) }
end)

lib.callback.register('ts_flatbed:lift', function(src, action, id, target, data)
    if not Config.WheelLift.enabled or type(action) ~= 'string' or not rate(src, 350) then return fail('Even wachten.') end
    local truck = validTruck(src, id)
    if not truck or GetEntitySpeed(truck) > 0.25 then return fail('Ga naast de stilstaande vrachtwagen staan.') end
    local r = records[id]
    if r and r.entity ~= truck then
        restore(r,false); clearTarget(r); clearLift(r); records[id]=nil; r=nil
    end
    if r and (r.busy or r.liftOperator or r.ramps) then return fail('Berg de rijplaten op en wacht tot de bediening klaar is.') end
    if action == 'deploy' then
        if r and r.lift then return fail('De lepel is al uitgeklapt.') end
        if type(data) ~= 'table' or not FB.finite(data.rearY, -15, 0) or not FB.finite(data.bottom, -4, 2) then
            return fail('Ongeldige lepelpositie.')
        end
        r = r or { id=id, entity=truck, model=models[GetEntityModel(truck)] }
        r.lift, r.liftGeometry = true, { rearY=data.rearY, bottom=data.bottom }
        records[id] = r
    elseif not r or not r.lift then return fail('Klap eerst de lepel uit.')
    elseif action == 'stow' then
        if r.liftTarget then return fail('Maak eerst de tweede auto los.') end
        r.lift = false
    elseif action == 'attach' then
        if r.liftTarget then return fail('Er hangt al een auto aan de lepel.') end
        local car = entity(target)
        if car == 0 or car == truck or GetEntityType(car) ~= 2 or cargoOwners[target] or models[GetEntityModel(car)] then
            return fail('Deze auto kan niet aan de lepel.')
        end
        if not empty(car) or GetEntitySpeed(car) > 0.5 or GetEntityRoutingBucket(car) ~= GetEntityRoutingBucket(truck) then
            return fail('De auto moet leeg en stilstaand in dezelfde wereld zijn.')
        end
        if type(data) ~= 'table' or not FB.finite(data.front, 0.4, 3.5) or not FB.finite(data.rear, -3.5, -0.4)
            or not FB.finite(data.bottom, -2.5, 0) or not FB.finite(data.halfWidth, 0.5, 1.3)
            or data.front - data.rear > 5.5 then return fail('Ongeldige voertuigafmetingen.') end
        local x,y = offset(truck, car)
        local desired = r.liftGeometry.rearY - Config.WheelLift.reach - data.front
        local heading = math.abs((GetEntityHeading(car)-GetEntityHeading(truck)+180)%360-180)
        if math.abs(x)>0.8 or math.abs(y-desired)>1.5 or heading>15 then
            return fail('Zet de voorwielen recht boven de lepel, neus richting vrachtwagen.')
        end
        r.liftTarget, r.liftEntity = target, car
        r.liftData = {front=data.front,rear=data.rear,bottom=data.bottom,halfWidth=data.halfWidth}
        cargoOwners[target] = id
    elseif action == 'detach' then
        if not r.liftTarget or not empty(entity(r.liftTarget)) then return fail('Laat iedereen uit de tweede auto stappen.') end
        clearLift(r)
    else return fail('Onbekende lepelactie.') end
    r.liftOperator, r.liftUntil = src, GetGameTimer()+2200
    FreezeEntityPosition(truck, true)
    sync(r)
    return {ok=true,state=public(r)}
end)

RegisterNetEvent('ts_flatbed:finish', function(id, token, success)
    local src, r = source, records[id]
    if not r or not r.busy or r.busy.actor ~= src or r.busy.token ~= token then return end
    if success ~= true then abort(r); return end
    local truck, car = entity(id), entity(r.target)
    if truck == 0 or car == 0 or car ~= r.targetEntity or not near(src, truck) or not empty(car) then abort(r); return end
    local c, t = GetEntityCoords(car), GetEntityCoords(truck)
    if #(c - t) > Config.MaxCableLength + 2 then abort(r); return end
    local x, y, z = offset(truck, car)
    if r.busy.action ~= 'unload' and (math.abs(x - r.load.x) > 0.8 or math.abs(y - r.load.y) > 0.8 or math.abs(z - r.load.z) > 0.8) then
        abort(r); return
    end
    if r.busy.action == 'unload' and (math.abs(x) > 1.5 or y > r.geometry.toeY) then abort(r); return end
    if r.busy.action == 'unload' then
        restore(r, false); clearTarget(r)
    else
        r.stage, r.busy, r.origin = 'loaded', nil, nil
    end
    sync(r)
end)

lib.callback.register('ts_flatbed:admin', function(src, id, values)
    if not IsPlayerAceAllowed(src, Config.AdminAce) then return fail('Geen afstelrechten.') end
    local truck = entity(id)
    if truck == 0 or not models[GetEntityModel(truck)] or not near(src, truck) then return fail('Ga naast de vrachtwagen staan.') end
    local model = models[GetEntityModel(truck)]
    if values == nil then return { ok = true, profile = calibrations[model] } end
    local r = records[id]
    if r and (r.target or r.ramps or r.lift) then return fail('Berg rijplaten en lepel op en maak de laadbak leeg.') end
    if type(values) ~= 'table' then return fail('Ongeldige waarden.') end
    local clean = {}
    for _, k in ipairs({'rearY','deckZ','loadY','frontY','rampX','rampY','rampZ','rampPitch','rampYaw'}) do
        local bound = k == 'rampYaw' and 360 or 20
        if not FB.finite(values[k], -bound, bound) then return fail('Ongeldige afstelwaarde: '..k) end
        clean[k] = values[k]
    end
    if clean.loadY <= clean.rearY or clean.frontY <= clean.loadY then return fail('Laadpositie moet tussen achterrand en voorrand liggen.') end
    local before = calibrations[model]
    calibrations[model] = clean
    if not SaveResourceFile(GetCurrentResourceName(), 'calibration.json', json.encode(calibrations, { indent = true }), -1) then
        calibrations[model] = before; return fail('Opslaan mislukt; controleer schrijfrechten van de resource.')
    end
    TriggerClientEvent('ts_flatbed:calibrations', -1, calibrations)
    return { ok = true }
end)

AddEventHandler('playerDropped', function()
    local src = source
    limits[src] = nil
    for _, r in pairs(records) do
        if r.busy and r.busy.actor == src then abort(r) end
        if r.liftOperator == src then
            r.liftOperator=nil
            if not r.ramps and DoesEntityExist(r.entity) then FreezeEntityPosition(r.entity,false) end
            sync(r)
        end
    end
end)
CreateThread(function()
    while true do
        Wait(1000)
        for id, r in pairs(records) do
            local truck = entity(id)
            if truck == 0 or truck ~= r.entity or models[GetEntityModel(truck)] ~= r.model then
                restore(r, false); clearTarget(r); clearLift(r)
                records[id] = nil; TriggerClientEvent('ts_flatbed:state', -1, id, false)
            else
                if r.busy and (GetGameTimer() - r.busy.at > Config.OperationTimeout or not near(r.busy.actor, truck)) then abort(r) end
                if r.target and entity(r.target) ~= r.targetEntity then clearTarget(r); sync(r) end
                if r.liftTarget and entity(r.liftTarget) ~= r.liftEntity then clearLift(r); sync(r) end
                if r.liftOperator and GetGameTimer() > r.liftUntil then
                    r.liftOperator=nil
                    if not r.ramps then FreezeEntityPosition(truck,false) end
                    sync(r)
                end
                if r.ramps then FreezeEntityPosition(truck, true) end
                if r.stage == 'hooked' and r.target and #(GetEntityCoords(entity(r.target)) - GetEntityCoords(truck)) > Config.MaxCableLength + 2 then
                    clearTarget(r); sync(r)
                end
                if not r.ramps and not r.target and not r.lift and not r.liftOperator then
                    records[id] = nil; TriggerClientEvent('ts_flatbed:state', -1, id, false)
                end
            end
        end
    end
end)
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for _, r in pairs(records) do
        if DoesEntityExist(r.entity) then FreezeEntityPosition(r.entity, false) end
        restore(r, r.busy ~= nil and r.busy.action ~= 'unload')
        clearLift(r)
    end
end)
