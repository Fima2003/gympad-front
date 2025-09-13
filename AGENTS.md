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
- Storage: Hive for storage
- Firebase Auth + backend API services
- Platform targets: iOS, Android, Web

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
3. Services (API, hive, auth, audio, etc.) (`lib/services`)
4. DTOs for sending objects via the network (`lib/services/api/models`)
5. Models for the internal use in the application (`lib/models`)
6. Adapters for the hive (`lib/services/hive/adapters`)
7. Utilities (timers, formatting)

Rules:

- Screens never call API services directly—dispatch BLoC events or call a domain service exposed via BLoC.
- Local persistence only from services; never from widgets.
- Keep business transformations (mapping performed sets to DTOs) in the screen or a helper, not in widgets.

---

## 6. State Management

Primary responsibilities:

- Sync personal workouts (event: `PersonalWorkoutsSyncRequested`)
- Manage workout session lifecycle (exercise start/end, workout completion)
- Emit domain states (`WorkoutInProgress`, `WorkoutCompleted`, `PersonalWorkoutsLoaded`, etc.)

When adding new features:

1. Define new Events
2. Define corresponding States if needed
3. Implement handlers for every event in `{name}_bloc.dart`
4. Ensure UI listens (BlocBuilder/BlocListener) and acts minimally (navigation, minor UI updates)

Do not mutate lists in-place; emit cloned lists to force rebuild.

---

## 7. Navigation Conventions

- Use go router navigation with strongly typed arguments.
- if the screen is not present in the `main.dart`, add it there

---

## 8. Theming & Styling

Central references:

- `AppColors`
- `AppTextStyles`

Guidelines:

- Use semi-transparent surfaces (e.g., `Colors.white.withValues(alpha: 0.06)`) for cards over dark backgrounds.
- Accent color limited to primary CTAs and current exercise highlight.
- Avoid hard-coded text styles; use `AppTextStyles` or copyWith.
- If a new text style or color is being repeated over and over — feel free to add it

---

## 9. Local Storage Services

Location: `lib/services/hive`
Patterns:

- Initialization

  - Register all adapters explicitly with concrete generic types to avoid dynamic dispatch issues:
    `Hive.registerAdapter<HiveWorkout>(HiveWorkoutAdapter());`
  - Guard with `Hive.isAdapterRegistered` before registering.

- Boxes (naming and access)

  - One service per box; keep box names constant and scoped in the service, for example:
    - Current workout: `current_workout_box`, key `current`.
  - Open boxes lazily via a private helper: if open use `Hive.box<T>(name)` else `Hive.openBox<T>(name)`.
  - Never open boxes in widgets; only in services.

- Data mapping (Domain ↔ Hive)

  - Keep Hive-only models in `lib/services/hive/adapters/` with `@HiveType(typeId: X)` and `.g.dart`.
  - Each adapter provides:
    - `fromDomain(domain)` factory to convert domain → Hive model.
    - `toDomain()` to convert Hive model → domain.
  - Store primitives only (e.g., `Duration` as microseconds) to keep Hive schemas stable.

- CRUD patterns

  - Replace-all: `box.clear()` then `box.putAll({...})` when syncing lists (e.g., personal workouts).
  - Point updates: use deterministic keys (`id` for history/current; index for ordered lists).
  - Mark/patch flows: read → copy/construct updated → put back (see `markUploaded`).
  - For singletons (current workout, auth), keep a single constant key.

- Error handling & logging

  - Wrap IO with try/catch; log via `AppLogger` (not `print`) and rethrow when upstream needs to react.
  - When failures are non-fatal for UX (e.g., load optional data), return sensible defaults (empty list/null).

- Lifecycle utilities

  - Provide `clear()` methods on services to wipe a box (used on sign-out or resets).
  - For optional companion boxes (e.g., to-follow), check `Hive.isBoxOpen/boxExists` to avoid errors.

- Migrations / schema stability

  - Keep `typeId`s stable; never reuse IDs.
  - When changing data shapes, prefer adding fields with defaults over renaming/removing.
  - If a breaking change is unavoidable, introduce new `typeId` and map forward in service during load.

- Testing

  - Unit-test mapping logic: domain → Hive → domain round-trip.
  - Use a temporary directory with `Hive.init` in tests; register adapters explicitly.
  - Mock services at higher layers; don’t access Hive from UI/blocs directly.

- Do nots
  - Don’t access boxes from UI/widgets.
  - Don’t store domain models directly; always convert via adapters.
  - Don’t scatter box names/keys—keep them as private constants in the owning service.

---

## 10. API Services

Location: `lib/services/api`
Patterns:

