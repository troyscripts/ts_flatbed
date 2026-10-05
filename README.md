# TroyScripts — ts_flatbed

**Script 0.5.3 · Config 1.1.0 · 4 oktober 2026**

Flatbedbediening voor de vaste laadbak van `energyrampamec`: plaatsbare oprijplaten,
een geleide lier, vastzetten en afladen. Tijdens de lierbeweging houdt de bediener
een afstandsbediening vast en speelt een bedieningsanimatie. Andere spelers in de
buurt krijgen de afstandsbediening ook te zien.

Deze versie gebruikt je bestaande **ts_bridge** voor meldingen, jobcontrole,
targetregistratie, controle of je personage dood is, voortgang en invoervensters.
De koppeling is gemaakt tegen de bestaande API 1 uit je aangetroffen bridgebestanden
en de 0.0.8-update. **Er is geen wijziging aan ts_bridge nodig.**

## Functies

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

## Meerijden in de eigen auto

Aan de lepel mogen bestuurder en passagiers blijven zitten tijdens koppelen,
vervoer en losmaken. De bergingsmedewerker blijft buiten naast de stilstaande
truck staan voor de bediening. De client die netwerkcontrole over de tweede auto
heeft (vaak de inzittende bestuurder) voert de koppeling uit.

Op de laadbak mag de eigenaar na het laden/vastzetten weer instappen en meerijden.
Tijdens het lieren, vastzetten en met de lier afladen moet de auto nog leeg zijn;
laat de inzittenden daarvoor uitstappen. Bij **Voertuig losmaken op laadbak** kan
de bestuurder blijven zitten en na vrijgeven zelf afrijden.

Gas, rem, handrem en stuurinvoer vanuit een vastgekoppelde auto worden tijdelijk
geblokkeerd. Uitstappen blijft mogelijk. Na losmaken werkt de invoer weer normaal;
de motor of schade wordt niet hersteld en de deursloten worden niet gewijzigd.
Het script controleert hiervoor de transportstatus, geen database-eigendom.
Normale toegangsregels van je voertuigsloten blijven gelden.

## Tweede auto aan de lepel

1. Laad eerst de eerste auto op de laadbak en berg de rijplaten op.
2. Open **Lepel voor tweede auto** in het flatbedmenu, of gebruik `/flatbedlepel`.
3. Kies **Lepel uitklappen**. Onder de achterkant verschijnt de wielheffer met
   gele uiteinden en twee wielsteunen.
4. Zet een tweede personenauto recht achter de truck, in dezelfde rijrichting.
   De voorwielen moeten bij de wielsteunen staan. Inzittenden mogen blijven zitten;
   de bergingsmedewerker bedient de lepel buiten de vrachtwagen.
5. Kies **Tweede auto koppelen** en selecteer die auto met ox_target.
   De voorwielen worden opgetild; de auto volgt een begrensd scharnier tijdens rijden.
6. Stop om te lossen, kies **Tweede auto losmaken** en berg de lepel op.

De lepel en de rijplaten mogen niet tegelijk uitgeklapt zijn. Je moet daarom de
tweede auto eerst losmaken en de lepel opbergen voordat je de eerste auto kunt
afladen. Beide auto's blijven afzonderlijk geregistreerd.

De lepel is een **door het script getekende metalen constructie**, zonder apart
gestreamd propmodel of eigen collision. De tweede auto wordt via een geleide,
meedraaiende attachment vastgehouden; het is geen ingebouwde GTA-towtruck-lepel
met volledige wiel-/ophangingsphysics. Onder beide achterbanden verschijnen automatisch wielkarretjes met elk vier
draaiende wieltjes. De achterwielhoogte houdt rekening met deze steunen; de
wieltjes draaien op basis van de afgelegde afstand, ook achteruit. Ze verdwijnen
bij losmaken. Dit is visuele ondersteuning binnen dezelfde geleide koppeling,
geen afzonderlijke dolly-physics. De banden worden gemeten via de wielbotten en
het band-collisionformaat (met modelmaten als fallback). Test bochten,
achteruitrijden, verhoogde wegen en hellingen in-game. Met
`Config.WheelLift.dollies.enabled = false` vervallen de karretjes en wordt de
achterwielhoogte weer op de grond gericht.
Positie, hoogte, maximaal stuurhoekverschil en maximale voertuigafmetingen staan in
`Config.WheelLift`. Motorfietsen en fietsen worden niet aan de lepel gekoppeld.

