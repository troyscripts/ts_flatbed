-- Pure geometry plus server orchestration with mocked FiveM natives.
-- This does NOT simulate GTA collision, attachments or networking.
dofile('ts_flatbed/config.lua')
dofile('ts_flatbed/shared/math.lua')
local g = { rearY=-4, toeY=-9, deckZ=0.4, groundZ=-1, loadY=-0.6, frontY=3,
    rampX=0,rampY=-6,rampZ=-0.5,rampPitch=16,rampYaw=180 }
assert(FB.validGeometry(g))
assert(not FB.finite(0/0)); assert(not FB.finite(math.huge))
assert(math.abs(FB.surface(-12,g)+1)<1e-8 and math.abs(FB.surface(0,g)-0.4)<1e-8)
local zg,pg=FB.pose(-12,g,1.3,-0.4)
local zb,pb=FB.pose(0,g,1.3,-0.4)
assert(math.abs(pg)<1e-8 and math.abs(pb)<1e-8)
assert(zb>zg and math.abs(zb-0.84)<1e-8)
for y=-11,2,0.02 do
    local z=FB.pose(y,g,1.3,-0.4)
    local nextZ=FB.pose(y+0.02,g,1.3,-0.4)
    assert(math.abs(nextZ-z)<0.03, 'discontinuous cargo path')
end
print('PASS: finite numbers, ground/deck heights, smooth loading path')
local shifted=assert(FB.cargoPlan({x=-1,y=-4,z=-0.4},{x=1,y=1,z=1},g,true))
assert(shifted.y==0, 'asymmetric model must shift forward to fit')
local hugeLow,hugeHigh={x=-2,y=-5,z=-0.5},{x=2,y=5,z=1}
assert(FB.cargoPlan(hugeLow,hugeHigh,g,false), 'hooking alone must not reject the cargo size')
local rejected,reason=FB.cargoPlan(hugeLow,hugeHigh,g,true)
assert(not rejected and reason:find('10.00') and reason:find('4.00'))
assert(FB.cargoPlan({x=-1.34,y=-2,z=-0.4},{x=1.34,y=2,z=1},g,true), 'allow small measurement margin')
print('PASS: hook separated from size check, asymmetric fit, size diagnostics and measurement margin')

