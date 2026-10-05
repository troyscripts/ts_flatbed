local thread
local vehicle,driver,owner=20,1,true
local record={target=20,stage='loaded',load={x=0,y=-2,z=0.8}}
local controls,attached,handbrake={},0,false
local intact=true
function IsEntityAttachedToEntity()return intact end
function PlayerPedId()return 1 end
function GetVehiclePedIsIn()return vehicle end
function GetPedInVehicleSeat()return driver end
function NetworkHasControlOfEntity()return owner end
function DisableControlAction(_,input,on)
    assert(on and input~=75,'exit must remain available')
    controls[input]=true
end
function SetVehicleHandbrake(_,value)handbrake=value end
function CreateThread(f)thread=coroutine.create(f)end
function Wait()coroutine.yield()end
FlatbedClient={
    net=function(e)return e end,
    entity=function(id)return id end,
    states=function()return {[10]=record}end,
    attachCargo=function(car,truck,pos)
        assert(car==20 and truck==10 and pos==record.load)
        attached=attached+1
        intact=true
    end
}
dofile('ts_flatbed/client/passengers.lua')
local function frame()
    controls={}
    local ok,err=coroutine.resume(thread);assert(ok,err)
end
frame()
assert(controls[71] and controls[72] and controls[59] and handbrake and attached==1)
for i=1,120 do frame()end
assert(attached==1,'unchanged occupied bed cargo must not reattach every frame')
intact=false;frame();assert(attached==2,'broken attachment must recover immediately')
owner=false;frame();assert(attached==2,'non-owner must not move occupied bed cargo')
owner=true;frame();assert(attached==3,'new owner must preserve attachment')
record={lift=true,liftTarget=20}
frame();assert(controls[71] and attached==3,'wheel lift has its own controller')
driver=2;frame();assert(not next(controls),'passenger must retain their normal controls')
driver=1;record={};frame();assert(not next(controls),'released car must regain driving input')
record={lift=true,liftTarget=20};vehicle=0;frame();assert(not next(controls),'pedestrian must retain controls')
vehicle=99;frame();assert(not next(controls),'unrelated vehicle must remain drivable')
print('PASS: occupied cargo input, owner migration, seat changes, exit, release and unrelated vehicles')
