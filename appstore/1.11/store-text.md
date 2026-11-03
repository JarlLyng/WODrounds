# App Store text for 1.11, the deep-link release (#208)

Everything that changes in App Store Connect for 1.11. Written 2026-11-03. The release adds one
thing: links that open the app (`wodrounds://`, plus one per mode). App Store Connect needs such a
link before the iPhone Duo In-App Event can go in for review, which it couldn't with 1.10.

Each field below is a heading of the form `platform · locale · field` with the text in the block
under it, counted against Apple's limits by 1.10's checker:

```bash
python3 appstore/1.10/check_store_text.py appstore/1.11/store-text.md
```

**Unchanged from 1.10, and not repeated here:** the names, subtitles, keywords, descriptions,
screenshots, the header and the Apple TV privacy text. All of them are in
[`appstore/1.10/store-text.md`](../1.10/store-text.md) and carry over to the new version.

**Promotional text is wiped by every new version.** Paste it again unchanged from 1.10's §3 on
every platform and language, and log the date in the hub's WODrounds folder.

**Mac and Apple TV:** the link works there too, but nothing else changes. Their versions can go in
with the iPhone or be skipped. They must not hold the iPhone version.

---

## 1. What's New in 1.11

From `CHANGELOG.md`, 1.11. The Danish and Spanish name the Start button as the app does ("Start",
"Iniciar"). Spain says "pulses" and Mexico "toques", as in the 1.10 descriptions.

#### iOS · en-US · what's new
```text
WODrounds can now be opened from a link. wodrounds://emom, wodrounds://intervals and wodrounds://fortime open that mode's setup, ready for you to press Start.

A link never starts a timer. During a workout it only brings the app forward.
```

#### iOS · da · what's new
```text
WODrounds kan nu åbnes fra et link. wodrounds://emom, wodrounds://intervals og wodrounds://fortime åbner opsætningen til den mode, klar til at du trykker Start.

Et link starter aldrig en timer. Under et pas henter det bare appen frem.
```

#### iOS · es-MX · what's new
```text
Ahora WODrounds se puede abrir desde un enlace. wodrounds://emom, wodrounds://intervals y wodrounds://fortime abren la configuración de ese modo, lista para que toques Iniciar.

Un enlace nunca inicia un temporizador. Durante un entrenamiento solo trae la app al frente.
```

#### iOS · es-ES · what's new
```text
Ahora WODrounds se puede abrir desde un enlace. wodrounds://emom, wodrounds://intervals y wodrounds://fortime abren la configuración de ese modo, lista para que pulses Iniciar.

Un enlace nunca inicia un temporizador. Durante un entrenamiento solo trae la app al frente.
```

#### macOS · en-US · what's new
```text
WODrounds can now be opened from a link. wodrounds://emom, wodrounds://intervals and wodrounds://fortime open that mode's setup. A link never starts a timer.
```

#### macOS · es-ES · what's new
```text
Ahora WODrounds se puede abrir desde un enlace. wodrounds://emom, wodrounds://intervals y wodrounds://fortime abren la configuración de ese modo. Un enlace nunca inicia un temporizador.
```

#### macOS · da · what's new
```text
WODrounds kan nu åbnes fra et link. wodrounds://emom, wodrounds://intervals og wodrounds://fortime åbner opsætningen til den mode. Et link starter aldrig en timer.
```

#### macOS · es-MX · what's new
```text
Ahora WODrounds se puede abrir desde un enlace. wodrounds://emom, wodrounds://intervals y wodrounds://fortime abren la configuración de ese modo. Un enlace nunca inicia un temporizador.
```

#### tvOS · en-US · what's new
```text
WODrounds can now be opened from a link, such as one from an App Store event. Nothing changes on screen.
```

#### tvOS · es-ES · what's new
```text
Ahora WODrounds se puede abrir desde un enlace, como el de un evento del App Store. Nada cambia en pantalla.
```

#### tvOS · da · what's new
```text
WODrounds kan nu åbnes fra et link, fx fra en begivenhed i App Store. Intet ændrer sig på skærmen.
```

#### tvOS · es-MX · what's new
```text
Ahora WODrounds se puede abrir desde un enlace, como el de un evento del App Store. Nada cambia en pantalla.
```

---

## 2. The In-App Event: WODrounds on iPhone Duo, now with its link

The event from 1.10's §7 is still a draft in App Store Connect, with its four localizations and
the images in `appstore/1.10/event/`. Its texts don't change. What changes:

- **Event deep link:** `wodrounds://open`. It opens the app where the user left it. App Store
  Connect turns down a bare `wodrounds://` as not a valid URL, and the app ignores a host it doesn't
  know, so `open` behaves exactly like the bare link. A mode link would pick a mode for them, and
  the event is about the layout, not a mode.
- **Submit it with 1.11.** The link only works once 1.11 is live, so the event goes in with the
  build, not before.
- **New dates.** The 1.10 window (2026-10-23 to 2026-11-22) has mostly passed. Pick a start on or
  after 1.11's release, and an end at most 31 days later.
- **The badge was Major Update,** chosen for 1.10. iPhone Duo support shipped in 1.10, so App
  Review may not count a 1.11 event as a major update. The owner picks the badge. If App Review
  turns the event down, drop it, as 1.10's §7 said. The release doesn't wait for it.
