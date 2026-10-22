FBConfigValid = true
local function invalid(message)
    FBConfigValid = false
    print('^1[ts_flatbed] ' .. message .. '^7')
end
if Config.Version ~= '1.1.1' then
    invalid(('Configversie %s; vereist: 1.1.1. Gebruik de nieuwe config.lua en zet eigen instellingen terug.'):format(tostring(Config.Version or 'ontbreekt')))
    return
end
local function number(path, value, minimum, maximum)
    if type(value) ~= 'number' or value ~= value or value < minimum or value > maximum then
        invalid(path .. ': verwacht een getal tussen ' .. minimum .. ' en ' .. maximum)
    end
end
if type(Config.Timing) ~= 'table' then
    invalid('Config.Timing ontbreekt of is geen tabel.')
else
    number('Config.Timing.ModelLoad', Config.Timing.ModelLoad, 1, 600000)
    number('Config.Timing.Restore', Config.Timing.Restore, 1, 600000)
    number('Config.Timing.Selection', Config.Timing.Selection, 1, 600000)
    number('Config.Timing.Secure', Config.Timing.Secure, 1, 600000)
    number('Config.Timing.MinimumWinch', Config.Timing.MinimumWinch, 1, 600000)
    number('Config.Timing.RampAndHook', Config.Timing.RampAndHook, 1, 600000)
    number('Config.Timing.WheelLift', Config.Timing.WheelLift, 1, 600000)
    number('Config.Timing.LiftGrace', Config.Timing.LiftGrace, 1, 600000)
    number('Config.Timing.ObstacleCheck', Config.Timing.ObstacleCheck, 1, 600000)
    number('Config.Timing.SnapshotRate', Config.Timing.SnapshotRate, 1, 600000)
    number('Config.Timing.ActionRate', Config.Timing.ActionRate, 1, 600000)
    number('Config.Timing.OperationReserve', Config.Timing.OperationReserve, 1, 600000)
end
if type(Config.SpeedLimits) ~= 'table' then
    invalid('Config.SpeedLimits ontbreekt of is geen tabel.')
else
    number('Config.SpeedLimits.Truck', Config.SpeedLimits.Truck, 0, 10)
    number('Config.SpeedLimits.LiftTruck', Config.SpeedLimits.LiftTruck, 0, 10)
    number('Config.SpeedLimits.Cargo', Config.SpeedLimits.Cargo, 0, 10)
    number('Config.SpeedLimits.ServerCargo', Config.SpeedLimits.ServerCargo, 0, 10)
    number('Config.SpeedLimits.LiftCargo', Config.SpeedLimits.LiftCargo, 0, 10)
end
if type(Config.Alignment) ~= 'table' then
    invalid('Config.Alignment ontbreekt of is geen tabel.')
else
    number('Config.Alignment.SecureSide', Config.Alignment.SecureSide, 0, 30)
    number('Config.Alignment.DeckEdge', Config.Alignment.DeckEdge, 0, 30)
    number('Config.Alignment.DeckHeight', Config.Alignment.DeckHeight, 0, 30)
    number('Config.Alignment.HookSide', Config.Alignment.HookSide, 0, 30)
    number('Config.Alignment.HookFront', Config.Alignment.HookFront, 0, 30)
    number('Config.Alignment.Heading', Config.Alignment.Heading, 0, 180)
    number('Config.Alignment.ServerSide', Config.Alignment.ServerSide, 0, 30)
    number('Config.Alignment.ServerHeading', Config.Alignment.ServerHeading, 0, 180)
    number('Config.Alignment.HookBehind', Config.Alignment.HookBehind, 0, 30)
    number('Config.Alignment.LiftSide', Config.Alignment.LiftSide, 0, 30)
    number('Config.Alignment.LiftLongitudinal', Config.Alignment.LiftLongitudinal, 0, 30)
    number('Config.Alignment.LiftHeight', Config.Alignment.LiftHeight, 0, 30)
    number('Config.Alignment.Finish', Config.Alignment.Finish, 0, 30)
end
number('Config.OperationTimeout', Config.OperationTimeout, 1, 3600000)
number('Config.PullSpeed', Config.PullSpeed, 0.01, 20)
if FBConfigValid then
    if Config.OperationTimeout <= Config.Timing.OperationReserve + math.max(Config.Timing.Secure, Config.Timing.MinimumWinch) then
        invalid('OperationTimeout moet groter zijn dan OperationReserve plus Secure/MinimumWinch.')
    end
    if Config.SpeedLimits.ServerCargo < Config.SpeedLimits.Cargo
        or Config.Alignment.ServerHeading < Config.Alignment.Heading
        or Config.Alignment.ServerSide < math.max(Config.Alignment.SecureSide, Config.Alignment.HookSide) then
        invalid('De servermarges mogen niet strenger zijn dan de bijbehorende clientmarges.')
    end
end
