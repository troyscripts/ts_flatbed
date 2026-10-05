local api=FlatbedClient
if not api then return end

-- Alleen lokale rij-invoer blokkeren: geen engine-health, sloten of stoelstatus wijzigen.
-- De blokkeeracties gelden één frame; bij uitstappen/losmaken is invoer direct vrij.
local driveControls={59,60,63,64,71,72,76}
local held
CreateThread(function()
    while true do
        local sleep=200
        local ped=PlayerPedId()
        local nextHeld
        local car=GetVehiclePedIsIn(ped,false)
        if car~=0 then
            local id=api.net(car)
            for truckId,r in pairs(api.states()) do
                local onBed=id and r.target==id and r.stage=='loaded'
                local onLift=id and r.lift and r.liftTarget==id
                if onBed or onLift then
                    local truck=api.entity(truckId)
                    if truck~=0 then
                        sleep=0
                        if GetPedInVehicleSeat(car,-1)==ped then
                            for _,input in ipairs(driveControls) do DisableControlAction(0,input,true) end
                        end
                        -- Instappen kan netwerkcontrole laten wisselen of de attachment verbreken.
                        -- De nieuwe eigenaar houdt de laadbakpositie vast; lepel volgt via carry.
                        if onBed and NetworkHasControlOfEntity(car) then
                            local p=r.load
                            if not held or held.car~=car or held.truck~=truck
                                or held.x~=p.x or held.y~=p.y or held.z~=p.z
                                or not IsEntityAttachedToEntity(car,truck) then
                                api.attachCargo(car,truck,p,0)
                            end
                            nextHeld={car=car,truck=truck,x=p.x,y=p.y,z=p.z}
                            SetVehicleHandbrake(car,true)
                        end
                    end
                    break
                end
            end
        end
        held=nextHeld
        Wait(sleep)
    end
end)
