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
local owns=true
local now,ground,attachments=0,0,0
local intact=true
function GetGameTimer()return now end
local collision,damage,noCollision={},{},{}
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
function AttachEntityToEntity(car,truck,bone,x,y,z,pitch,roll,yaw,p9,soft,collide)
    attachments=attachments+1
    intact=true
    assert(collide==true,'attachment collision must stay enabled')
    carPos=GetOffsetFromEntityInWorldCoords(truck,x,y,z)
    carPitch,carHeading=pitch,yaw
end
function GetGroundZFor_3dCoord()return true,ground end
function GetHeadingFromVector_2d(x,y)return math.deg(math.atan(-x,y))end
function GetFrameTime()return 10 end
function PlayerPedId()return 1 end
function NetworkHasControlOfEntity()return owns end
function SetEntityCollision(e,on,physics)assert(e==20 and on and physics);collision[e]=on end
function SetEntityNoCollisionEntity(a,b,oneFrame)
    assert(oneFrame and ((a==20 and b==10) or (a==10 and b==20)), 'only the towing pair may ignore collision, one frame at a time')
    noCollision[#noCollision+1]={a,b}
end
function SetEntityInvincible(e,on)assert(e==20 and not on);damage.invincible=on end
function SetEntityCanBeDamaged(e,on)assert(e==20 and on);damage.enabled=on end
function SetVehicleCanBeVisiblyDamaged(e,on)assert(e==20 and on);damage.visible=on end
function SetVehicleCanBreak(e,on)assert(e==20 and on);damage.breakable=on end
function SetVehicleFixed()error('must not repair existing damage')end
function SetVehicleEngineHealth()error('must not overwrite engine health')end
function SetVehicleBodyHealth()error('must not overwrite body health')end
function DoesEntityExist()return true end
function IsEntityAttachedToEntity()return intact end
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
local function frame()now=now+16;local ok,err=coroutine.resume(thread);assert(ok,err)end
frame()
local contact=GetOffsetFromEntityInWorldCoords(20,0,record.liftData.rear,record.liftData.rearBottom)
assert(math.abs(contact.z-Config.WheelLift.dollies.height)<1e-8,'rear wheels must sit at dolly deck height')
assert(polys and polys>200,'draw lift and dolly wheels')
assert(collision[20] and damage.enabled and damage.visible and damage.breakable and damage.invincible==false)
assert(#noCollision==2)
frame() -- existing motion state, stationary vehicle
for i=1,60 do frame()end
assert(attachments==1,'unchanged lift must not repeatedly reattach')
local before=attachments
for i=1,120 do ground=ground+0.003;frame()end
assert(attachments>before and attachments-before<=math.ceil(120*16/50),'changed lift offsets must be rate-limited')
before=attachments;intact=false;frame()
assert(attachments==before+1,'lost attachment must recover without waiting for throttle')
owns=false
collision,noCollision={},{}
frame() -- a nearby player's client, which does not own the cargo
assert(collision[20] and #noCollision==2, 'collision must also be enabled for non-owners')
owns=true
before=attachments;frame();assert(attachments==before+1,'ownership migration must reset stale motion and attach immediately')
record.lift=false
collision,noCollision={},{}
frame()
assert(freed,'release second car when lift state disappears')
assert(not next(collision) and #noCollision==0,'frame-only collision exclusions must stop after release')
print('PASS: dolly geometry, collision for owner/observer, damage enabled without healing, pair-only exclusion and cleanup')