- Each endpoint method returns a wrapper with `success`, `status`, `data`, `message`.
- After adding a new endpoint:
  1. Create DTOs in `models/`
  2. Add method to service
  3. Integrate in service, not directly in UI or bloc

Authentication:

- `AuthService` maintains id token in Hive; if unauthorized, attempt refresh (already implemented in `fetchUserOnAppStartWithRetry` pattern).

---

## 11. Testing Strategy

We currently have minimal tests. New code should follow these testing layers (use `flutter test`).

### 11.1 Test Pyramid

1. Model & Utility Unit Tests (fast) – pure Dart: JSON (de)serialization, value objects, validators.
2. BLoC Tests – event → state transitions with mocked services.
3. Widget (Golden) Tests – critical widgets (ExerciseChip, WeightSelector) for visual & interaction integrity.
4. Integration / Flow Tests – high‑value user flows (start workout → add exercise → add set → finish → save).

### 11.2 Conventions

- File naming: `<unit>_test.dart` matching source structure under `test/`.
- Group tests with `group('Description', () { ... });` and prefer descriptive `test()` names: `test('emits WorkoutInProgress after WorkoutStarted', ...)`.
- Use `setUp` / `tearDown` for shared fixtures.

### 11.3 BLoC Testing Pattern

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

### 11.4 Widget Testing

Use `pumpWidget` with minimal `MaterialApp`/`BlocProvider` shell. Prefer keys for querying dynamic elements.
Golden tests (optional): capture critical UI states (light & dark backgrounds). Store goldens under `test/goldens/`.

### 11.5 Integration / Flow

Use `integration_test` for end‑to‑end flows (later). Scenarios:

1. Free workout flow: start → add set → break → finish → well done.
2. Save workout flow: perform → save → appears in Personal tab.
3. Personal run flow: open personal → detail → prepare → run → finish.

### 11.6 Data Builders / Fixtures

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

### 11.7 Assertions & Matchers

- Prefer explicit matchers (`equals`, `contains`, `isA`) over broad ones.
- For time/duration variability, assert ranges not exact equality.

### 11.8 Test Isolation

- Do not rely on SharedPreferences global state: use `SharedPreferences.setMockInitialValues({})` in test `setUp()`.
- Global singletons (e.g., `GlobalTimerService`) – reset between tests if used.

### 11.9 Coverage Targets (Initial)

- Models: ≥90%
- WorkoutBloc core transitions: ≥80%
- Critical widgets (selector, chips): snapshot/golden coverage.

### 11.10 Adding a New Test Suite Checklist

1. Identify public behaviors (inputs/outputs, events/states).
2. Mock dependencies & define fixtures.
3. Write happy path test.
4. Add at least one edge / failure test.
5. Run `flutter test` & ensure green.
6. Update AGENTS.md if a new pattern/tool introduced.

---

---

## 12. Error Handling

Hierarchical:

1. Service: capture and wrap error
2. BLoC: emit fallback state or keep prior data
3. UI: snack bar or quiet fail (avoid crashes)

Avoid silent catches without logging (`AppLogger.error` for unexpected paths).

---

## 13. Adding a New Screen (Template)

Use a bottom-up approach:

1. Clarify domain object changes (models + DTOs)
2. Add API call if necessary (DTO + service)
3. Create a service for the feature
4. Create/extend BLoC (event + state + handler)
5. Build UI view(s) with minimal internal logic and without using BLoC unless it is absolutely irreplaceable
6. Create one UI screen that will have BlocListener or BlocConsumer, etc. this UI screen should render UI view(s) based on the state
7. Wire UI ↔ BLoC events/states
8. Add audio/haptics if user-feedback-critical

---

## 14. Performance Notes

- Avoid rebuilding large lists by mutating state in place; create new list instances.
- Debounce rapid set updates if needed (currently acceptable).
- Audio calls are lightweight; keep them out of tight loops.
- Use DRY principle and SSOT

---

## 15. PR / Commit Guidance (Agent)

Before signaling completion:

1. Run `flutter analyze`
2. Run `dart format .`
3. Summarize changes (files touched + why)
4. Do not leave commented-out code
5. Avoid introducing new global singletons (prefer existing patterns)

---

## 16. Anti-Patterns to Avoid

- Direct service calls inside widgets
- Modifying BLoC state fields without emitting a new state
- Creating duplicate style constants inline
- Adding sound calls directly (bypass `AudioService`)
- Using `print` instead of `AppLogger`

---

## 17. Quick Reference Snippets

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

---

## 18. Escalation

If a task requests restructuring that conflicts with these guidelines:

- Prefer adapter pattern over rewriting
- Document deviation in a short “Rationale” comment near the change

---

End of AGENTS.md
