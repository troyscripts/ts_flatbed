-- Execute the real client maintenance thread with a distant, still-owned vehicle.
dofile('ts_flatbed/config.lua')
local threads, attached, frozen = {}, false, false
local mt={__sub=function(a,b)return setmetatable({distance=math.abs(a.distance-b.distance)},getmetatable(a))end,
    __len=function(a)return a.distance end}
local function pos(d)return setmetatable({distance=d},mt)end
FBBridge={ready=function()return true end,addVehicle=function()end}
function joaat()return 123 end
function RegisterNetEvent()end
function RegisterCommand()end
function AddEventHandler()end
function CreateThread(f)threads[#threads+1]=coroutine.create(f)end
function Wait()coroutine.yield()end
function PlayerPedId()return 1 end
function GetEntityCoords(e)return pos(e==1 and 500 or 0)end
function GetEntityModel()return 123 end
function NetworkDoesEntityExistWithNetworkId(id)return id==100 or id==101 end
function NetToVeh(id)return id end
function DoesEntityExist(e)return e==100 or e==101 end
function NetworkHasControlOfEntity()return true end
function IsEntityAttachedToEntity()return attached end
function AttachEntityToEntity()attached=true end
function DetachEntity()attached=false end
function SetVehicleHandbrake()end
function FreezeEntityPosition(_,value)frozen=value end
lib={callback={await=function()return {records={},calibrations={}}end}}
dofile('ts_flatbed/client/main.lua')
FlatbedClient.setState(100,{id=100,model='energyrampamec',ramps=true,target=101,
    stage='loaded',load={x=0,y=-2,z=1},revision=1})
local function tick()local ok,err=coroutine.resume(threads[1]);assert(ok,err)end
tick();tick()
assert(attached and frozen,'distant owned cargo must stay attached and ramp truck frozen')
FlatbedClient.setState(100,{id=100,model='energyrampamec',remoteActive=true})
tick()
assert(frozen and not attached,'lift operation must freeze truck; released cargo must detach')
FlatbedClient.setState(100,nil)
tick()
assert(not frozen,'removed state must release freeze')
print('PASS: distant cargo retention, ramp freeze, lift freeze and authoritative release')