local mt={}
local function v(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__sub=function(a,b)return v(a.x-b.x,a.y-b.y,a.z-b.z)end
mt.__len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end
local ents={
 [100]={pos=v(0,0,0),model=123,type=2},
 [101]={pos=v(0,-12,-0.6),model=456,type=2},
 [102]={pos=v(10,0,0),model=123,type=2},
 [1]={pos=v(2,-2,0),model=0,type=1},
 [2]={pos=v(2,-2,0),model=0,type=1}
}
local callbacks,events,handlers,threads,packets={},{},{},{},{}
local now=0
lib={callback={register=function(n,f)callbacks[n]=f end}}
function joaat(n)return n=='energyrampamec' and 123 or 0 end
function GetCurrentResourceName()return 'ts_flatbed'end
function LoadResourceFile()return nil end
function SaveResourceFile()return true end
json={encode=function()return '{}'end}
function GetGameTimer()return now end
function NetworkGetEntityFromNetworkId(n)return ents[n] and n or 0 end
function DoesEntityExist(e)return ents[e]~=nil end
function GetEntityType(e)return ents[e].type end
function GetEntityModel(e)return ents[e].model end
function GetPlayerPed(s)return ents[s] and s or 0 end
function GetEntityHealth()return 200 end
function GetPlayerRoutingBucket(s)return ents[s].bucket or 0 end
function GetEntityRoutingBucket(s)return ents[s].bucket or 0 end
function GetEntityCoords(e)return ents[e].pos end
function GetEntitySpeed(e)return ents[e].speed or 0 end
function GetEntityHeading(e)return ents[e].heading or 0 end
function SetEntityHeading(e,h)ents[e].heading=h end
function SetEntityCoords(e,x,y,z)ents[e].pos=v(x,y,z)end
function GetVehiclePedIsIn(p)return ents[p].car or 0 end
function GetAllPeds()return {1,2}end
function IsPlayerAceAllowed(s)return s==1 end
function FreezeEntityPosition(e,b)ents[e].frozen=b end
function TriggerClientEvent(name,to,id,data)packets[#packets+1]={name=name,id=id,data=data}end
function RegisterNetEvent(n,f)events[n]=f end
function AddEventHandler(n,f)handlers[n]=f end
function CreateThread(f)threads[#threads+1]=f end
function Wait()coroutine.yield()end
function GetResourceState()return 'started'end
function IsDuplicityVersion()return true end
exports={ts_bridge={
 GetStatus=function()return {api=1,features={GetJob=true}}end,
 GetJob=function(_,id)return id==1 and {name='mechanic',grade=2} or {name='unemployed',grade=0}end
}}
dofile('ts_flatbed/shared/bridge.lua')
dofile('ts_flatbed/server/main.lua')
local function action(src,a,id,target,data)
 now=now+400
 return callbacks['ts_flatbed:action'](src,a,id or 100,target,data)
end
local function latest()
 for i=#packets,1,-1 do if packets[i].name=='ts_flatbed:state' and packets[i].id==100 then return packets[i].data end end
end
assert(action(1,'load').ok==false)
assert(action(1,'rampsOn',100,nil,g).ok)
assert(ents[100].frozen)
assert(action(1,'hook',100,101,{z=0.84}).ok)
assert(action(2,'hook',100,101,{z=0.84}).ok==false)
assert(action(1,'rampsOff').ok==false)
local reply=action(1,'load',100,nil,{y=-0.1,z=0.84})
assert(reply.ok and reply.token and reply.state.operator==1)
assert(action(2,'load').ok==false)
source=2;events['ts_flatbed:finish'](100,reply.token,true)
assert(latest().busy, 'wrong actor must not finish an operation')
source=1;events['ts_flatbed:finish'](100,reply.token+1,true)
assert(latest().busy, 'wrong token must not finish an operation')
assert(reply.state.load.y==-0.1, 'server must preserve the calculated position')
ents[101].pos=v(0,-0.1,0.84)
events['ts_flatbed:finish'](100,reply.token,true)
assert(latest().stage=='loaded' and not latest().busy)
assert(action(1,'rampsOff').ok and not ents[100].frozen)
assert(action(1,'unload').ok==false)
assert(action(1,'rampsOn',100,nil,g).ok)
reply=action(1,'unload');assert(reply.ok)
source=1;events['ts_flatbed:finish'](100,reply.token,false)
assert(latest().stage=='loaded', 'cancelled unload must retain cargo')
reply=action(1,'unload');assert(reply.ok)
ents[101].pos=v(0,-12,-0.6)
events['ts_flatbed:finish'](100,reply.token,true)
assert(not latest().target)
print('PASS: competing users, operation tokens, load, transport, unload and unload cancellation')

ents[2].car=101
assert(action(1,'hook',100,101,{z=0.84}).ok==false)
ents[2].car=nil
ents[101].bucket=5
assert(action(1,'hook',100,101,{z=0.84}).ok==false)
ents[101].bucket=0
ents[1].pos=v(99,99,99)
assert(action(1,'hook',100,101,{z=0.84}).ok==false)
ents[1].pos=v(2,-2,0)
assert(action(1,'hook',100,101,{z=0.84}).ok)
reply=action(1,'load');assert(reply.ok)
ents[101].pos=v(0,-7,0)
source=1;handlers.playerDropped()
assert(not latest().target and ents[101].pos.y==-12)
print('PASS: occupied vehicle, routing buckets, distance and operator disconnect recovery')

-- Laadbak + tweede auto, en blokkering tussen lepel en rijplaten.
assert(action(1,'hook',100,101,{z=0.84}).ok)
reply=action(1,'load');assert(reply.ok)
ents[101].pos=v(0,-0.6,0.84)
source=1;events['ts_flatbed:finish'](100,reply.token,true)
assert(action(1,'rampsOff').ok)
local scheduler=coroutine.create(threads[1]);assert(coroutine.resume(scheduler))
local function tick() now=now+3500;assert(coroutine.resume(scheduler))end
local function lift(a,target,data)
 now=now+400
 return callbacks['ts_flatbed:lift'](1,a,100,target,data)
end
assert(lift('deploy',nil,{rearY=-4,bottom=-1}).ok)
assert(action(1,'rampsOn',100,nil,g).ok==false)
tick()
ents[103]={pos=v(0,-6.65,-0.6),model=456,type=2}
local second={front=1.4,rear=-1.4,bottom=-0.4,halfWidth=0.8}
second.rearBottom=0/0
assert(not lift('attach',103,second).ok, 'reject nonfinite rear contact')
second.rearBottom=-0.45
second.rearHalfWidth=2.0
assert(not lift('attach',103,second).ok, 'reject excessive rear track')
second.halfWidth=1.5
second.rearHalfWidth=1.5
assert(lift('attach',103,second).ok)
assert(latest().liftData.rearBottom==-0.45 and latest().liftData.rearHalfWidth==1.5)
assert(latest().target==101 and latest().liftTarget==103)
tick()
assert(lift('stow').ok==false)
assert(action(1,'rampsOn',100,nil,g).ok==false)
assert(lift('detach').ok)
assert(latest().target==101 and not latest().liftTarget)
tick();assert(lift('stow').ok);tick()
assert(action(1,'rampsOn',100,nil,g).ok)
assert(action(1,'release').ok)
print('PASS: two independent cars, wheel-lift/ramp interlock and lift release preserving bed cargo')

Config.Jobs={mechanic=2}
assert(action(2,'rampsOff').ok==false)
assert(action(1,'rampsOff').ok)
Config.Jobs=false
assert(action(1,'rampsOn',100,nil,g).ok)
print('PASS: job permission through the verified ts_bridge GetJob contract')

assert(callbacks['ts_flatbed:admin'](2,100).ok==false)
assert(callbacks['ts_flatbed:admin'](1,100).ok)
local unsafe={rearY=0/0,deckZ=0.2,loadY=-1,frontY=3,rampX=0,rampY=0,rampZ=0,rampPitch=0,rampYaw=0}
assert(callbacks['ts_flatbed:admin'](1,100,unsafe).ok==false)
source=1;handlers.onResourceStop('ts_flatbed')
assert(not ents[100].frozen)
print('PASS: admin rights, invalid calibration and resource-stop parking cleanup')
