# TroyScripts — ts_flatbed

**Versie 0.1.1-beta · 4 oktober 2026**

Flatbedbediening voor de vaste laadbak van `energyrampamec`: plaatsbare oprijplaten,
een geleide lier, vastzetten en afladen. Tijdens de lierbeweging houdt de bediener
een afstandsbediening vast en speelt een bedieningsanimatie. Andere spelers in de
buurt krijgen de afstandsbediening ook te zien.

Deze versie gebruikt je bestaande **ts_bridge** voor meldingen, jobcontrole,
targetregistratie, controle of je personage dood is, voortgang en invoervensters.
De koppeling is gemaakt tegen de bestaande API 1 uit je aangetroffen bridgebestanden
en de 0.0.8-update. **Er is geen wijziging aan ts_bridge nodig.**

## Wat deze eerste versie doet

- Rijplaten plaatsen/opbergen via ox_target of `/flatbed`.
- Bestaand GTA-model `imp_prop_flatbed_ramp` als complete oprijconstructie.
- Vrachtwagen vastzetten zolang de rijplaten zijn geplaatst.
- Een stilstaande, lege auto achter de truck aan de lier koppelen.
- Langzaam opladen en automatisch vastzetten, ook met een kapotte motor.
- Handmatig opgereden auto's vastzetten.
- Geleid afladen, of losmaken op de bak zodat iemand zelf kan afrijden.
- Zichtbare kabel en afstandsbediening. Geen inventory-item nodig.
- Een losse lepel onder de achterkant voor een tweede auto, met meedraaiende koppeling.
- Nederlandse ox_lib-meldingen, menu en voortgang.
- Instelbare voertuigmodellen, rechten, afmetingen, snelheid en aansluitpunten.
- Afstellingen in-game opslaan, zonder steeds de resource te herstarten.

De originele laadbak beweegt niet. De lier verplaatst de auto via een geleide
laadroute en gebruikt een visuele kabel; dit is geen vrij zwaaiende GTA-rope-physics
simulatie. De motor wordt niet gerepareerd of aangezet.

## Installeren

1. Zet de map `ts_flatbed` in je serverresources, bijvoorbeeld onder `[troyscripts]`.
2. Laat de bestaande voertuigresource normaal staan en starten. Deze download bevat
   uitsluitend het nieuwe script; je beveiligde voertuigbestanden zijn niet gewijzigd
   en worden niet opnieuw meegeleverd.
3. Zorg dat OneSync, `ox_lib`, `ox_target` en **`ts_bridge`** actief zijn.
4. Voeg onder de bestaande startregels voor het voertuig en ox-resources toe:

```cfg
ensure ts_flatbed
```

Voorbeeld van de volgorde, als jouw voertuigresource inderdaad zo heet:

```cfg
ensure ox_lib
ensure ox_target
ensure ts_bridge
ensure energyrampamec
ensure ts_flatbed
```

Het script gebruikt standaard **spawnnaam `energyrampamec`**, afgeleid van je YFT.
Als je auto met een andere naam spawnt, wijzig dan `Config.Models` in `config.lua`.
De resourcenaam van het voertuig en de spawnnaam hoeven niet hetzelfde te zijn.

ESX is alleen nodig als je `Config.Jobs` instelt; deze controle verloopt via de
frameworkinstelling in ts_bridge. SQL en nieuwe ox_inventory-items zijn niet nodig.
Laat de nieuwe resource **ts_flatbed** heten: de bridge gebruikt deze naam voor
het eigenaarschap van de targetopties. Bij opstart wordt gecontroleerd of de
vereiste bridgefuncties beschikbaar zijn.

## Gebruik

1. Parkeer op een vlakke, vrije plek. Houd achter de truck ruimte voor de volledige
   oprijconstructie, een auto en de bediener. Stap uit.
2. Richt met ox_target (standaard linker ALT) op de vrachtwagen en kies **Flatbed bedienen**.
   Je kunt ook `/flatbed` gebruiken wanneer je ernaast staat.
