# App Store text for 1.10, the iPhone Duo release (#199)

Everything the owner pastes into App Store Connect for the release that goes in by **Tuesday
2026-10-20** and is released by hand on **2026-10-23** (#157). Written 2026-10-16.

Each field below is a heading of the form `platform · locale · field` with the text in the block
under it. `check_store_text.py` counts every block against Apple's limits (the keyword field in
bytes, so æ, ø, å and ó count as two):

```bash
python3 appstore/1.10/check_store_text.py
```

What changes from the live 1.9 listing, and why:

- **"CrossFit" is gone** from every keyword field and every description. It is a registered mark,
  and the hub's rule keeps third-party marks out of the name, subtitle, keywords and promotional
  text. The descriptions say "Tabata" in its place, which the app backs.
- **"The only WOD timer you need" is gone** from all promotional text (owner, 2026-10-16). It was
  on all seven live versions.
- **`puls` is gone** from the Danish keywords. The app has no heart-rate feature.
- **`wod` and `tabata` move into the name** (A), so the keyword fields carry other words.
- **The missing localizations** are written out: iPhone es-ES, Mac da and es-MX, Apple TV da and
  es-MX. Until now those storefronts showed the English description and indexed no keywords.
- **The descriptions gain one paragraph** about the new two-column layout on iPhone and iPad.
- **The sound is described as it is:** a voice for get ready, halfway, ten seconds and rounds
  remaining, and a 3-2-1 beep before every change. "Recorded in English" becomes "in English",
  since halfway and ten seconds are the system voice. The Apple TV promotional text no longer says
  the whole room can hear the cues, which the German review contradicts (#200).

Unchanged and not repeated here: the subtitles (en-US `EMOM & Intervals Timer`, da `EMOM og
intervaltimer`, es-ES and es-MX `Temporizador EMOM e intervalos`), support and marketing URLs,
age rating, copyright.

**Before pasting:** the iPhone Duo claims (What's New, the description paragraph, the In-App Event)
hold only once the build is checked in the iPhone Duo simulator in every pose (#157). If that check
finds a problem, those lines change with the fix.

---

## 1. The name: A, chosen by the owner on 2026-10-16

The name is set once per language for the app, so it shows on iPhone, Mac and Apple TV alike. Today
it is `WODrounds`, 9 of 30 characters, and `wod` is in no indexed field. Each proposal keeps the
wordmark first and adds a phrase you could say aloud. None repeats the subtitle's words (EMOM,
intervals, timer), and none uses a trademark.

"WOD Clock" on its own is taken: several apps are called that or something very close (SmartWOD
Timer - WOD Clock, Box Timer - Simple WOD Clock, WOD Clock: Personal Timer, US store, 2026-10-16).
So each proposal gives it a shape of its own.

| | en-US and da | es-ES and es-MX | New indexed words |
|---|---|---|---|
| **A** | `WODrounds: Tabata WOD Clock` (27) | `WODrounds: Reloj WOD y Tabata` (29) | tabata, wod, clock |
| **B** | `WODrounds: Clock for Your WOD` (29) | `WODrounds: Reloj para tu WOD` (28) | wod, clock |
| **C** | `WODrounds: Gym Clock for WODs` (29) | `WODrounds: Reloj de gym WOD` (27) | gym, clock, wods |

**Recommended: A.** It moves the two strongest search terms into the most heavily weighted field:
`tabata` comes out of the keyword field, and `wod` arrives. That frees keyword bytes for words no
field has today. B reads most naturally but adds only `wod`. C relies on Apple matching `wods` to
`wod`, which Apple doesn't document. Danish keeps the English name, because Danes search the
English words (`tabata`, `wod`) and the Danish keywords already carry the Danish ones.

**Chosen: A** (owner, 2026-10-16): `WODrounds: Tabata WOD Clock` on en-US and da, and
`WODrounds: Reloj WOD y Tabata` on es-ES and es-MX. The name under the icon on the home screen
stays `WODrounds`.

---

## 2. Keywords

Comma-separated with no spaces. No word repeats the name or subtitle.

### For name A

#### iOS · en-US · keywords
```text
hiit,for time,countdown,apple watch,stopwatch,gym,workout,functional,fitness,circuit,training,rounds
```

#### iOS · da · keywords
```text
hiit,for time,træning,nedtælling,stopur,fitness,cirkeltræning,styrketræning,apple watch,gym
```

#### iOS · es-MX · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta regresiva,entrenamiento,ejercicio,fuerza,apple watch
```

#### iOS · es-ES · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta atrás,entrenamiento,ejercicio,fuerza,apple watch,box
```

#### macOS · en-US · keywords
```text
hiit,for time,countdown,stopwatch,gym,workout,functional,fitness,training,circuit,rounds,desktop
```

#### macOS · es-ES · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta atrás,entrenamiento,ejercicio,fuerza,escritorio
```

#### macOS · da · keywords
```text
hiit,for time,træning,nedtælling,stopur,fitness,cirkeltræning,styrketræning,gym,mac
```

#### macOS · es-MX · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta regresiva,entrenamiento,ejercicio,fuerza,escritorio
```

#### tvOS · en-US · keywords
```text
hiit,for time,countdown,gym,workout,box,functional,fitness,training,class,tv,big screen,group
```

#### tvOS · es-ES · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta atrás,entrenamiento,ejercicio,clase,grupo,tele
```

#### tvOS · da · keywords
```text
hiit,for time,træning,nedtælling,fitness,cirkeltræning,holdtræning,gym,tv,storskærm
```

#### tvOS · es-MX · keywords
```text
hiit,for time,gimnasio,cronómetro,cuenta regresiva,entrenamiento,ejercicio,clase,grupo,tv
```



---

## 3. Promotional text

The only field that can change without a release. It is wiped by every new version, so paste it
again with 1.10, and **log the date it goes live** in the hub's WODrounds folder.

#### iOS · en-US · promotional text
```text
EMOM, intervals and For Time. Set it up on your Apple Watch and leave the phone in your bag. One purchase for iPhone, iPad, Watch, Mac and Apple TV.
```

#### iOS · da · promotional text
```text
EMOM, intervaller og For Time. Sæt den op på dit Apple Watch, og lad telefonen blive i tasken. Ét køb til iPhone, iPad, Watch, Mac og Apple TV.
```

#### iOS · es-MX · promotional text
```text
EMOM, intervalos y For Time. Configúralo en tu Apple Watch y deja el teléfono en la mochila. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

#### iOS · es-ES · promotional text
```text
EMOM, intervalos y For Time. Configúralo en tu Apple Watch y deja el móvil en la mochila. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

#### macOS · en-US · promotional text
```text
EMOM, intervals and For Time in a compact window with numbers you can read from the mat. One purchase for iPhone, iPad, Watch, Mac and Apple TV.
```

#### macOS · es-ES · promotional text
```text
EMOM, intervalos y For Time en una ventana compacta con números que se leen desde la esterilla. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

#### macOS · da · promotional text
```text
EMOM, intervaller og For Time i et lille vindue med tal, du kan læse fra måtten. Ét køb til iPhone, iPad, Watch, Mac og Apple TV.
```

#### macOS · es-MX · promotional text
```text
EMOM, intervalos y For Time en una ventana compacta con números que se leen desde el tapete. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

#### tvOS · en-US · promotional text
```text
EMOM, intervals and For Time on the big screen, with voice cues and a 3-2-1 beep. One purchase for iPhone, iPad, Watch, Mac and Apple TV.
```

#### tvOS · es-ES · promotional text
```text
EMOM, intervalos y For Time en la pantalla grande, con avisos de voz y un pitido 3-2-1. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

#### tvOS · da · promotional text
```text
EMOM, intervaller og For Time på den store skærm, med stemmecues og et 3-2-1-bip. Ét køb til iPhone, iPad, Watch, Mac og Apple TV.
```

#### tvOS · es-MX · promotional text
```text
EMOM, intervalos y For Time en la pantalla grande, con avisos de voz y un pitido 3-2-1. Una compra para iPhone, iPad, Watch, Mac y Apple TV.
```

---

## 4. Descriptions

Version-locked, so they ship with 1.10. The iPhone texts change in the first line (Tabata for
CrossFit) and gain the paragraph on the two-column layout. The rest is the live 1.9 text.

#### iOS · en-US · description
```text
Interval timer for EMOM, For Time, Tabata and HIIT. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

Start on your iPhone and the watch shows the same time and the same round. You can also set up an EMOM or an interval session on the watch itself and leave the phone in your bag.

On iPhone Duo's inner display, on an iPad on its side and on an iPhone in landscape, the timer takes two columns, with the digits on one side, as large as the column allows, and the buttons on the other.

A voice calls get ready, halfway, ten seconds and rounds remaining at ten, five and two, and a 3-2-1 beep comes before every change. The numbers are big enough to read at a distance, everything works one-handed, and the timer keeps running when the screen goes dark.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

#### iOS · da · description
```text
Intervaltimer til EMOM, For Time, Tabata og HIIT. Ingen konto og ingen oprettelse. Bare tid, runder og ro til at træne.

EMOM kører 1 til 120 runder med en rundelængde mellem 0:30 og 9:30. Intervaller er arbejde, hvile og runder som du selv sætter, så Tabata er bare 20/10 gange 8. For Time tæller op fra nul, du trykker Stop når du er færdig, og du kan sætte en tidsgrænse hvis du vil have en.

Start på din iPhone, og uret viser samme tid og samme runde. Du kan også sætte en EMOM eller et intervalpas op direkte på uret og lade telefonen blive i tasken.

På iPhone Duos indre skærm, på en iPad i liggende format og på en iPhone i liggende format deler timeren sig i to kolonner, med tallene i den ene, så store som kolonnen tillader, og knapperne i den anden.

Undervejs siger en stemme gør dig klar, halvvejs, ti sekunder og runder tilbage ved ti, fem og to, og et 3-2-1-bip kommer før hvert skift. Stemmen er på engelsk. Tallene er store nok til at læse på afstand, alt kan betjenes med én hånd, og timeren kører videre når skærmen slukker.

Ét køb dækker iPhone, iPad, Apple Watch, Mac og Apple TV. Intet abonnement, ingen reklamer og intet at købe inde i appen.

En timer til træning. Ingen logbog, ingen deling og ingen konto.
```

#### iOS · es-MX · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM corre de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, presionas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

Empieza en tu iPhone y el reloj muestra el mismo tiempo y la misma ronda. También puedes configurar un EMOM o una sesión de intervalos en el reloj y dejar el teléfono en la mochila.

En la pantalla interior del iPhone Duo, en un iPad en horizontal y en un iPhone en horizontal, el temporizador se divide en dos columnas, con los números en una, tan grandes como la columna lo permite, y los botones en la otra.

Una voz anuncia prepárate, a la mitad, diez segundos y las rondas restantes en diez, cinco y dos, y un pitido 3-2-1 suena antes de cada cambio. La voz está en inglés. Los números se leen a distancia, todo funciona con una mano, y el temporizador sigue corriendo con la pantalla apagada.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin bitácora, sin compartir y sin cuenta.
```

#### iOS · es-ES · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM va de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, pulsas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

Empieza en tu iPhone y el reloj muestra el mismo tiempo y la misma ronda. También puedes configurar un EMOM o una sesión de intervalos en el reloj y dejar el móvil en la mochila.

En la pantalla interior del iPhone Duo, en un iPad en horizontal y en un iPhone en horizontal, el temporizador se divide en dos columnas, con los números en una, tan grandes como la columna lo permite, y los botones en la otra.

Una voz anuncia prepárate, a la mitad, diez segundos y las rondas restantes en diez, cinco y dos, y un pitido 3-2-1 suena antes de cada cambio. La voz está en inglés. Los números se leen a distancia, todo funciona con una mano, y el temporizador sigue contando con la pantalla apagada. La app está en español de México.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin historial, sin compartir y sin cuenta.
```

#### macOS · en-US · description
```text
Interval timer for EMOM, For Time, Tabata and HIIT, on your Mac. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

The window stays compact and the numbers stay large, so you can put it in a corner of the screen and still read it from the mat. It keeps time when the window is behind something else, and it follows your light or dark appearance. The Mac has no sound cues.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

#### macOS · es-ES · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT, en tu Mac. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM va de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, pulsas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

La ventana se mantiene compacta y los números grandes, así que puedes dejarla en una esquina de la pantalla y leerla desde la esterilla. Sigue contando aunque la ventana quede detrás de otra, y respeta el aspecto claro u oscuro del sistema. En el Mac no hay señales de sonido.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin historial, sin compartir y sin cuenta.
```

#### macOS · da · description
```text
Intervaltimer til EMOM, For Time, Tabata og HIIT, på din Mac. Ingen konto og ingen oprettelse. Bare tid, runder og ro til at træne.

EMOM kører 1 til 120 runder med en rundelængde mellem 0:30 og 9:30. Intervaller er arbejde, hvile og runder som du selv sætter, så Tabata er bare 20/10 gange 8. For Time tæller op fra nul, du trykker Stop når du er færdig, og du kan sætte en tidsgrænse hvis du vil have en.

Vinduet er lille og tallene store, så du kan lægge det i et hjørne af skærmen og stadig læse det fra måtten. Det holder tiden, når vinduet ligger bag noget andet, og det følger dit lyse eller mørke udseende. Mac'en har ingen lydcues.

Ét køb dækker iPhone, iPad, Apple Watch, Mac og Apple TV. Intet abonnement, ingen reklamer og intet at købe inde i appen.

En timer til træning. Ingen logbog, ingen deling og ingen konto.
```

#### macOS · es-MX · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT, en tu Mac. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM corre de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, presionas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

La ventana se mantiene compacta y los números grandes, así que puedes dejarla en una esquina de la pantalla y leerla desde el tapete. Sigue contando aunque la ventana quede detrás de otra, y respeta el aspecto claro u oscuro del sistema. En la Mac no hay señales de sonido.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin bitácora, sin compartir y sin cuenta.
```

#### tvOS · en-US · description
```text
Interval timer for EMOM, For Time, Tabata and HIIT, on the TV everyone in the room can see. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

The numbers fill the screen, so nobody has to walk over and check the clock. A voice calls get ready, halfway, ten seconds and rounds remaining at ten, five and two, and a 3-2-1 beep comes before every change. You can mute the sound from the remote. The screensaver stays out of the way for as long as the workout is running.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

#### tvOS · es-ES · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT, en la tele que ve toda la sala. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM va de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, pulsas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

Los números llenan la pantalla, así que nadie tiene que acercarse a mirar el reloj. Una voz anuncia prepárate, a la mitad, diez segundos y las rondas restantes en diez, cinco y dos, y un pitido 3-2-1 suena antes de cada cambio. La voz está en inglés, y puedes silenciar el sonido desde el mando. El salvapantallas no aparece mientras el entrenamiento está en marcha.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin historial, sin compartir y sin cuenta.
```

#### tvOS · da · description
```text
Intervaltimer til EMOM, For Time, Tabata og HIIT, på det tv hele rummet kan se. Ingen konto og ingen oprettelse. Bare tid, runder og ro til at træne.

EMOM kører 1 til 120 runder med en rundelængde mellem 0:30 og 9:30. Intervaller er arbejde, hvile og runder som du selv sætter, så Tabata er bare 20/10 gange 8. For Time tæller op fra nul, du trykker Stop når du er færdig, og du kan sætte en tidsgrænse hvis du vil have en.

Tallene fylder skærmen, så ingen behøver at gå hen og kigge på uret. En stemme siger gør dig klar, halvvejs, ti sekunder og runder tilbage ved ti, fem og to, og et 3-2-1-bip kommer før hvert skift. Stemmen er på engelsk, og du kan slå lyden fra med fjernbetjeningen. Pauseskærmen holder sig væk, så længe træningen kører.

Ét køb dækker iPhone, iPad, Apple Watch, Mac og Apple TV. Intet abonnement, ingen reklamer og intet at købe inde i appen.

En timer til træning. Ingen logbog, ingen deling og ingen konto.
```

#### tvOS · es-MX · description
```text
Temporizador de intervalos para EMOM, For Time, Tabata y HIIT, en la tele que ve todo el salón. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM corre de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, presionas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

Los números llenan la pantalla, así que nadie tiene que acercarse a ver el reloj. Una voz anuncia prepárate, a la mitad, diez segundos y las rondas restantes en diez, cinco y dos, y un pitido 3-2-1 suena antes de cada cambio. La voz está en inglés, y puedes silenciar el sonido desde el control remoto. El protector de pantalla no aparece mientras el entrenamiento está en marcha.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin bitácora, sin compartir y sin cuenta.
```

---

## 5. What's New in 1.10

From `CHANGELOG.md`, Unreleased. The Mac and Apple TV versions go in alongside the iPhone only if
their builds are ready, and they must not hold it (#199).

#### iOS · en-US · what's new
```text
WODrounds now fits iPhone Duo. On the inner display the timer takes two columns, with the digits on one side, as large as the column allows, and the buttons on the other. An iPad on its side gets the same layout, and so does the iPhone in landscape, which is new.

On Apple Watch, setting up a workout fits on one screen with no scrolling, down to the 40 mm watch.

New: Send feedback, in About. It opens an email with the app and system version filled in, and you see all of it before you send.

WODrounds now needs iOS 17 and watchOS 10 or later.
```

#### iOS · da · what's new
```text
WODrounds passer nu til iPhone Duo. På den indre skærm deler timeren sig i to kolonner, med tallene i den ene, så store som kolonnen tillader, og knapperne i den anden. En iPad i liggende format får samme layout, og det gør iPhone i liggende format også, hvilket er nyt.

På Apple Watch passer opsætningen af et pas nu på én skærm uden at scrolle, helt ned til uret på 40 mm.

Nyt: Send feedback, under Om. Det åbner en mail med app- og systemversion udfyldt, og du ser det hele, før du sender.

WODrounds kræver nu iOS 17 og watchOS 10 eller nyere.
```

#### iOS · es-MX · what's new
```text
WODrounds ahora se adapta al iPhone Duo. En la pantalla interior el temporizador se divide en dos columnas, con los números en una, tan grandes como la columna lo permite, y los botones en la otra. Un iPad en horizontal tiene el mismo diseño, y también el iPhone en horizontal, que es nuevo.

En el Apple Watch, configurar un entrenamiento cabe en una sola pantalla, sin desplazarte, hasta en el reloj de 40 mm.

Nuevo: Enviar comentarios, en Acerca de. Abre un correo con la versión de la app y del sistema ya escritas, y ves todo antes de enviarlo.

WODrounds ahora requiere iOS 17 y watchOS 10 o posterior.
```

#### iOS · es-ES · what's new
```text
WODrounds ahora se adapta al iPhone Duo. En la pantalla interior el temporizador se divide en dos columnas, con los números en una, tan grandes como la columna lo permite, y los botones en la otra. Un iPad en horizontal tiene el mismo diseño, y también el iPhone en horizontal, que es nuevo.

En el Apple Watch, configurar un entrenamiento cabe en una sola pantalla, sin desplazarte, hasta en el reloj de 40 mm.

Nuevo: Enviar comentarios, en Acerca de. Abre un correo con la versión de la app y del sistema ya escritas, y ves todo antes de enviarlo.

WODrounds ahora necesita iOS 17 y watchOS 10 o posterior.
```

#### macOS · en-US · what's new
```text
New: Send feedback, in About and in the Help menu. It opens an email with the app and macOS version filled in, and you see all of it before you send.
```

#### macOS · es-ES · what's new
```text
Nuevo: Enviar comentarios, en Acerca de y en el menú Ayuda. Abre un correo con la versión de la app y de macOS ya escritas, y ves todo antes de enviarlo.
```

#### macOS · da · what's new
```text
Nyt: Send feedback, under Om og i menuen Hjælp. Det åbner en mail med app- og macOS-version udfyldt, og du ser det hele, før du sender.
```

#### macOS · es-MX · what's new
```text
Nuevo: Enviar comentarios, en Acerca de y en el menú Ayuda. Abre un correo con la versión de la app y de macOS ya escritas, y ves todo antes de enviarlo.
```

#### tvOS · en-US · what's new
```text
Built with Apple's newest tools. Nothing changes on screen.
```

#### tvOS · es-ES · what's new
```text
Compilada con las herramientas más recientes de Apple. Nada cambia en pantalla.
```

#### tvOS · da · what's new
```text
Bygget med Apples nyeste værktøjer. Intet ændrer sig på skærmen.
```

#### tvOS · es-MX · what's new
```text
Compilada con las herramientas más recientes de Apple. Nada cambia en pantalla.
```

The Danish and Spanish names of About and Send feedback match the app's own strings ("Om" and
"Send feedback"; "Acerca de" and "Enviar comentarios"). The Help menu is the system's own.

---

## 6. The Apple TV privacy policy text (#187)

App Privacy › Apple TV Privacy Policy. It changes only with a new version, so it goes in with the
Apple TV 1.10 version. If the Apple TV version doesn't go in with this release, it waits for the
next one. Set the date on the day.

#### tvOS · en-US · privacy policy
```text
Privacy Policy for WODrounds
Last updated: <release date>

WODrounds is an interval timer for EMOM, Intervals and For Time. It has no account and no ads, and it works offline.

Your workouts and settings stay on your device. The app does not send them to us or to anyone else.

On Apple TV the app collects nothing. It has no crash reporting, no analytics and no tracking, and it does not sync with your other devices.

On iPhone and iPad the app sends crash reports and performance diagnostics to Sentry, so bugs can be fixed. They hold the device type, the OS version and the app's state at the time of the crash, never your workouts or who you are. If you allow it, a finished workout is saved to Apple Health as HIIT. That stays in Health on your device and is not sent to us.

The full policy: https://wodrounds.iamjarl.com/privacy.html
Questions: support@iamjarl.com
```

---

## 7. In-App Event: WODrounds on iPhone Duo

Badge **Major Update**, submitted with the build, published on 2026-10-23 and running to
2026-11-22 (31 days at most). Purpose: keep users informed and reach new ones. No deep link: the
event opens the app's front page. **If App Review finds that support for a new iPhone doesn't
meet the event criteria, drop the event.** The release doesn't wait for it.

The event card (1920 × 1080) and details image (1080 × 1920) follow the dark poster standard in the
hub's `DESIGN.md`, made from the iPhone Duo capture once the simulator is installed. Until then
the event has text only.

#### event · en-US · name
```text
WODrounds on iPhone Duo
```

#### event · en-US · short description
```text
Two columns on the inner display, digits first.
```

#### event · en-US · long description
```text
Open iPhone Duo and the timer splits in two, with the digits as large as their column allows and the buttons beside.
```

#### event · da · name
```text
WODrounds på iPhone Duo
```

#### event · da · short description
```text
To kolonner på den indre skærm, tallene først.
```

#### event · da · long description
```text
Fold iPhone Duo ud, og timeren deler sig i to, med tallene så store som kolonnen tillader og knapperne ved siden af.
```

#### event · es-MX · name
```text
WODrounds en el iPhone Duo
```

#### event · es-MX · short description
```text
Dos columnas en la pantalla interior.
```

#### event · es-MX · long description
```text
Abre el iPhone Duo y el temporizador se parte en dos, con los números tan grandes como su columna y los botones al lado.
```

#### event · es-ES · name
```text
WODrounds en el iPhone Duo
```

#### event · es-ES · short description
```text
Dos columnas en la pantalla interior.
```

#### event · es-ES · long description
```text
Abre el iPhone Duo y el temporizador se parte en dos, con los números tan grandes como su columna y los botones al lado.
```

---

## 8. Two review replies, for the owner to post

Each says only what has shipped, with the version it shipped in. Both reviews are in English, so
the replies are too.

**Canada, 3★, 2026-08-26, "Nice first try…".** Post on or after 2026-10-23, once 1.10 is live.
Posted earlier, drop the landscape sentence.

#### reply · en-US · CAN 2026-08-26
```text
Thank you for the list. Two of your points have shipped since. From 1.8, Intervals counts down the work or rest period you are in, with the whole workout as a smaller line below it. From 1.10, the iPhone runs in landscape, with the digits in one column and the buttons in the other. The 10-second count-in can be cancelled (since 1.4), but its length is still fixed, and the steppers still move in steps. Jarl
```

**Germany, 4★, 2026-09-28, "Perfect for Solo, missing functions for group".** Both signals the
review asks for exist, but on a speaker the 3-2-1 is easy to miss: it is a short system sound
(`AudioServicesPlaySystemSound(1057)`), quiet next to music. The reply says so rather than telling
the reviewer the feature is there. The beep itself is #200, for a later release.

#### reply · en-US · DEU 2026-09-28
```text
Thank you, and good to hear it works for your group sessions. Both signals are there, but easy to miss on a speaker: a 10-second count-in before the first round, and a 3-2-1 beep before every change, work to rest and rest to work, since 1.3. The beep is a short system sound, so it gets lost next to music. That is the part of your review I'm looking at. Jarl
```
