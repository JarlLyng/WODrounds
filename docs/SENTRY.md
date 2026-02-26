# Sentry (iOS)

Crash- og fejlrapportering for WODrounds bruger Sentry og er kun aktiveret på **iOS** (ikke macOS, tvOS eller Watch).

## DSN – hvor sættes den?

Appen læser DSN i denne rækkefølge: **1)** miljøvariablen `SENTRY_DSN` (fx fra Scheme), **2)** Info.plist-nøglen `SentryDSN` (fra `Sentry.xcconfig` ved build).

### A) Miljøvariabel (anbefalet til lokal test)

1. I Xcode: **Product → Scheme → Edit Scheme…** (eller **⌘<**).
2. Vælg **Run** til venstre → fanen **Arguments**.
3. Under **Environment Variables** klik **+** og tilføj:
   - **Name:** `SENTRY_DSN`
   - **Value:** din DSN-URL (fra Sentry → Project Settings → Client Keys (DSN)).
4. Luk og kør appen på iOS (⌘R). DSN bruges nu ved kørsel fra Xcode.

### B) Sentry.xcconfig (til build/arkiv)

1. **Åbn `Sentry.xcconfig`** i projektroden.
2. Sæt `SENTRY_DSN = https://din-key@o0.ingest.sentry.io/dit-projekt-id` (med mellemrum efter `=`).
3. Ved build indsætter Xcode værdien i Info.plist som `SentryDSN`, så arkiv og kørsel uden scheme-env også får DSN.

**Hvis Sentry stadig ikke modtager:** I Debug står der i Xcode-konsollen `[Sentry] No DSN: ...`, hvis ingen DSN blev fundet. Tjek at miljøvariablen er sat under Run, eller at `Sentry.xcconfig` er brugt som base config for WODrounds-targetet.

## Tilføj Sentry-pakken (Swift Package)

Hvis du ikke har tilføjet pakken endnu:

1. I Xcode: **File → Add Package Dependencies…**
2. Angiv URL: `https://github.com/getsentry/sentry-cocoa.git`
3. Vælg version (fx **Up to Next Major** med 9.0.0 eller nyere).
4. Vælg produktet **Sentry** og tilknyt det til targetet **WODrounds**.
5. Klik **Add Package**.

Herefter bygger appen med Sentry, og ved kørsel på iOS med DSN sat i `Sentry.xcconfig` sendes crashes og fejl til dit Sentry-projekt.

## Sentry MCP (valgfri)

[Sentry MCP](https://docs.sentry.io/ai/mcp/) giver Cursor (eller andre AI-værktøjer) adgang til at læse issues og fejl fra Sentry. Det er **uafhængigt** af DSN i appen: DSN bruges kun i iOS-appen til at sende events; MCP bruger OAuth mod Sentry. Konfigurer MCP i Cursor efter [Sentry MCP-dokumentationen](https://docs.sentry.io/ai/mcp/).

## "Upload Symbols Failed" ved archive / TestFlight

Når du uploader et arkiv til App Store Connect, kan Xcode vise: **Upload Symbols Failed – The archive did not include a dSYM for the Sentry.framework**. Det er en **kendt advarsel** ved Sentry via Swift Package Manager (Sentry leveres som forhåndsbygget framework uden dSYM i arkivet). Uploadet er stadig gennemført – dialogen siger "Upload completed **with warnings**". Du kan trykke **Done**; buildet bør ligge på TestFlight. Crashes fra **din app-kode** kan Sentry stadig symbolikere, hvis dit eget app-dSYM uploades (fx via Sentry's eget upload-step eller sentry-cli). Advarslen påvirker ikke at TestFlight-buildet er brugbart.

## Privacy

Opdater din **Privacy Policy** og App Store **Privacy-labels** med, at appen sender crash- og fejldata til Sentry (tredjepart). Se fx [Sentry privacy](https://docs.sentry.io/product/security/).