3. Kies **Rijplaten plaatsen**. De vrachtwagen wordt nu vastgezet.
4. Zet de te laden auto recht achter de onderkant van de rijplaten, met de neus naar
   de vrachtwagen. Alle inzittenden moeten uitstappen. Een defecte motor is geen bezwaar.
5. Kies op de truck **Lier aansluiten op voertuig** en selecteer daarna via ox_target
   de gewenste auto. Deze selectiestap vervalt na één minuut of met BACKSPACE.
6. Kies op de truck **Lier binnenhalen / voertuig laden**. De afstandsbediening verschijnt
   automatisch in je hand. Blijf naast de vrachtwagen en houd de laadstrook vrij.
7. Na het laden staat de auto automatisch vast. **Berg de rijplaten op voordat je rijdt.**

Voor lossen: plaats de rijplaten en kies **Voertuig met lier afladen**. Hiervoor hoeft
de motor van de geladen auto ook niet te werken. De afstandsbediening wordt opnieuw
gebruikt. Met **Voertuig losmaken op laadbak** blijft de auto op de bak staan en kan
iemand zelf achteruit afrijden.

Heb je zelf een auto opgereden? Kies **Voertuig op laadbak vastzetten** en target die
auto. Ook hiervoor moet hij leeg zijn en dezelfde kant op wijzen als de truck.

**BACKSPACE tijdens de beweging:** breekt de lieractie af. Een afgebroken laadpoging
zet de auto terug op zijn startplek en maakt de kabel los. Een afgebroken lossing
zet hem terug op de laadpositie. De afstandsbediening en eigen animatie worden opgeruimd.

## Tweede auto aan de lepel

1. Laad eerst de eerste auto op de laadbak en berg de rijplaten op.
2. Open **Lepel voor tweede auto** in het flatbedmenu, of gebruik `/flatbedlepel`.
3. Kies **Lepel uitklappen**. Onder de achterkant verschijnt de wielheffer met
   gele uiteinden en twee wielsteunen.
4. Zet een tweede personenauto recht achter de truck, in dezelfde rijrichting.
   De voorwielen moeten bij de wielsteunen staan. Iedereen stapt uit.
5. Kies **Tweede auto koppelen** en selecteer die auto met ox_target.
   De voorwielen worden opgetild; de auto volgt een begrensd scharnier tijdens rijden.
6. Stop om te lossen, kies **Tweede auto losmaken** en berg de lepel op.

De lepel en de rijplaten mogen niet tegelijk uitgeklapt zijn. Je moet daarom de
tweede auto eerst losmaken en de lepel opbergen voordat je de eerste auto kunt
afladen. Beide auto's blijven afzonderlijk geregistreerd.

De lepel is een **door het script getekende metalen constructie**, zonder apart
gestreamd propmodel of eigen collision. De tweede auto wordt via een geleide,
meedraaiende attachment vastgehouden; het is geen ingebouwde GTA-towtruck-lepel
met volledige wiel-/ophangingsphysics. Het script benadert de hoogte bij de
achterwielen met een grondmeting. Test bochten, achteruitrijden en hellingen in-game.
Positie, hoogte, maximaal stuurhoekverschil en maximale voertuigafmetingen staan in
`Config.WheelLift`. Motorfietsen en fietsen worden niet aan de lepel gekoppeld.

## De eerste afstelling voor dit voertuig

De YFT-bestanden zijn beveiligd en deze omgeving kan FiveM niet starten. Daarom
zijn de exacte pasvorm, prop-collision, animatie en netwerksynchronisatie nog niet
in GTA getest. Ook de tweede auto en de getekende lepel moeten op je server worden
gecontroleerd. De beginwaarden worden uit modelafmetingen berekend; het script
probeert daarnaast de bovenkant van de laadbak met een botsingsmeting te vinden.
**Beschouw dit als een eerste testversie, niet als een in-game gevalideerde release.**

