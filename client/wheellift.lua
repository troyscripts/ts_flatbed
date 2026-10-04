-- Losse, procedureel getekende wielheffer. Geen wijziging aan het escrow-model.
-- De tweede auto volgt een begrensd scharnier; GTA-towtruck-bones zijn niet vereist.
FBWheel = {}
local api = FlatbedClient
if not api then return end
local selected, busy
local carried, motion, heights = {}, {}, {}
local function dimensions(car)
    local low, high = GetModelDimensions(GetEntityModel(car))
    local front, rear = high.y * 0.65, low.y * 0.65
    for _, entry in ipairs({{'wheel_lf','front'}, {'wheel_lr','rear'}}) do
        local bone = GetEntityBoneIndexByName(car, entry[1])
        if bone ~= -1 then
            local w = GetWorldPositionOfEntityBone(car, bone)
            local p = GetOffsetFromEntityGivenWorldCoords(car, w.x,w.y,w.z)
            if entry[2]=='front' and p.y>0.4 then front=p.y end
            if entry[2]=='rear' and p.y< -0.4 then rear=p.y end
        end
    end
    return {front=front,rear=rear,bottom=math.min(-0.05,low.z),halfWidth=(high.x-low.x)*0.40}, low, high
end
local function doAction(name, truck, car)
    if busy then return end
    busy = true
    local ok, err = xpcall(function()
        if not DoesEntityExist(truck) or IsPedInAnyVehicle(PlayerPedId(),false) then error('Ga naast de vrachtwagen staan.') end
        local data
        if name=='deploy' then
            local lo=GetModelDimensions(GetEntityModel(truck))
            data={rearY=api.profile(truck).rearY,bottom=lo.z}
        elseif name=='attach' then
            if not DoesEntityExist(car) or car==truck or IsEntityAttached(car) or api.occupied(car) then error('Kies een lege, losstaande auto.') end
            local cls=GetVehicleClass(car)
            if cls==8 or cls==13 or cls==14 or cls==15 or cls==16 or cls==21 then error('De lepel is bedoeld voor auto\'s, niet voor dit voertuigtype.') end
            local lo,hi
            data,lo,hi=dimensions(car)
            if hi.y-lo.y>Config.WheelLift.maxLength or hi.x-lo.x>Config.WheelLift.maxWidth then error('Deze auto is te groot voor de lepel.') end
            if not api.control(car) then error('Geen netwerkcontrole over de tweede auto.') end
        elseif name=='detach' then
            local r=api.state(truck)
            car=r and api.entity(r.liftTarget) or 0
            if car==0 or api.occupied(car) or not api.control(car) then error('Laat iedereen uitstappen; netwerkcontrole is nodig om los te maken.') end
        end
        local reply=lib.callback.await('ts_flatbed:lift',false,name,api.net(truck),car and api.net(car),data)
        if not reply or not reply.ok then error(reply and reply.message or 'Geen antwoord van de server.') end
        api.setState(api.net(truck),reply.state)
        if name=='detach' then
            api.freeCar(car)
            SetVehicleOnGroundProperly(car)
            SetEntityVelocity(car,0,0,0)
        end
        FBBridge.progress({duration=2000,label='Lepel bedienen',position='bottom',canCancel=false,
            disable={move=true,car=true,combat=true},
            anim=Config.Remote.enabled and {dict=Config.Remote.dict,clip=Config.Remote.clip,flag=49} or nil})
        local messages={deploy='Lepel uitgeklapt. Zet de voorwielen van de tweede auto boven de wielsteunen.',
            stow='Lepel opgeborgen.',attach='Tweede auto gekoppeld. De voorwielen worden geheven.',detach='Tweede auto losgemaakt.'}
        api.notify(messages[name],'success')
    end,function(e)return tostring(e)end)
    busy=false
    if not ok then api.notify(err,'error') end
