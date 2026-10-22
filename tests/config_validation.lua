local realPrint=print
local function check(change,expected)
 dofile('ts_flatbed/config.lua')
 change()
 local messages={}
 print=function(message)messages[#messages+1]=message end
 dofile('ts_flatbed/shared/config_version.lua')
 print=realPrint
 assert(FBConfigValid==expected)
 assert(expected or #messages>0)
end
check(function()end,true)
check(function()Config.Timing=nil end,false)
check(function()Config.Timing.WheelLift=0 end,false)
check(function()Config.Alignment.Heading=0/0 end,false)
check(function()Config.SpeedLimits.Truck=math.huge end,false)
check(function()Config.Timing.Selection='60000' end,false)
check(function()Config.Timing.Secure=nil end,false)
check(function()Config.OperationTimeout=Config.Timing.OperationReserve end,false)
check(function()Config.Alignment.Heading=20 end,false)
check(function()Config.SpeedLimits.Cargo=1 end,false)
check(function()Config.Timing.WheelLift=4000;Config.SpeedLimits.Truck=0.1 end,true)
print('PASS: missing, nonfinite, wrong-type, zero and contradictory configuration rejected; custom settings accepted')
