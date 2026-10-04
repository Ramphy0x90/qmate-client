# qmate-client

Flutter client for Qmate, a **platonic** companionship-matching app. No payments. The
server is a separate repo (`../qmate-server`). Its `CLAUDE.md` documents the API,
the WS protocol and the domain decisions (accept = instant match, decline = hide,
symmetric blocking, fixed role tags/addons). Read it first.

Stack: Flutter 3.44 / Dart 3.12, **material_ui** (not `package:flutter/material.dart`),
go_router 18, dio, web_socket_channel, flutter_secure_storage.

## Running

```sh
flutter run                                                  # desktop/web: server at localhost:8080
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080  # Android emulator
flutter build web --dart-define=API_BASE_URL=https://...     # release builds REQUIRE https
flutter test                                                 # unit + widget tests
QMATE_LIVE_TEST=1 flutter test test/live_server_contract_test.dart   # needs qmate-server running
```

The live contract test drives the real `ApiClient` and `ChatConnection` against the
server. It covers register → create → discover → accept → two-sided chat → block. Run
it after any change to models or the wire protocol on either side.

## Layout

```
lib/main.dart                  bootstrap: Session + ApiClient, restore token, runApp
lib/core/
  config.dart                  API_BASE_URL (--dart-define)
  models.dart                  wire models + enums (mirror server Postgres enums)
  session.dart                 Session (ChangeNotifier): token + current Profile
  api_client.dart              dio wrapper; every call throws ApiException(message, statusCode)
  chat_connection.dart         one match's WebSocket; emits ChatReady/MessageReceived/Error
  routes.dart                  Routes: static const paths + chatFor()/userFor() builders
  router.dart                  GoRouter: auth redirect, 4-tab StatefulShellRoute, pushed routes
lib/features/<name>/screens/   smart: own state, call ApiClient, navigate
lib/features/<name>/widgets/   dumb: data + callbacks via constructor only
lib/features/safety/safety_flows.dart   block/report dialog+API flows (used by chat + profile)
lib/shared/                    cross-feature dumb widgets + format helpers
```

## Architectural decisions

- **Smart screens / dumb widgets (hard rule).** Widgets never import `api_client.dart`
  or `session.dart`. They may hold purely local UI state (e.g. `ChatComposer`'s text
  controller, `ReportDialog`'s field). Everything else comes in as constructor params and
  callbacks.
- **No state-management package or DI container.** `main.dart` creates a single `Session`
  and a single `ApiClient`. `createRouter` passes them into screen constructors. Screens hold
  their own state in `StatefulWidget`s. Revisit this only when two screens genuinely need
  to share live, mutable state. (The current case of that is "blocked someone → Discover is
  stale", listed under gaps.)
- **`Session` is the router's `refreshListenable`.** Signing in or out (including the
  automatic sign-out when any API call returns 401) redirects between auth and app. Screens
  never navigate on login/logout themselves.
- **Token storage**: only the JWT is in `flutter_secure_storage`. The profile is re-fetched
  via `/me` on launch. A 401 clears the token. Any other failure (e.g. server down) keeps it
  stored for the next launch and shows login. JWTs last 7 days with no refresh, so an expired
  token simply means logging in again.
- **Routes**: always `Routes.x` / `Routes.chatFor(id)`, never literal paths. Chat and user
  profile are top-level routes pushed over the tab shell. Chat receives the `MatchView` via
  `extra` when available and falls back to fetching `/matches` on a cold deep link.
- **Enums are strict.** `fromWire` throws on an unknown value, and `ApiClient` surfaces that
  as "Unexpected response from server". Adding a role tag, activity or status on the server
  therefore **requires** a client update. That is deliberate, so a missing label can't render
  silently.
- **Chat**: `ChatScreen` opens the socket first and loads history on `ready`, so no message
  can fall between the history fetch and the subscription. Messages are merged by id, which
  dedupes the overlap and the server's echo of our own sends. Scrolling up pages older history.
  Server error `"this conversation is closed"` (block) ends the chat with no reconnect. A
  socket drop or `"resync"` shows a Reconnect banner.
- **material_ui**: Flutter 3.44 moved Material out of the framework. Import
  `package:material_ui/material_ui.dart` everywhere. go_router 18 detects
  `material_ui`'s `MaterialApp`, so mixing in `flutter/material.dart` would silently lose
  Material page transitions.
- **Avatars**: there's no photo upload in v1. `InitialsAvatar` shows `photoUrl` if one is ever
  set, and otherwise shows initials.
- **Release builds refuse a non-https `API_BASE_URL`** (`main.dart` throws at startup).
  Android and iOS would block cleartext anyway, but web and desktop wouldn't.
- **Secure-storage failures are non-fatal.** `Session` catches `PlatformException` on
  read/write/delete. The user stays signed in for that run but isn't remembered.
- **Pagination never auto-retries a failure.** Discover's scroll-triggered "load more" and
  chat's "load older" set a failed flag after an error. They resume only on an explicit Retry,
  a refresh, or a reconnect, so scrolling can't hammer a failing server. Discover also drops
  responses from a superseded refresh or filter (a `_generation` counter). My requests uses
  an explicit "Load older" button.
- When a refresh fails while a list is already on screen, a snackbar says so. The full-screen
  error view only shows when the list is empty.
- **Sign-up requires two checkboxes** (18+, and agreement to the Terms and Privacy Policy). Both
  are sent to the server, which records them. The policy pages are the server's `/legal/*`
  (`core/legal.dart`) and open in the browser via url_launcher. They're linked from
  Register and Profile.
- **Delete account** (Profile) asks for the password in `DeleteAccountDialog` and re-prompts
  on a wrong one. `ApiClient.deleteAccount` marks its request so the interceptor's
  "401 → sign out" doesn't fire for a wrong password.
- **Deleted users**: `MatchView.otherUser` and `ChatMessage.senderId` can be null. Use
  `MatchView.otherName` ("Deleted user"). Chats with a deleted user are read-only, with no
  profile link or safety menu.
- **Formatting**: `dart format` uses a page width of 120 (`analysis_options.yaml`).

## Known gaps

- **No profile editing** (stretch goal) and no photo upload.
- **No push or in-app notifications.** An author finds out about a match only by refreshing
  Matches or My requests. There's no unread state either.
- **Discover isn't refreshed after a block.** Blocking from a profile jumps to Discover, which
  keeps its old list until pull-to-refresh. Accepting a blocked user's request then fails
  (404) and the card is removed, so this is cosmetic but visible.
- **Chat reconnect is manual** (a banner button). There's no automatic backoff.
- **Open items from the design review:**
  - Block and Report are only in the chat overflow menu and at the bottom of profiles. They
    aren't on Discover cards or Matches, and Block isn't styled as destructive in the menu.
  - The Discover filter bar has a fixed 52px height and clips at large text scales.
  - Chat bubbles have no sender semantics, and timestamps have low contrast.
  - Cancel has no confirmation.
  - There's no max content width on wide screens.
- **Launch blockers** (the legal drafts still need placeholders filled and a lawyer's review;
  no moderation tooling): see the server CLAUDE.md.
- **No unblock UI** (the server has no unblock endpoint either).
- The UI has been compile-checked (`flutter build web`), widget-tested, and contract-tested
  for its API layer, but hasn't been manually exercised on a device yet.
- iOS: plain `http://` to a LAN IP needs an ATS exception for dev. Only `localhost` works
  without one. Android debug builds allow cleartext (`src/debug/AndroidManifest.xml`). Release
  builds don't.
- Linux desktop builds need `libsecret-1-dev` for flutter_secure_storage.