end
function FBWheel.menu(truck)
    local r=api.state(truck) or {}
    lib.registerContext({id='ts_flatbed_lift_menu',title='Lepel • Tweede auto',options={
        {title=r.lift and 'Lepel opbergen' or 'Lepel uitklappen',icon='truck-pickup',disabled=r.ramps or r.busy or r.liftTarget~=nil or r.remoteActive,
            onSelect=function()doAction(r.lift and 'stow' or 'deploy',truck)end},
        {title='Tweede auto koppelen',description='Voorwielen boven de lepel, neus naar de truck.',icon='link',disabled=not r.lift or r.liftTarget~=nil or r.remoteActive,
            onSelect=function()
                selected={truck=truck,at=GetGameTimer()}
                lib.showTextUI('[ALT] Kies de tweede auto • [BACKSPACE] Annuleren')
            end},
        {title='Tweede auto losmaken',icon='link-slash',disabled=not r.liftTarget or r.remoteActive,
            onSelect=function()doAction('detach',truck)end}
    }})
    lib.showContext('ts_flatbed_lift_menu')
end
RegisterCommand('flatbedlepel',function()
    if not Config.WheelLift.enabled then return end
    local truck=api.closestTruck()
    if truck then FBWheel.menu(truck) else api.notify('Geen flatbed in de buurt.','error') end
end,false)

-- Eenvoudige metalen constructie, met echte 3D-vlakken in de gamewereld.
local faces={{1,2,3,4},{5,8,7,6},{1,5,6,2},{2,6,7,3},{3,7,8,4},{4,8,5,1}}
local corners={{-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1},{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1}}
local function box(truck,x,y,z,sx,sy,sz,yaw,yellow)
    local v={}
    local c,s=math.cos(yaw or 0),math.sin(yaw or 0)
    for i,k in ipairs(corners) do
        local dx,dy=k[1]*sx*0.5,k[2]*sy*0.5
        v[i]=GetOffsetFromEntityInWorldCoords(truck,x+dx*c-dy*s,y+dx*s+dy*c,z+k[3]*sz*0.5)
    end
    for i,f in ipairs(faces) do
        local tone=i==2 and 95 or 55
        local red,green,blue=tone,tone,tone+5
        if yellow then red,green,blue=200,160,20 end
        local function tri(a,b,c)
            local p,q,t=v[a],v[b],v[c]
            DrawPoly(p.x,p.y,p.z,q.x,q.y,q.z,t.x,t.y,t.z,red,green,blue,255)
            DrawPoly(t.x,t.y,t.z,q.x,q.y,q.z,p.x,p.y,p.z,red,green,blue,255)
        end
        tri(f[1],f[2],f[3]);tri(f[1],f[3],f[4])
    end
end
local function drawLift(truck,r,height,yaw)
    local g=r.liftGeometry
    local cy=g.rearY-Config.WheelLift.reach
    local cz=g.bottom+height
    local root=g.rearY+0.35
    box(truck,0,(root+cy)*0.5,cz-0.10,0.24,root-cy,0.18,0)
    box(truck,0,root,cz+0.12,0.45,0.40,0.45,0)
    local half=r.liftData and r.liftData.halfWidth or 0.85
    local angle=math.rad(yaw or 0)
    local c,s=math.cos(angle),math.sin(angle)
    local function part(x,y,z,sx,sy,sz,color)
        box(truck,x*c-y*s,cy+x*s+y*c,cz+z,sx,sy,sz,angle,color)
    end
    part(0,0.28,-0.06,half*2+0.65,0.18,0.16)
    for _,side in ipairs({-1,1}) do
        local x=half*side
        part(x,-0.13,-0.04,0.16,0.9,0.12)
        part(x,-0.04,0.0,0.62,0.62,0.06)
        part(x,-0.39,0.06,0.65,0.12,0.14,true)
        part(x,0.23,0.06,0.65,0.12,0.14,true)
    end
