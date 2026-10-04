-- Gebaseerd op de daadwerkelijke API 1 van TroyScripts ts_bridge 0.0.7/0.0.8.
FBBridge = {}
function FBBridge.ready()
    if GetResourceState('ts_bridge') ~= 'started' then
        print('^1[ts_flatbed] Start ts_bridge voor ts_flatbed.^7'); return false
    end
    local ok,status=pcall(function()return exports.ts_bridge:GetStatus()end)
    local required=IsDuplicityVersion() and {'GetJob'} or
        {'Notify','IsDead','AddGlobalVehicle','RemoveGlobalVehicle','ProgressCircle','InputDialog'}
    if not ok or type(status)~='table' or status.api~=1 or status.ready==false or type(status.features)~='table' then
        print('^1[ts_flatbed] ts_bridge API 1 is niet beschikbaar of de bridgeconfiguratie is ongeldig.^7'); return false
    end
    for _,name in ipairs(required) do
        if not status.features[name] then print('^1[ts_flatbed] Ontbrekende bridgefunctie: '..name..'. Werk ts_bridge bij.^7'); return false end
    end
    return true
end
function FBBridge.notify(data) return exports.ts_bridge:Notify(data) end
function FBBridge.progress(data) return exports.ts_bridge:ProgressCircle(data) end
function FBBridge.input(title,rows) return exports.ts_bridge:InputDialog(title,rows) end
function FBBridge.addVehicle(options) return exports.ts_bridge:AddGlobalVehicle(options) end
function FBBridge.removeVehicle(name)
    if GetResourceState('ts_bridge')=='started' then return exports.ts_bridge:RemoveGlobalVehicle(name) end
end
function FBBridge.dead(ped) return exports.ts_bridge:IsDead(ped) end
function FBBridge.job(id)
    local ok,job=pcall(function()return exports.ts_bridge:GetJob(id)end)
    return ok and job or nil
end
