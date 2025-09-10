# GymPad AGENTS.md

Purpose: Operational instructions for coding agents working on the GymPad Flutter project. Humans can ignore; this complements README content.

---

## 1. Project Overview

GymPad is a Flutter (Dart) mobile + web app for:
- Tracking the Workout progress
- Tracking Nutrition
- Personalized assistance
- Social aspect between gymmers
---

## 2. Runtime / Toolchain

- Flutter stable (assume latest stable; validate with `flutter --version`).
- Dart formatting via `dart format .` (run before commits).
- State management: flutter_bloc (WorkoutBloc + others).
- Storage: SharedPreferences for lightweight local caches (auth, personal workouts).
- Firebase Auth + backend API services (user + workout endpoints).
- Platform targets: iOS, Android, Web (some sound features are mobile-only currently).

---

## 3. Build & Run Commands

- Get deps: `flutter pub get`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Run (debug): `flutter run`
- Run (web): `./run-web.sh`
- Test (if tests present later): `flutter test`

Always ensure `flutter analyze` passes before finishing a task.

---

## 4. Logging

Use `AppLogger` (do not use raw print unless debugging something transient). Truncate large objects manually (serialize thoughtfully).

---

## 5. Architecture & Layering

Layers (top → bottom):
1. UI Screens & Widgets (in `lib/screens`, `lib/widgets`)
- Any new screen or widget should be split into view and manager. view should be stateless and accept only the values to render
2. BLoC / Events / States (`lib/blocs`)
3. Services (API, auth, audio, local storage) (`lib/services`)
4. DTOs for sending objects via the network (`lib/services/api/models`)
5. Models for the internal use in the application (`lib/models`)
6. Utilities (timers, formatting)

Rules:
- Screens never call API services directly—dispatch BLoC events or call a domain service exposed via BLoC.
- Local persistence (SharedPreferences) only from services; never from widgets.
- Keep business transformations (mapping performed sets to DTOs) in the screen or a helper, not in widgets.

---

## 6. State Management (WorkoutBloc)

Primary responsibilities:
- Sync personal workouts (event: `PersonalWorkoutsSyncRequested`)
- Manage workout session lifecycle (exercise start/end, workout completion)
- Emit domain states (`WorkoutInProgress`, `WorkoutCompleted`, `PersonalWorkoutsLoaded`, etc.)

When adding new workout-related features:
1. Define a new Event in `workout_events.dart`
2. Define corresponding States if needed
3. Implement handler in `workout_bloc.dart`
4. Ensure UI listens (BlocBuilder/BlocListener) and acts minimally (navigation, minor UI updates)

Do not mutate lists in-place; emit cloned lists to force rebuild.

---

## 7. Navigation Conventions

- Use explicit Navigator pushes with strongly typed arguments.
- For flows reused between custom and personal workouts: convert models early (e.g., personal workout → custom workout structure) so downstream screens stay generic.
- Break screen & run screen share UI components—import shared widgets (e.g., `exercise_chip.dart`).

---

## 8. Audio Abstraction

`AudioService` exposes:
- `playTick()`
- `playStart()`

Currently uses `SystemSound` (no-op on Web). If migrating to `just_audio`, only change internals. Never call platform channels from UI directly.

---

## 9. Weight Selector (Velocity-Based)

Widget: `WeightSelectorVelocity`
- Horizontal scroll with custom physics for acceleration (0.5 increments).
- If modifying:
  - Keep public API: `initialWeight`, `onWeightChanged`
  - Tuning params inside widget: baseline velocity (v0), max multiplier
- Avoid adding synchronous heavy computations in scroll callbacks.

---

## 10. Theming & Styling

Central references:
- `AppColors`
- `AppTextStyles`

Guidelines:
- Use semi-transparent surfaces (e.g., `Colors.white.withValues(alpha: 0.06)`) for cards over dark backgrounds.
- Accent color limited to primary CTAs and current exercise highlight.
- Avoid hard-coded text styles; use `AppTextStyles` or copyWith.

---

## 11. Validation Patterns

Use RegExp centrally inside form widget. If reusing across multiple forms, extract to `validators.dart`.
Return user-friendly, concise messages (“6–100 letters & spaces”).
Never block Save by throwing; rely on form state validation.

---

## 12. API Services

Location: `lib/services/api`
Patterns:
- Each endpoint method returns a wrapper with `success`, `status`, `data`, `message`.
- After adding a new endpoint:
  1. Create DTOs in `models/`
  2. Add method to service
  3. Integrate in BLoC, not directly in UI

Authentication:
- `AuthService` maintains id token in SharedPreferences; if unauthorized, attempt refresh (already implemented in `fetchUserOnAppStartWithRetry` pattern).

---

## 13. Local Storage

When adding new caches:
- Create `*_local_service.dart`
- JSON encode to strings
- Provide `saveAll`, `loadAll`, `clear`

No async file ops directly in widgets.

---

## 14. Testing Strategy

We currently have minimal tests. New code should follow these testing layers (use `flutter test`).

### 14.1 Test Pyramid
1. Model & Utility Unit Tests (fast) – pure Dart: JSON (de)serialization, value objects, validators.
2. BLoC Tests – event → state transitions with mocked services.
3. Widget (Golden) Tests – critical widgets (ExerciseChip, WeightSelector) for visual & interaction integrity.
4. Integration / Flow Tests – high‑value user flows (start workout → add exercise → add set → finish → save).

