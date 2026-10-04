FB = {}
function FB.finite(n, low, high)
    return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
        and (not low or n >= low) and (not high or n <= high)
end
function FB.clamp(n, a, b) return math.max(a, math.min(b, n)) end
function FB.lerp(a, b, t) return a + (b - a) * t end
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
