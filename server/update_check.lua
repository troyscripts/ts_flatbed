if FBConfigValid == false or not Config.UpdateCheck or Config.UpdateCheck.Enabled == false then return end
-- De bestaande bridge haalt alleen versiemetadata op; installeert geen updates.
CreateThread(function()
    local ok, accepted = pcall(function()
        return exports.ts_bridge:CheckForUpdates(Config.UpdateCheck)
    end)
    if not ok or not accepted then
        print('[ts_flatbed] Versiecontrole kon niet starten. Controleer de CheckForUpdates-export en configuratie van ts_bridge.')
    end
end)
