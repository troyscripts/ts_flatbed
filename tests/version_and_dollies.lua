-- Pure support geometry + configuration/update adapter; no GTA physics emulation.
dofile('ts_flatbed/config.lua')
dofile('ts_flatbed/shared/math.lua')
for _,rearBottom in ipairs({-0.35,-0.5,-0.75}) do
    for _,difference in ipairs({-0.6,0,0.6,1.4}) do
        local wheelbase,frontBottom=2.8,-0.45
        local pitch=FB.liftPitch(wheelbase,frontBottom,rearBottom,difference)
        local achieved=wheelbase*math.sin(pitch)+(frontBottom-rearBottom)*math.cos(pitch)
        assert(math.abs(achieved-difference)<1e-9,'wheel contact height must match the dolly support')
        local ground,top=11.0,Config.WheelLift.dollies.height
        local front=ground+top+difference
        assert(math.abs(front-achieved-ground-top)<1e-9)
    end
end
assert(Config.WheelLift.dollies.height>=2*Config.WheelLift.dollies.wheelRadius)
print('PASS: rear support height on flat/uphill/downhill surfaces and unequal tyre contact heights')
dofile('ts_flatbed/shared/config_version.lua')
assert(FBConfigValid)
local log,realPrint={},print
print=function(message)log[#log+1]=message end
Config.Version='0.9.0'
dofile('ts_flatbed/shared/config_version.lua')
assert(not FBConfigValid and #log==1)
dofile('ts_flatbed/shared/bridge.lua')
assert(not FBBridge.ready(),'old config must stop before bridge access')
Config.Version='1.0.0'
dofile('ts_flatbed/shared/config_version.lua')
local calls=0
function CreateThread(f)f()end
exports={ts_bridge={CheckForUpdates=function(_,settings)
    calls=calls+1
    assert(settings.Repository=='troyscripts/ts_flatbed' and settings.Enabled)
    return true
end}}
dofile('ts_flatbed/server/update_check.lua')
assert(calls==1)
Config.UpdateCheck.Enabled=false
dofile('ts_flatbed/server/update_check.lua')
assert(calls==1,'disabled checker must not request an update')
Config.UpdateCheck.Enabled=true
exports.ts_bridge.CheckForUpdates=function()error('missing export')end
dofile('ts_flatbed/server/update_check.lua')
assert(#log==2 and log[2]:find('Versiecontrole kon niet starten'))
print=realPrint
print('PASS: config mismatch blocks startup, bridge checker repo, disabled checker and missing export')
