FB = {}
function FB.finite(n, low, high)
    return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
        and (not low or n >= low) and (not high or n <= high)
end
function FB.clamp(n, a, b) return math.max(a, math.min(b, n)) end
function FB.lerp(a, b, t) return a + (b - a) * t end
-- Exact hoogteverschil tussen twee wielcontactpunten, ook bij ongelijke banden.
function FB.liftPitch(wheelbase, frontBottom, rearBottom, heightDifference)
    local dz = frontBottom - rearBottom
    local span = math.sqrt(wheelbase * wheelbase + dz * dz)
    return math.asin(FB.clamp(heightDifference / span, -0.95, 0.95)) - math.atan(dz, wheelbase)
end
function FB.surface(y, g)
    local t = FB.clamp((y - g.toeY) / (g.rearY - g.toeY), 0.0, 1.0)
    return FB.lerp(g.groundZ, g.deckZ, t)
end
-- Twee steunpunten benaderen de wielbasis: soepel van grond naar plaat naar bak.
function FB.pose(y, g, halfWheelbase, bottom)
    local front = FB.surface(y + halfWheelbase, g)
    local rear = FB.surface(y - halfWheelbase, g)
    local pitch = math.atan(front - rear, halfWheelbase * 2)
    return (front + rear) * 0.5 - bottom * math.cos(pitch) + Config.Defaults.cargoLift,
        math.deg(pitch)
end
function FB.validGeometry(g)
    if type(g) ~= 'table' then return false end
    for _, k in ipairs({'rearY','toeY','deckZ','groundZ','loadY','frontY','rampX','rampY','rampZ','rampPitch','rampYaw'}) do
        if not FB.finite(g[k], -30, 30) and not (k == 'rampYaw' and FB.finite(g[k], -360, 360)) then return false end
    end
    return g.rearY - g.toeY >= 1 and g.rearY - g.toeY <= 15
        and g.deckZ > g.groundZ and g.deckZ - g.groundZ < 3
        and g.loadY > g.rearY and g.frontY > g.loadY
end

-- Kabel koppelen en daadwerkelijk laden zijn aparte controles.
-- Bereken een interval voor het voertuigorigin, ook bij asymmetrische modellen.
function FB.cargoPlan(low, high, g, requireFit)
    local length, width = high.y-low.y, high.x-low.x
    local tolerance = Config.CargoSizeTolerance or 0.15
    local minimum, maximum = g.rearY-low.y, g.frontY-high.y
    local y = minimum <= maximum and FB.clamp(g.loadY, minimum, maximum) or g.loadY
    local z = g.deckZ-low.z+Config.Defaults.cargoLift
    if not requireFit then return {y=y,z=z} end
    if length > Config.MaxCargoLength+tolerance or width > Config.MaxCargoWidth+tolerance then
        return nil, ('Gemeten auto: %.2f m lang, %.2f m breed. Ingestelde maxima: %.2f × %.2f m (+ %.2f m meetmarge). Controleer de modelmaten/config.'):format(
            length,width,Config.MaxCargoLength,Config.MaxCargoWidth,tolerance)
    end
    if minimum > maximum then
        return nil, ('Auto %.2f m lang; ingestelde laadbak %.2f m. Controleer achterrand en voorrand met /flatbedafstellen.'):format(length,g.frontY-g.rearY)
    end
    return {y=y,z=z}
end
