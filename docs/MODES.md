# Modes

What each timer mode does, with its ranges. The engine behind all three is
`Shared/WODTimerEngine.swift`; the architecture is in the [README](../README.md#architecture).

## EMOM

- Set the number of rounds (1–120) and a **custom round length** (0:30–9:30, 30s steps).
- Total time = rounds × round length (e.g. 10 rounds at 1:30 is 15:00).
- Round counter and a per-round countdown. Start / Pause / Resume / Reset, and Cancel while running or paused.

## Intervals

- Work (seconds), rest (seconds) and rounds, each with +/− and its label above the value.
- Total time = `rounds × work + (rounds − 1) × rest` (no rest after the last work).
- The big readout counts down the **current phase** (since 1.8), with the whole-workout countdown as a line below the round counter. Work / Rest sits above the readout.
- A ring around the readout drains over each work or rest phase and refills at every change. Only Intervals has the ring.
- Start / Pause / Resume / Reset / Cancel, as in EMOM.

## Tabata

Tabata (e.g. 20/10 × 8) is a manual Intervals preset, not a separate mode.

## For Time

- Counts **up** from zero, for the classic "complete the work as fast as you can" WOD.
- Optional **time cap** (0:30–60:00, 30s steps; one stepper where 0 reads "No cap"). Uncapped runs until you press **Stop**; capped finishes on its own at the cap.
- Stop freezes your final time, and the Done screen shows "Finished in MM:SS". No rounds and no in-round audio cues. Saves to Apple Health like the other modes.
- The Apple Watch follows a synced For Time workout (count-up on the wrist). There is no local For Time mode on the Watch.

## Apple Watch on its own (since 1.6)

- The Watch configures and runs **EMOM and Intervals on its own**: a mode switch, plus steppers for rounds and round length (EMOM) or work, rest and rounds (Intervals), with the same ranges as on iPhone. Its settings persist between workouts.
- When a workout is started on iPhone, the Watch follows the synced state instead and shows no controls of its own. Since 1.9 it labels Intervals WORK or REST.

## In-app flow

Choose EMOM, Intervals or For Time, set rounds (Intervals: work and rest; For Time: an optional cap), then Start. The timer runs; Pause and Resume (EMOM and Intervals), Stop (For Time) or Cancel. On completion the Done screen appears, and Reset returns to setup.

Since 1.9 the iPhone, iPad, Mac and Apple TV reopen in the last mode used, with its values.
