# Voice cues

The spoken cues on iPhone, iPad and Apple TV. The Mac and the Watch have no sound.

## How the app finds them

Each cue is an `.mp3` named after the cue, in the language folder it is spoken in:
`WODrounds/en.lproj/halfway.mp3`, `WODrounds/da.lproj/halfway.mp3`, `WODrounds/es.lproj/halfway.mp3`.
`WorkoutSoundManager.cueURL` takes the file for the app's current language and falls back to
English when a language has no recording of that cue. The list of cues is
`WorkoutSoundManager.voiceCues`.

`halfway` and `tenSeconds` fall back to the system voice (`AVSpeechSynthesizer`, en-US) while they
have no file. That voice is a different speaker from the recordings, which is the reason they are
being recorded.

`VoiceCueTests` checks that every English cue played today exists, and that a language folder
holds either every cue or none, so a workout never switches speaker halfway through.

## The lines

One voice for all three languages, so a user who switches language hears the same person. The tone
is the app's: plain, athlete-direct, no hype. These are written for each language, not translated
word for word. Spanish is Mexican Spanish, as the app's `es` localization is es-MX.

| File | English | Danish | Spanish (es-MX) | When it plays |
|---|---|---|---|---|
| `getReadyStart` | Go! | Kør! | ¡Ya! | The 10-second count-in reaches zero |
| `halfway` | Halfway. | Halvvejs. | A la mitad. | Half of a phase left (phases over 40 s) |
| `tenSeconds` | Ten seconds. | Ti sekunder. | Diez segundos. | 10 s left in a phase (phases over 15 s) |
| `tenRoundsLeft` | Ten rounds left. | Ti runder tilbage. | Quedan diez rondas. | 10 rounds to go |
| `fiveRoundsLeft` | Five rounds left. | Fem runder tilbage. | Quedan cinco rondas. | 5 rounds to go |
| `twoRoundsLeft` | Two rounds left. | To runder tilbage. | Quedan dos rondas. | 2 rounds to go |
| `youDidIt` | You did it! | Du klarede det! | ¡Lo lograste! | Workout done (one of three, at random) |
| `youDidIt2` | Done. Nice work. | Færdig. Godt gået. | Listo. Buen trabajo. | Workout done |
| `youDidIt3` | That's it. Well done. | Sådan. Flot klaret. | Eso es. Bien hecho. | Workout done |

## Format

Match the files already in the app: MP3, mono, 44.1 kHz, 128 kbit/s. Trim the silence at both
ends so a cue lands on its moment. Keep `getReadyStart` and `tenSeconds` under a second; the 3-2-1
beeps follow `tenSeconds` closely in a short phase. Even out the loudness across all files, so no
cue jumps out over the music.

## Making them

Generated with ElevenLabs, under the hub's rule in `BRAND_LEGAL.md`: the paid plan's commercial
licence covers a paid app (confirm it is still current before a release), only the finished
`.mp3` files are committed, and the API key, any script and the MCP server stay out of this repo.

When a language's set is complete: add the folder's files, run the tests, add the release note,
and change the audio line in `AGENTS.md`, which today says the cues are English only.