end
local function carry(truck,car,r,height)
    local d,g=r.liftData,r.liftGeometry
    local anchor={x=0,y=g.rearY-Config.WheelLift.reach,z=g.bottom+height}
    local hook=GetOffsetFromEntityInWorldCoords(truck,anchor.x,anchor.y,anchor.z)
    local heading=GetEntityHeading(car)
    local old=motion[r.liftTarget]
    local wheelbase=d.front-d.rear
    if old and #(hook-old.hook)<4 then
        local rad=math.rad(old.heading)
        local rearX=old.hook.x+math.sin(rad)*wheelbase
        local rearY=old.hook.y-math.cos(rad)*wheelbase
        heading=GetHeadingFromVector_2d(hook.x-rearX,hook.y-rearY)
    end
    local truckHeading=GetEntityHeading(truck)
    local relative=FB.clamp((heading-truckHeading+180)%360-180,-Config.WheelLift.maxAngle,Config.WheelLift.maxAngle)
    heading=truckHeading+relative
    local rad=math.rad(heading)
    local rearX,rearY=hook.x+math.sin(rad)*wheelbase,hook.y-math.cos(rad)*wheelbase
    local found,ground=GetGroundZFor_3dCoord(rearX,rearY,hook.z+4.0,false)
    local pitch=found and math.deg(math.asin(FB.clamp((hook.z-ground)/wheelbase,-0.35,0.35))) or 8.0
    pitch=pitch-GetEntityPitch(truck)
    local p,a=math.rad(pitch),math.rad(relative)
    local along=d.front*math.cos(p)-d.bottom*math.sin(p)
    local vertical=d.front*math.sin(p)+d.bottom*math.cos(p)
    AttachEntityToEntity(car,truck,-1,anchor.x+math.sin(a)*along,anchor.y-math.cos(a)*along,
        anchor.z-vertical,pitch,0,relative,false,false,false,false,2,true)
    SetVehicleHandbrake(car,false)
    motion[r.liftTarget]={heading=heading,hook=hook}
end

CreateThread(function()
    if not Config.WheelLift.enabled then return end
    FBBridge.addVehicle({{
        name='ts_flatbed_select_lift',label='Aan de lepel koppelen',icon='fa-solid fa-truck-pickup',distance=Config.InteractionDistance,
        canInteract=function(e)return selected~=nil and e~=selected.truck end,
        onSelect=function(data)
            local selection=selected;selected=nil;lib.hideTextUI()
            if selection then doAction('attach',selection.truck,data.entity) end
        end
    }})
    while true do
        local sleep=300
        local wanted={}
        if selected then
            sleep=0
            if IsControlJustPressed(0,177) or GetGameTimer()-selected.at>60000 or not DoesEntityExist(selected.truck) then
                selected=nil;lib.hideTextUI()
            end
        end
        local here=GetEntityCoords(PlayerPedId())
        for id,r in pairs(api.states()) do
            local truck=api.entity(id)
            if r.lift and r.liftGeometry and truck~=0 then
                local distance=#(GetEntityCoords(truck)-here)
                local desired=r.liftTarget and Config.WheelLift.raisedHeight or Config.WheelLift.loweredHeight
                local height=heights[id] or Config.WheelLift.loweredHeight
                height=height+FB.clamp(desired-height,-GetFrameTime()*0.3,GetFrameTime()*0.3)
                heights[id]=height
                local car=api.entity(r.liftTarget)
                if car~=0 then
                    wanted[r.liftTarget]={car=car,truck=truck}
                    if NetworkHasControlOfEntity(car) then
                        sleep=0
                        carry(truck,car,r,height)
                    end
                end
                if distance<Config.WheelLift.renderDistance then
                    sleep=0
                    local yaw=car~=0 and ((GetEntityHeading(car)-GetEntityHeading(truck)+180)%360-180) or 0
                    drawLift(truck,r,height,yaw)
                end
            else heights[id]=nil end
        end
        for id,pair in pairs(carried) do
            if not wanted[id] then
                if DoesEntityExist(pair.car) and NetworkHasControlOfEntity(pair.car) and IsEntityAttachedToEntity(pair.car,pair.truck) then api.freeCar(pair.car) end
                motion[id]=nil
            end
        end
        carried=wanted
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    FBBridge.removeVehicle('ts_flatbed_select_lift')
    for _,pair in pairs(carried) do
        if DoesEntityExist(pair.car) and NetworkHasControlOfEntity(pair.car) then api.freeCar(pair.car) end
    end
end)