Begin met één normale personenauto. Controleer eerst of de rijplaten werkelijk de
grond en de achterrand raken. Test zelf langzaam oprijden vóór het testen van de
lier, zodat ook de fysieke aansluiting van de platen wordt gecontroleerd. Test
daarna met een tweede speler of beide dezelfde belading en afstandsbediening zien.

Geef je beheerders afstelrechten, bijvoorbeeld:

```cfg
add_ace group.admin ts_flatbed.admin allow
```

Dit werkt voor spelers die al lid zijn van jouw ACE-groep `group.admin`.
Een ESX-adminrang alleen is niet automatisch hetzelfde als deze ACE-groep.

### `/flatbedmeten`

Toont rode, groene en blauwe markers voor achterrand, laadpositie en voorrand.
Linksonder zie je de positie van de linkervoet ten opzichte van de vrachtwagen.
F8 toont de modelnaam en modelgrenzen. Nogmaals uitvoeren schakelt de weergave uit.
Gebruik voetcoördinaten als benadering; de zool en het voetbot vallen niet exact samen.

### `/flatbedafstellen`

Open dit naast een lege vrachtwagen met opgeborgen rijplaten en lepel. Je kunt instellen:

| Instelling | Betekenis |
| --- | --- |
| Achterrand Y | Waar de laadbak achter eindigt; negatieve Y is naar achteren |
| Bovenkant Z | Het rijoppervlak van de laadbak ten opzichte van het voertuigorigin |
| Midden geladen auto Y | De gewenste positie van het voertuigorigin van de geladen auto |
| Voorrand Y | Grens vóór op de laadbak, vóór de cabine |
| Rijplaten X/Y/Z | Kleine positiecorrecties boven op de berekende plaatsing |
| Hellingshoek | Correctie in graden op de berekende helling |
| Draairichting | Correctie in graden op de standaardrichting |

Positieve X is rechts, positieve Y is voorwaarts, positieve Z is omhoog.
Pas **Bovenkant Z** aan als zowel de lierroute als de auto op de laadbak te hoog/laag
zit. Gebruik **Rijplaten Z** alleen voor een correctie aan het zichtbare propmodel.
Grote propcorrecties veranderen de lierroute niet: stel daarom eerst achterrand en
laadbakhoogte correct af. Als het standaardprop zelf een ingebouwde helling heeft,
kun je `Config.RampNativeRise` in `config.lua` aanpassen.

Opgeslagen waarden gelden voor alle trucks van hetzelfde model en staan in het
automatisch aangemaakte `calibration.json` in deze resource. Bewaar dit bestand bij
updates. Wil je terug naar de beginwaarden? Stop de resource, maak een backup van
`calibration.json`, verwijder daarna de betreffende modelinstelling en start opnieuw.

## Instellingen en toegang

Standaard mag iedereen de flatbed gebruiken. Voor alleen bepaalde ESX-banen:

```lua
Config.Jobs = { mechanic = 0, anwb = 0 }
```

Gebruik de echte interne jobnamen van je server. Het getal is de minimale rang.
Met `Config.UseAce = 'ts_flatbed.use'` kun je daarnaast een ACE-recht vereisen.
Bij beide instellingen moet de speler aan beide voorwaarden voldoen.

`Config.PullSpeed` bepaalt de liersnelheid. `Config.MaxCargoLength` en
`Config.MaxCargoWidth` beperken de maat van auto's. Boten, vliegtuigen,
helikopters en treinen worden niet geladen. Auto's moeten recht staan en mogen
niet door een ander script ergens aan vastzitten.

`Config.Remote.enabled = false` schakelt de afstandsbediening en de bijbehorende
animatie uit. Model, handpositie, rotatie en animatie staan in hetzelfde configblok.
Er wordt een bestaande GTA-afstandsbediening gebruikt; geen zelfgemaakt model.

## Als iets niet werkt

