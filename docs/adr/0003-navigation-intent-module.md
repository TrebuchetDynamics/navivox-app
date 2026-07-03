# 0003 — Navigation intent module

Status: active implementation decision. The compatibility export remains at
`lib/router/navigation_intent.dart`, while the implementation lives under
`lib/router/intents/navigation_intent.dart` beside router provider/route modules.

Navigation intent variants are a sealed Dart class with static `go`/`maybeGo` methods rather than raw `context.go()` calls or a provider-based service. The resolver lives in `lib/router/navigation_intent.dart`, collocated with the app router and app route exports.

**Considered alternatives:**
- **Raw `context.go(AppRoutes.xxx)`** — the original pattern. Duplicated route constants across 6+ files, three different GoRouter access patterns (`context.go()`, `GoRouter.of().go()`, `GoRouter.maybeOf()?.go()`), no compile-time exhaustiveness.
- **Enum with route string** — cannot carry payload for `OpenChatThread(serverId, profileId)`. Would need a separate method or map for param-bearing routes.
- **Extension on `BuildContext`** — `context.goIntent(intent)` would couple intent resolution to the widget context, making tests harder.
- **Provider-injected service** — would require Riverpod dependency just for route resolution, which is a pure function.

**Rationale:** sealed class gives compile-time exhaustiveness in the resolver switch, supports payload variants, and keeps the import surface minimal (`NavigationIntent.go(context, const OpenSettings())`). Static methods avoid Riverpod or provider boilerplate for a pure function.