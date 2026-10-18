FBConfigValid = Config.Version == '1.1.0'
if not FBConfigValid then
    print(('^1[ts_flatbed] Configversie %s; vereist: 1.1.0. Neem config.lua uit het huidige releasepakket over en zet eigen job/rechteninstellingen terug.^7'):format(tostring(Config.Version or 'ontbreekt')))
end