## De eerste afstelling voor dit voertuig

Het standaardprofiel voor `energyrampamec` bevat de aangeleverde kalibratie exact,
inclusief achterrand Y -5.855, dekhoogte Z 0.2421760559082 en rampcorrectie -12°.
Een bestaand `calibration.json` blijft voorrang houden. Dit bestand wordt niet
meegeleverd of overschreven; je aangeleverde instellingen zijn in `config.lua`
opgenomen.

De lierroute is door jou in-game getest. De nieuwe wielkarretjes, fysieke
rijplaat-collision en multiplayerweergave moeten nog op je server worden getest;
de ontwikkelomgeving kan FiveM niet starten. Rijplaten worden nu zelfstandig
bevroren geplaatst, met expliciet geladen en ingeschakelde collision. Een
geleide lierbeweging alleen bewijst niet dat een auto ook fysiek op de platen kan
rijden. De collision-vorm van het gebruikte propmodel blijft bepalend.

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
met het daadwerkelijke voertuig op een FiveM-server. Voor 0.5.0 zijn ook
de achterwiel-steunhoogte, ongelijke wielcontactpunten, een gesimuleerd clientframe
met dollies, cleanup, configversiecontrole en de bridge-checker-aanroep getest.

Bronnen voor de gebruikte interfaces:

- https://docs.fivem.net/natives/
- https://docs.fivem.net/docs/developers/server-security/
- https://coxdocs.dev/ox_lib
- https://coxdocs.dev/ox_target

## Update naar 0.5.3 en versiecontrole

Dit pakket bevat alleen gewijzigde bestanden ten opzichte van 0.5.2. Installeer
het over 0.5.2 en herstart met een lege truck: `restart ts_flatbed`. Config.lua en
calibration.json worden niet meegeleverd; configversie blijft 1.1.0. Er is geen
nieuwe succesvolle-configmelding in de console toegevoegd.

De lokale configcontrole verwacht `Config.Version = '1.1.0'`. Bij een oude of
ontbrekende versie start de bediening niet en verschijnt een duidelijke melding.
De scriptversie in `fxmanifest.lua` is onafhankelijk hiervan `0.5.3`.

`server/update_check.lua` gebruikt de bestaande serverexport
`exports.ts_bridge:CheckForUpdates(Config.UpdateCheck)`. **ts_bridge blijft
0.0.8; geen bridge-update is nodig.** De checker leest `version.json` uit de
standaardbranch van `troyscripts/ts_flatbed`, vergelijkt numerieke versies en
meldt updates in de serverconsole. Het installeren blijft handmatig. Uitschakelen:
`Config.UpdateCheck.Enabled = false`.

Plaats de meegeleverde **version.json in de hoofdmap van je GitHub-repository**,
naast `fxmanifest.lua`. De repository is gecontroleerd; dit bestand stond er bij
het maken van de update nog niet. Deze download publiceert niets naar GitHub.
Zonder dat bestand meldt de checker HTTP 404. Verhoog bij volgende releases zowel
de manifestversie als `version` in dit JSON-bestand; verhoog de configversie
alleen als het configuratieformaat verandert. De bridge verwerkt time-outs,
ongeldige antwoorden en een lokale versie die nieuwer is dan GitHub.

## Changelog

### 0.5.3 / config blijft 1.1.0

- De passagiersmodule vernieuwt de vaste laadbak-attachment alleen na een
  gewijzigde laadpositie, wisseling van netwerkcontrole of verbroken koppeling.
- De lepel vernieuwt de attachment alleen bij een positieverschil groter dan
  1 cm of hoekverschil groter dan 0.25 graad, met maximaal 20 updates/seconde.
  De bestaande attachment volgt de truck ook tussen die updates.
- Eerste koppeling, herstel van een verbroken koppeling en overname van
  netwerkcontrole gebeuren direct, zonder de updatebegrenzer af te wachten.
- Bewegingshistorie van de lepel vervalt bij verlies van netwerkcontrole.
- Schadevlaggen worden eenmaal ingesteld bij overname, niet opnieuw elk frame.
  Collision en tijdelijke botsingsuitsluiting tussen trekker en lading blijven actief.