### 14.2 Conventions
- File naming: `<unit>_test.dart` matching source structure under `test/`.
- Group tests with `group('Description', () { ... });` and prefer descriptive `test()` names: `test('emits WorkoutInProgress after WorkoutStarted', ...)`.
- Use `setUp` / `tearDown` for shared fixtures.

### 14.3 BLoC Testing Pattern
Use `bloc_test` package (add to `dev_dependencies`). Example skeleton:
```dart
blocTest<WorkoutBloc, WorkoutState>(
  'emits WorkoutInProgress on WorkoutStarted',
  build: () => WorkoutBloc()..add(WorkoutLoaded()),
  act: (bloc) => bloc.add(WorkoutStarted(WorkoutType.free, name: 'Test')),
  expect: () => [isA<WorkoutInProgress>()],
);
```
Mock external services (API / local storage) via `mocktail`:
```dart
class MockWorkoutApiService extends Mock implements WorkoutApiService {}
```

### 14.4 Widget Testing
Use `pumpWidget` with minimal `MaterialApp`/`BlocProvider` shell. Prefer keys for querying dynamic elements.
Golden tests (optional): capture critical UI states (light & dark backgrounds). Store goldens under `test/goldens/`.

### 14.5 Integration / Flow
Use `integration_test` for end‑to‑end flows (later). Scenarios:
1. Free workout flow: start → add set → break → finish → well done.
2. Save workout flow: perform → save → appears in Personal tab.
3. Personal run flow: open personal → detail → prepare → run → finish.

### 14.6 Data Builders / Fixtures
Create small builders in `test/fixtures/`:
```dart
CustomWorkout makeCustomWorkout({String name = 'Test'}) => CustomWorkout(
  id: 'test',
  name: name,
  description: '',
  difficulty: 'Beginner',
  muscleGroups: const ['Chest'],
  exercises: [
    CustomWorkoutExercise(id: 'push_up', setsAmount: 3, restTime: 60),
  ],
);
```

### 14.7 Assertions & Matchers
- Prefer explicit matchers (`equals`, `contains`, `isA`) over broad ones.
- For time/duration variability, assert ranges not exact equality.

### 14.8 Test Isolation
- Do not rely on SharedPreferences global state: use `SharedPreferences.setMockInitialValues({})` in test `setUp()`.
- Global singletons (e.g., `GlobalTimerService`) – reset between tests if used.

### 14.9 Coverage Targets (Initial)
- Models: ≥90%
- WorkoutBloc core transitions: ≥80%
- Critical widgets (selector, chips): snapshot/golden coverage.

### 14.10 Adding a New Test Suite Checklist
1. Identify public behaviors (inputs/outputs, events/states).
2. Mock dependencies & define fixtures.
3. Write happy path test.
4. Add at least one edge / failure test.
5. Run `flutter test` & ensure green.
6. Update AGENTS.md if a new pattern/tool introduced.

---

---

## 15. Error Handling

Hierarchical:
1. Service: capture and wrap error
2. BLoC: emit fallback state or keep prior data
3. UI: snack bar or quiet fail (avoid crashes)

Avoid silent catches without logging (`AppLogger.error` for unexpected paths).

---

## 16. Adding a New Feature (Template)

1. Clarify domain object changes (models + DTOs)
2. Add API call (DTO + service)
3. Extend BLoC (event + state + handler)
4. Build UI widget(s) with minimal internal logic
5. Wire UI ↔ BLoC events/states
6. Add audio/haptics if user-feedback-critical
7. Analyze, format, write tests

---

## 17. Performance Notes

- Avoid rebuilding large lists by mutating state in place; create new list instances.
- Debounce rapid set updates if needed (currently acceptable).
- Audio calls are lightweight; keep them out of tight loops.

---

## 18. Accessibility / Semantics

(Not fully implemented—future-ready)
- Prefer `Semantics(label: ...)` on tappable custom widgets (ExerciseChip, velocity selector).
- Ensure tap targets ≥ 44x44 logical pixels.

---

## 19. Known Gaps / Future Enhancements

- Web audio (needs asset + `just_audio`)
- Real rest time capture (currently stubbed)
- Unit tests (validators, BLoC event handling)
- Internationalization (validation restricts to English letters now)

---

## 20. PR / Commit Guidance (Agent)

Before signaling completion:
1. Run `flutter analyze`
2. Run `dart format .`
3. Summarize changes (files touched + why)
4. Do not leave commented-out code
5. Avoid introducing new global singletons (prefer existing patterns)

---

## 21. Anti-Patterns to Avoid

- Direct API calls inside widgets
- Modifying BLoC state fields without emitting a new state
- Creating duplicate style constants inline
- Adding sound calls directly (bypass `AudioService`)
- Using `print` instead of `AppLogger`

---

## 22. Quick Reference Snippets

Add BLoC event:
```dart
// workout_events.dart
class ExampleEvent extends WorkoutEvent {
  const ExampleEvent();
}
```

Handle in BLoC:
```dart
on<ExampleEvent>((event, emit) async {
  // logic
  emit(SomeState(...));
});
```

ExerciseChip usage:
```dart
ExerciseChip(
  title: exercise.name,
  setsCount: exercise.sets.length,
  variant: ExerciseChipVariant.current,
  onTap: () {},
);
```

---

## 23. Escalation

If a task requests restructuring that conflicts with these guidelines:
- Prefer adapter pattern over rewriting
- Document deviation in a short “Rationale” comment near the change

---

End of AGENTS.md