- **Geen target/menu:** controleer de spawnnaam en of ox_target/ox_lib vóór dit script starten.
- **Bridgecontrole mislukt:** start ts_bridge vóór ts_flatbed. Controleer zijn
  configuratie en API-functies; deze koppeling gebruikt de reeds bestaande API 1.
- **Geen afstelrechten:** controleer het ACE-recht en je daadwerkelijke ACE-groep.
- **Rijplaten zweven/verkeerd om:** maak een zijaanzicht met `/flatbedmeten` actief en
  noteer de afstelwaarden. Controleer de achterrand, laadbakhoogte en propcorrecties.
- **Geen netwerkcontrole:** laat iedereen uitstappen en probeer opnieuw. Beveiligings-
  en voertuigscripts kunnen besturing of attachments beperken; controleer hun logs.
- **Laadstrook geblokkeerd:** haal personen/voertuigen uit de strook achter en op de bak.
  Het script controleert personen en voertuigen; kies zelf een plaats zonder muren,
  palen of andere obstakels. De geleide route is geen volledige botsingssimulatie.
- **Andere telefoon/emote zichtbaar:** stop die emote voordat je de lier gebruikt.
- **Resource herstarten:** doe dit bij voorkeur zonder lading. Bij stoppen worden de
  rijplaten, lepelweergave en afstandsbedieningen verwijderd, beide auto's losgemaakt,
  de handrem van vrijgegeven lading
  losgelaten en de truck vrijgegeven. Belading wordt niet in een database bewaard.

## Technische controle

Alle Lua-bestanden zijn met Lua 5.4 op syntax gecontroleerd. Geometrie en server-
scenario's zijn met gesimuleerde FiveM-functies getest: concurrerende gebruikers,
ongeldige tokens, laden/lossen, annuleren, inzittenden, routing buckets, afstand,
disconnect, afstelrechten, bridge-jobcontrole, twee auto's tegelijk, onderlinge
blokkering van rijplaten/lepel en opruimen bij resource-stop. Dat vervangt geen test
met het daadwerkelijke voertuig op een FiveM-server.

Bronnen voor de gebruikte interfaces:

- https://docs.fivem.net/natives/
- https://docs.fivem.net/docs/developers/server-security/
- https://coxdocs.dev/ox_lib
- https://coxdocs.dev/ox_target

## Changelog

### 0.1.1-beta

- Maatcontrole uitgevoerd bij laden/vastzetten, niet meer bij alleen kabel aansluiten.
- Laadpositie automatisch binnen de voor- en achterrand gekozen, inclusief modellen
  waarvan het origin niet precies in het midden zit.
- Een meetmarge van 0,15 meter op de ingestelde maximale voertuigafmetingen. Optioneel te
  wijzigen met `Config.CargoSizeTolerance` (in meters).
- Afwijzingen tonen nu de gemeten lengte/breedte en de relevante ingestelde grenzen;
  extra modelinformatie verschijnt in F8.
- Bestaande config en `calibration.json` blijven behouden bij dit updatepakket.

Parkeer voor het aansluiten de hele auto achter de lage uiteinden van de rijplaten,
niet eronder. Deze update wijzigt de plaatsing of collision van de rijplaten niet.

### 0.1.0-beta

- Eerste afzonderlijke resource voor `energyrampamec` met vaste laadbak.
- Oprijconstructie, geleide lier, visuele kabel en vastzetten/losmaken.
- Afstandsbediening in de hand met bedieningsanimatie tijdens laden en lossen.
- Losse getekende wielheffer en afzonderlijke koppeling voor een tweede auto.
- Aangesloten op de bestaande ts_bridge API 1; geen bridge-update nodig.
- ox_target-menu, commandofallback, Nederlandse meldingen en in-game afstellen.
- Servercontrole op toegang, afstand, bezetting en gelijktijdige bediening.
- Herstel bij afbreken/disconnect en opruimen bij resource-stop.
