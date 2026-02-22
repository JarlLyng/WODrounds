# Review af WODrounds (grundigt)

**Status efter rettelser:** (1) HealthKit bruger nu aktiv tid (effectiveWorkoutEndDate). (2) Countdown starter fra Date() i auth-callback. (3) WODTimerEngine er delt i Shared/. (4) Lokalisering en/da med Localizable.strings; Watch bruger "Following iPhone" (da: Følger iPhone).

**Fund (prioriteret)**
1. **Høj** – HealthKit-workout tager ikke højde for pauser, så træningens varighed i Apple Health bliver længere end den faktiske arbejdstid ved pause/resume. Pause/resume i UI påvirker kun timeren, ikke HealthKit-registreringen. Se `WODrounds/ContentView.swift:340-348` og `WODrounds/HealthKitWorkout.swift:37-73`.
2. **Middel** – Countdown-starttid bruger det oprindelige `now` fra knaptryk, ikke tidspunktet efter HealthKit-autorisation. Hvis brugeren bruger tid på autorisationsdialogen, kan countdown blive kortere eller starte med det samme. Se `WODrounds/ContentView.swift:328-335`.
3. **Lav** – Timer-engine er duplikeret mellem app- og Watch-target, hvilket øger risikoen for drift og bugs ved fremtidige ændringer. Se `WODrounds/WODTimerEngine.swift:10-220` og `WODroundsWatch/WODTimerEngine.swift:10-220`.
4. **Lav** – Sprog er blandet (dansk/engelsk) og ikke lokaliseret konsekvent (fx “Følger iPhone” vs. øvrige engelske tekster). Se `WODroundsWatch/WatchContentView.swift:41-58` og `WODrounds/ContentView.swift:385-403`.

**Anbefalinger**
1. Lad HealthKit-workout afspejle aktiv tid uden pauser. Overvej at spore aktiv varighed og bruge den som `endDate`, eller skift til at gemme et simpelt `HKWorkout`-sample baseret på engine-tider i stedet for en builder, hvis I ikke indsamler metrics.
2. Sæt countdown ud fra aktuelle tidspunkt i HealthKit-autorisationens callback (brug `Date()` i stedet for det gamle `now`), så 10 sekunder altid starter efter dialogen.
3. Flyt `WODTimerEngine` til et delt modul (Swift Package eller fælles fil med target membership), så iOS og watchOS bruger samme kilde.
4. Introducer simpel lokalisering (minimum `en` + `da`) og gør sprogstrenge konsistente i hele UI’et.

**Testdækning og kvalitet**
1. Unit-tests dækker kun et enkelt pause-edge-case. Overvej tests for intervaller, pause/resume-akkumulation, og korrekt round/phase-beregning. Se `WODroundsTests/WODroundsTests.swift:1-33`.
2. UI-tests er skabelon-agtige og validerer ikke funktionalitet. Se `WODroundsUITests/WODroundsUITests.swift:1-38`.

**Åbne spørgsmål**
1. Skal HealthKit-registreringen stoppe under pause, eller er “kalender-tid” bevidst?
2. Skal Watch-appen vise “Done” eller et afslutningsstate, når iPhone er færdig, eller er lokal timer ønsket som default?