- Tests met gesimuleerde frames controleren herhaling, updatebegrenzing,
  koppelingsherstel en overname. Dit bewijst geen lagere multiplayervertraging:
  daarvoor is een nieuwe in-game test met twee spelers nodig.

Test dezelfde route met iemand op de bestuurdersstoel van de vervoerde auto.
Vergelijk leeg vervoer, meerijden op de laadbak en meerijden aan de lepel. Als
vertraging blijft bestaan, noteer bij wie het zichtbaar is, of de auto achterloopt
of het hele beeld hapert, en de ping van beide spelers. Instappen op een
passagiersstoel kan als vergelijking helpen om de invloed van netwerkcontrole
te onderscheiden, maar is geen vereiste van deze update.

### 0.5.2 / config blijft 1.1.0

- Inzittenden toegestaan bij koppelen en losmaken van de lepel.
- Bediener hoeft de netwerkcontrole niet meer van de inzittende over te nemen.
- Lokaal rij-invoer blokkeren tijdens vervoer; uitstappen blijft beschikbaar.
- De bestuurderclient bewaakt de attachment op de laadbak na instappen of een
  wisseling van netwerkcontrole.
- Nieuwe passagiersmodule toegevoegd aan fxmanifest.lua.
- Config en bridge niet gewijzigd ten opzichte van 0.5.1. Dit cumulatieve pakket
  bevat ook de collisionfix en configwijzigingen van 0.5.1.
- Gesimuleerde tests voor bezet koppelen/losmaken, rij-invoer, netwerkcontrole,
  stoelwisseling en vrijgeven geslaagd. Meerijden nog met twee spelers in-game testen.

### 0.5.1 / config 1.1.0

- De auto aan de lepel krijgt expliciete collision op zowel de eigenaarclient als
  de clients van andere spelers, na de attachment-update.
- Alleen botsingen tussen de gekoppelde auto en de eigen trekker worden per frame
  onderdrukt. Deze uitzondering stopt bij losmaken; andere voertuigen worden niet
  uitgesloten. De attachment wordt met collision ingeschakeld gemaakt.
- Normale schade, zichtbare schade en afbreekbare onderdelen ingeschakeld op de
  netwerk-eigenaar. Bestaande motor- en carrosserieschade worden niet gerepareerd
  of overschreven. Er wordt geen kunstmatige schadeberekening toegevoegd.
- Lepel: reach 1.50, maxLength 10.0, maxWidth 3.5. De overige aangeleverde waarden
  en de wielkarretjes blijven behouden. MaxCargoWidth blijft 3.0.
- Servergrenzen voor wielbasis en wielposities volgen nu maxLength; de oude vaste
  grenzen van 3.5/5.5 meter blokkeren ruimere configuraties niet meer.
- Scriptversie en GitHub-metadata 0.5.1; configversie 1.1.0. ts_bridge blijft 0.0.8.

De gebruiker heeft de ruimere lepelinstellingen met een Mule getest. De nieuwe
collision- en schadeaanpassing is hier met gesimuleerde natives gecontroleerd,
maar nog niet in GTA. Test na herstart met een tweede speler die achterop de
gekoppelde auto rijdt, zowel met een stilstaande als rijdende trekker. Controleer
botsing en extra schade ook na losmaken. Voertuighandling en andere schade- of
godmode-scripts kunnen de uiteindelijke GTA-schade beïnvloeden. De geleide
attachment blijft de auto op de lepel houden; hij vliegt bij een aanrijding niet
vrij weg.

### 0.5.0 / config 1.0.0

- Maximale laadbak-autobreedte 3.0 m en lepel-autobreedte 3.2 m; de servercontrole
  op wielafstand volgt de ingestelde lepelbreedte.
- Achterwielkarretjes voor de tweede auto, met draaiende wieltjes en opruimen bij losmaken.
- Hoogte van de tweede auto berekend uit wielcontactpunten en dollyhoogte.
- Achterwielmaten servermatig begrensd en met andere spelers gedeeld.
- Aangeleverde kalibratie als standaardprofiel voor energyrampamec.
- Rijplaten als vaste wereldobjecten met expliciete collision-loading en collision aan.
- Configversiecontrole en GitHub-versiecontrole via de bestaande ts_bridge-export.
- version.json voor de hoofdmap van troyscripts/ts_flatbed.


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
