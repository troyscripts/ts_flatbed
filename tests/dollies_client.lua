-- One client frame using rigid transforms; checks grounding and cleanup, not GTA rendering.
dofile('ts_flatbed/config.lua')
dofile('ts_flatbed/shared/math.lua')
local mt={}
function vector3(x,y,z)return setmetatable({x=x,y=y,z=z},mt)end
mt.__sub=function(a,b)return vector3(a.x-b.x,a.y-b.y,a.z-b.z)end
mt.__len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end
local carPos=vector3(0,-9,0.6)
local carPitch,carHeading=0,0
local record={lift=true,liftTarget=20,liftGeometry={rearY=-5,bottom=-1},
    liftData={front=1.4,rear=-1.4,bottom=-0.4,rearBottom=-0.45,halfWidth=0.8,rearHalfWidth=0.82}}
local thread,freed,polys
function GetEntityCoords(e)return e==20 and carPos or vector3(0,0,1)end
function GetEntityHeading(e)return e==20 and carHeading or 0 end
function GetEntityPitch(e)return e==20 and carPitch or 0 end
function GetOffsetFromEntityInWorldCoords(e,x,y,z)
    local p=math.rad(GetEntityPitch(e))
    local a=math.rad(GetEntityHeading(e))
    local along=y*math.cos(p)-z*math.sin(p)
    local o=GetEntityCoords(e)
    return vector3(o.x+x*math.cos(a)-along*math.sin(a),o.y+x*math.sin(a)+along*math.cos(a),o.z+y*math.sin(p)+z*math.cos(p))
end
function AttachEntityToEntity(car,truck,bone,x,y,z,pitch,roll,yaw)
    carPos=GetOffsetFromEntityInWorldCoords(truck,x,y,z)
    carPitch,carHeading=pitch,yaw
end
function GetGroundZFor_3dCoord()return true,0 end
function GetHeadingFromVector_2d(x,y)return math.deg(math.atan(-x,y))end
function GetFrameTime()return 10 end
function PlayerPedId()return 1 end
function NetworkHasControlOfEntity()return true end
function DoesEntityExist()return true end
function IsEntityAttachedToEntity()return true end
function SetVehicleHandbrake(_,value)assert(not value)end
function RegisterCommand()end
function AddEventHandler()end
function CreateThread(f)thread=coroutine.create(f)end
function Wait()coroutine.yield()end
function DrawPoly(...)polys=(polys or 0)+1 end
FlatbedClient={
    states=function()return {[10]=record}end,
    entity=function(id)return id or 0 end,
    freeCar=function(e)assert(e==20);freed=true end
}
FBBridge={addVehicle=function()end}
dofile('ts_flatbed/client/wheellift.lua')
local function frame()local ok,err=coroutine.resume(thread);assert(ok,err)end
frame()
local contact=GetOffsetFromEntityInWorldCoords(20,0,record.liftData.rear,record.liftData.rearBottom)
assert(math.abs(contact.z-Config.WheelLift.dollies.height)<1e-8,'rear wheels must sit at dolly deck height')
assert(polys and polys>200,'draw lift and dolly wheels')
frame() -- existing motion state, stationary vehicle
record.lift=false
frame()
assert(freed,'release second car when lift state disappears')
print('PASS: client rear wheel contact sits on dolly deck, render loop and attachment cleanup')
