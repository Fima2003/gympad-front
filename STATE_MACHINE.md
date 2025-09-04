# Workout Run State Machine

This document describes the new run-phase state machine that powers the workout flow.

## Overview

The legacy flow relied on a single `WorkoutInProgress` state plus ad‑hoc navigation for rest screens. The refactor introduces explicit *run phase* states so the UI can render declaratively and a single periodic timer can drive set/rest timing.

```
┌────────────────┐   RunEnterSet        ┌────────────────┐  RunFinishCurrent(set)  ┌────────────────┐
│                │ ───────────────▶     │                │ ───────────────────────▶ │                │
│ WorkoutRunRest │                      │ WorkoutRunInSet│                         │ WorkoutRunRest │
│                │ ◀───────────────     │                │ ◀─────────────────────── │                │
└────────────────┘    auto when rest=0  └────────────────┘   auto (RunEnterRest)    └────────────────┘
           ▲                                 │   │                                   │
           │ RunFinishEarly                  │   │ RunFinishCurrent(workout)         │ RunFinishEarly
           │                                 │   │ (emits WorkoutCompleted)          │
           │                                 ▼   ▼                                   │
           │                           ┌────────────────┐                             │
           │                           │WorkoutRunFinis.│  (terminal -> WorkoutCompleted)
           │                           └────────────────┘
```

## States

| State | Purpose |
|-------|---------|
| `WorkoutRunInSet` | User is performing a set. A 1s ticker updates `elapsed`. `finishType` tells UI whether finishing records a set, completes the exercise, or the whole workout. |
| `WorkoutRunRest` | User is resting after a set or exercise. Countdown (`remaining` / `total`) driven by same shared timer. Allows reorder of *future* planned exercises (excludes active). |
| `WorkoutRunFinishing` | Transitional state while persisting workout completion (normal or early). |
| `WorkoutCompleted` | Terminal success state (existing). |

Legacy states retained (e.g. `WorkoutInProgress`) so free / not-yet-migrated flows continue to function, but the UI should preferentially react to run-phase states when present.

## Events (Run Phase)

| Event | Triggers |
|-------|----------|
| `RunEnterSet` | Enter / re-enter a set phase (initial start or after rest). Starts set ticker. |
| `RunSetTick` | Internal every-second tick while in a set. Updates `elapsed`. |
| `RunFinishCurrent` | User tapped finish in set phase. Behavior depends on `finishType`: add set, finish exercise, or finish workout. Emits rest (or finishing). |
| `RunEnterRest(Duration)` | Move to rest phase with provided duration. Starts rest ticker. |
| `RunRestTick` | Internal tick; decrements remaining rest, auto transitions to `RunEnterSet` at zero. |
| `RunSkipRest` | User skips remaining rest -> immediately `RunEnterSet`. |
| `RunExtendRest` | Adds seconds to remaining + total rest. |
| `RunFinishEarly` | Only allowed in rest phase. Cancels timers, transitions to `WorkoutRunFinishing` then `WorkoutCompleted`. |
| `UpcomingExercisesReordered` | Reorders future planned exercises during rest (excludes locked active one). |

## Finish Type Logic

`RunFinishType` (attached to `WorkoutRunInSet`):

* `set` – Finishing records a set and enters rest before next set of same exercise.
* `exercise` – Finishing records the final set of the exercise and enters rest before next exercise.
* `workout` – Finishing records final set of final exercise; transitions to finishing/completed.

## Timers

Only one periodic `Timer` (`_phaseTimer`) exists. It is restarted on each phase change (set/rest). This prevents drift and widget-level timer duplication.

## Reorder Semantics

During `WorkoutRunRest` users may reorder *upcoming* exercises. The active (current or just-finished) exercise is excluded from the reorderable slice (`reorderStartIndex`) to avoid inconsistencies with in-progress sets.

## Free Workout Compatibility

Free workouts (no plan) synthesize a transient `CustomWorkoutExercise` during set/rest phases so the UI can remain uniform. Migration path: emit run-phase states for free flow and eventually remove legacy `SetAdded` / `WorkoutFinished` events.

## Error Handling

Any persistence failure in a phase emits `WorkoutError` (non-terminal). The UI should allow user to retry (e.g. re-tap finish) after transient errors; timers stop only when moving to finishing or completion.

## Future Enhancements

* Inject timer (ticker) for deterministic tests.
* Persist elapsed rest across app suspends.
* Migrate free workout fully then remove legacy path & feature flag.
* Add guard rails for accidental double taps (debounce finish button while persisting).
