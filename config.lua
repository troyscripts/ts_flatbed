Config = {}
Config.Version = '1.1.0'
Config.UpdateCheck = { Enabled = true, Repository = 'troyscripts/ts_flatbed' }

-- Gebruik de echte spawnnaam. Standaard gebaseerd op het aangeleverde YFT.
Config.Models = { energyrampamec = true }
Config.AdminAce = 'ts_flatbed.admin'
-- false = iedereen. ESX-voorbeeld: { mechanic = 0, anwb = 0 }
Config.Jobs = false
Config.UseAce = false -- bijvoorbeeld 'ts_flatbed.use', of false
Config.InteractionDistance = 3.0
Config.ServerDistance = 18.0 -- afstand tot midden van de lange vrachtwagen
Config.MaxCableLength = 20.0
Config.PullSpeed = 0.65 -- meter per seconde
Config.MaxCargoLength = 6.5
Config.MaxCargoWidth = 3.0
Config.MaxSlope = 5.0 -- vrachtwagen moet redelijk vlak staan
Config.ControlTimeout = 2500
Config.OperationTimeout = 90000
Config.StreamDistance = 100.0
Config.Debug = false

-- Visuele afstandsbediening; verschijnt vanzelf, geen inventory-item vereist.
Config.Remote = {
    enabled = true,
    model = 'prop_cs_remote_01',
    bone = 28422,
    offset = { x = 0.0, y = 0.0, z = 0.0 },
    rotation = { x = 90.0, y = 0.0, z = 0.0 },
    dict = 'amb@world_human_stand_mobile@male@text@base',
    clip = 'base'
}

Config.WheelLift = {
    enabled = true,
    reach = 1.50, -- lepel achter de achterrand
    loweredHeight = 0.18, -- hoogte boven modelonderkant, onbeladen
    raisedHeight = 0.60, -- voorwielen boven modelonderkant, beladen
    maxAngle = 55.0, -- begrenzing van de meedraaiende tweede auto
    maxLength = 10.0,
    maxWidth = 3.5,
    renderDistance = 70.0,
    -- Twee zichtbare wielkarretjes onder de achterwielen, automatisch bij koppelen.
    dollies = { enabled = true, height = 0.22, wheelRadius = 0.10 }
}

-- Bestaand GTA-model; geen voertuigmodellen uit de upload nodig in dit script.
Config.RampModel = 'imp_prop_flatbed_ramp'
-- Het model bevat de oprijconstructie. Eén object wordt als complete set geplaatst.
-- Voor een ander propmodel moeten de bovenste/onderste aansluitpunten worden ingesteld.
Config.RampHighEnd = -1 -- -1 = min Y is de kant aan de laadbak; +1 = max Y
Config.RampNativeRise = 0.0 -- hoogteverschil dat al IN het propmodel zit

-- Beginwaarden: worden afgeleid van de modelafmetingen in FiveM.
-- /flatbedafstellen kan exacte waarden opslaan in calibration.json.
Config.Defaults = {
    deckHeightFromBottom = 1.45,
    rearInset = 0.20,
    loadFromRear = 3.40,
    frontFromRear = 7.00,
    cargoLift = 0.04,
    rampX = 0.0, rampY = 0.0, rampZ = 0.0,
    rampPitch = 0.0, rampYaw = 0.0
}
-- Optionele vaste waarden per spawnnaam. Opgeslagen afstellingen gaan voor.
Config.Profiles = {
    energyrampamec = {
        frontY = 1.14492959976196, deckZ = 0.2421760559082,
        loadY = -2.45507040023803, rearY = -5.855,
        rampX = 0, rampY = 0, rampZ = 0, rampPitch = -12, rampYaw = 0
    }
}
