GitHub Copilot

User-related integration test structure (no code):

1. Environment & Setup

- Hive + adapter init once; clean boxes between tests.
- Mock backend (Dio interceptors / test server / emulator) with switchable scripted responses.
- Firebase Auth emulator or mock: create user, sign in, force token refresh, sign out.

2. Authentication Flow

- Sign Up: create user -> receives valid token -> user auth box populated (userId, authToken, gymId null).
- Sign In Existing User: cached token reused; if absent, fetched then cached.
- Sign Out: local Hive auth cleared; protected endpoint afterwards fails (401).

3. Token Handling

- Valid Cached Token: request uses cached token (no Firebase call).
- Expired Token (simulate 401): triggers refresh path, retries once, success.
- Refresh Failure (401 then refresh fail): returns failure; no infinite retry; error surfaced.
- Token After User Reload: first getIdToken throws, reload succeeds, token cached.

4. Profile Retrieval & Consistency

- Partial Read -> Full Read: partial fields subset of full; gymId consistent; timestamps present in full.
- Full Read Missing Optional Fields: gracefully maps nulls (e.g., gymId absent).
- Data Cache Independence: modifying local Hive user auth does not auto-alter API responses (stateless calls).

5. Profile Updates

- Update Name Only: PUT sent with name only; response success; subsequent full read reflects new name.
- Update Gym Only: gymId updated; name unchanged.
- Update Both: atomic (both updated in single request).
- Clear Gym: gymId set to ''; persisted state matches.
- Invalid Update (empty both): no network call; validation failure.

6. Deletion Flow

- Delete User: DELETE returns success; subsequent authenticated request returns 401; local Hive auth cleared.
- Delete Without Auth: returns 401; no mutation of local storage.

7. Error & Resilience

- Network Timeout: surfaces timeout error; no stale data persisted.
- Server 500: returns failure; no mutation to Hive auth data.
- Malformed JSON: parser error -> failure object (or handled fallback) logged; no crash.
- Intermittent Failure (500 then success on retry if enabled) only retries within defined policy (if you add one).

8. Authorization Enforcement

- Protected Endpoint Without Token: rejects, does not call parser, logs auth warning.
- Protected Endpoint After Sign Out: same rejection path.

9. Persistence Layer Integration

- Auth Token Persisted Once: after multiple requests token stored only once (no redundant writes) — can inspect number of writes (wrap Hive or spy).
- Corrupted Hive Entry (manually write unexpected map): load gracefully returns null, triggers Firebase fetch path.
- Migration Scenario (if future schema): old format converted to new without breaking requests.

10. Concurrency & Race Conditions

- Parallel Requests After Expiration: only one refresh executed; others wait and reuse refreshed token (if you implement locking).
- Concurrent Update + Read: update response applied; subsequent full read reflects changes; no stale caching.

11. Edge Cases

- GymId Empty String vs Null: clearGym sets ''; partial/full reads preserve chosen representation.
- Long Name / Unicode: update handles multi-byte characters; retrieved intact.
- Rapid Sequential Updates: last update wins; intermediate states not persisted incorrectly.

12. Logging & Observability (optional assertions if you expose logger hooks)

- Info logs on successful auth fetch.
- Warning logs on missing token.
- Error logs on refresh failure or malformed response.

13. Performance (optional)

- Average latency for userPartialRead under mocked fast path (cached token) versus cold path (Firebase fetch).
- Memory: no unbounded growth in Hive boxes across multiple test iterations.

Grouping Example

- group('Auth Flow', …)
- group('Token Refresh', …)
- group('Profile Reads', …)
- group('Profile Updates', …)
- group('Deletion', …)
- group('Error Handling', …)
- group('Persistence Integration', …)
- group('Concurrency', …)
- group('Edge Cases', …)

Each test: Arrange (seed Hive + mock backend), Act (call service method), Assert (ApiResponse, Hive state, side effects, logs if captured).

Ask if you want a prioritized minimal subset or scaffolding next.
