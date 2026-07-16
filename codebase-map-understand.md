# Codebase Map from Understand-Anything

This file is a compact, agent-readable summary generated from Understand-Anything's knowledge graph. Keep it checked in only if your team wants future agents to start from this map.

## Project

- **Name:** navivox-app
- **Description:** Experimental cross-platform Flutter client for Hermes Agent with session chat, streamed activity, approval handling, endpoint configuration, and optional speech input. Note: this project has over 100 source files; consider scoping analysis to a subdirectory for faster results.
- **Languages:** arb, c, cmake, cpp, dart, entitlements, html, javascript, json, kotlin, manifest, markdown, pbxproj, properties, rc, shell, storyboard, swift, txt, unknown, xcconfig, xcscheme, xcsettings, xcworkspacedata, xib, xml, yaml
- **Frameworks:** Flutter, Riverpod, go_router, Playwright
- **Analyzed at:** 2026-07-15T21:54:08.509Z
- **Git commit:** f1f1eefb1685439ca2c0b28881d37d0793266591
- **Graph source:** `.understand-anything/knowledge-graph.json`
- **This file:** `codebase-map-understand.md`

## Size and shape

| Thing | Count |
| --- | ---: |
| Nodes | 476 |
| Edges | 125 |
| Layers | 8 |
| Tour steps | 11 |

### Node types

- file: 304
- document: 78
- function: 60
- config: 30
- class: 2
- pipeline: 2

### Edge types

- contains: 62
- exports: 40
- imports: 18
- tested_by: 5

## Architectural layers

- **Documentation** (78 nodes): Project guides, architecture decisions, security notes, runbooks, and planning records.
- **Test Suites** (80 nodes): Flutter, platform, integration, and browser tests that validate Navivox behavior.
- **Hermes Core** (48 nodes): Hermes API transport, channel, protocol, model, setup, and security-policy implementation.
- **Feature Modules** (70 nodes): User-facing chat, voice, enrollment, settings, agent, and experimental feature modules.
- **Application Shell** (22 nodes): Flutter entry points, application composition, routing, localization, and shared UI scaffolding.
- **Platform Integrations** (83 nodes): Android, iOS, macOS, Linux, Windows, and web host integration code.
- **Infrastructure & CI/CD** (2 nodes): Release and smoke-test workflows plus deployment-oriented project resources.
- **Project Support** (31 nodes): Build configuration, manifests, automation scripts, assets, and repository support files.

## Start here

- **2026-07-13-needle-router.md** (document, complex) — `docs/superpowers/plans/2026-07-13-needle-router.md` _documentation, markdown, routing_: Project documentation at docs/superpowers/plans/2026-07-13-needle-router.md containing 14 sections.
- **app_localizations_en.dart** (file, complex) — `lib/l10n/app_localizations_en.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations_en.dart.
- **app_localizations.dart** (file, complex) — `lib/l10n/app_localizations.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations.dart.
- **app_shell.dart** (file, complex) — `lib/shared/widgets/app_shell.dart` _source-code, dart, code_: Application source at lib/shared/widgets/app_shell.dart.
- **approval_stop_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart.
- **hermes_api_client.dart** (file, complex) — `lib/core/hermes/client/hermes_api_client.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/client/hermes_api_client.dart.
- **secure_hermes_endpoint_store.dart** (file, complex) — `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/setup/secure_hermes_endpoint_store.dart.
- **2026-07-13-needle-router-design.md** (document, moderate) — `docs/superpowers/specs/2026-07-13-needle-router-design.md` _documentation, markdown, routing_: Project documentation at docs/superpowers/specs/2026-07-13-needle-router-design.md containing 12 sections.
- **AndroidManifest.xml** (config, moderate) — `android/app/src/main/AndroidManifest.xml` _configuration, xml, config_: Project configuration at android/app/src/main/AndroidManifest.xml.
- **app_en.arb** (file, moderate) — `lib/l10n/app_en.arb` _source-code, arb, code_: Application source at lib/l10n/app_en.arb.

## Most important / complex nodes

- **2026-07-13-android-auth-profiles.md** (document, complex) — `docs/superpowers/plans/2026-07-13-android-auth-profiles.md` _documentation, markdown, security_: Project documentation at docs/superpowers/plans/2026-07-13-android-auth-profiles.md containing 12 sections.
- **2026-07-13-needle-router.md** (document, complex) — `docs/superpowers/plans/2026-07-13-needle-router.md` _documentation, markdown, routing_: Project documentation at docs/superpowers/plans/2026-07-13-needle-router.md containing 14 sections.
- **2026-07-13-needle-spike.md** (document, complex) — `docs/superpowers/plans/2026-07-13-needle-spike.md` _documentation, markdown, docs_: Project documentation at docs/superpowers/plans/2026-07-13-needle-spike.md containing 11 sections.
- **agents_screen_test.dart** (file, complex) — `test/features/agents/agents_screen_test.dart` _test, source-code, dart, code_: Test source at test/features/agents/agents_screen_test.dart.
- **agents_screen.dart** (file, complex) — `lib/features/agents/screens/agents_screen.dart` _source-code, dart, code_: Application source at lib/features/agents/screens/agents_screen.dart.
- **app_localizations_en.dart** (file, complex) — `lib/l10n/app_localizations_en.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations_en.dart.
- **app_localizations.dart** (file, complex) — `lib/l10n/app_localizations.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations.dart.
- **app_shell.dart** (file, complex) — `lib/shared/widgets/app_shell.dart` _source-code, dart, code_: Application source at lib/shared/widgets/app_shell.dart.
- **approval_stop_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart.
- **audit_hermes_readiness.sh** (file, complex) — `scripts/audit_hermes_readiness.sh` _source-code, shell, hermes_: Application source at scripts/audit_hermes_readiness.sh containing 9 functions.
- **cactus.dart** (file, complex) — `lib/features/voice_commands/ffi/cactus.dart` _source-code, dart, voice_: Application source at lib/features/voice_commands/ffi/cactus.dart.
- **connection_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart.
- **direct_chat_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/direct_chat_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/direct_chat_tests.dart.
- **fake_hermes_channel.dart** (file, complex) — `test/features/hermes_chat/support/fake_hermes_channel.dart` _test, source-code, dart, hermes_: Test source at test/features/hermes_chat/support/fake_hermes_channel.dart.
- **handleHermesApi** (function, complex) — `serve_web.mjs:72-300` _function, javascript, implementation_: Function handleHermesApi implements behavior in serve_web.mjs.

## High-signal relationships

- **hermes-live-api.spec.mjs** --imports→ **flutter_semantics.mjs**
- **hermes-live-say-hi.spec.mjs** --imports→ **flutter_semantics.mjs**
- **hermes-provider-chat.spec.mjs** --imports→ **flutter_semantics.mjs**
- **hermes-smoke.spec.mjs** --imports→ **flutter_semantics.mjs**
- **e2e-screenshots.spec.mjs** --imports→ **flutter_semantics.mjs**
- **flutter_window.cpp** --imports→ **flutter_window.h**
- **main.cpp** --imports→ **flutter_window.h**
- **main.cpp** --imports→ **utils.h**
- **utils.cpp** --imports→ **utils.h**
- **MainActivity.kt** --imports→ **DeviceSpeechDiagnostics.kt**
- **MainActivity.kt** --imports→ **DurableKeyStoreChannel.kt**
- **MainActivity.kt** --imports→ **PairingHandoffIntentParser.kt**
- **main.cc** --imports→ **my_application.h**
- **my_application.cc** --imports→ **my_application.h**
- **win32_window.cpp** --imports→ **resource.h**
- **win32_window.cpp** --imports→ **win32_window.h**
- **generated_plugin_registrant.cc** --imports→ **generated_plugin_registrant.h**
- **generated_plugin_registrant.cc** --imports→ **generated_plugin_registrant.h**

## Guided reading order

1. **Project Overview**: Start with the README to understand Navivox's role as a cross-platform Flutter client for Hermes Agent. It also establishes the alpha support matrix, compatibility contract, privacy constraints, and development workflow used throughout the repository.
1. **Application Bootstrap**: The production and browser-test entry points launch the Flutter application through the shared app facade. Reading these files first shows how normal and end-to-end environments converge on the same runtime composition.
1. **Shell and Routing**: The application widget and router define the top-level navigation shell exposed to users. This is the bridge from bootstrap code into feature screens and endpoint-aware navigation.
1. **Hermes API Boundary**: These files establish the public Hermes API surface and the HTTP client used to reach a configured agent endpoint. They are the starting point for tracing capability negotiation, transport policy, and request execution.
1. **Streaming Channel**: The channel contracts and API-backed implementation coordinate sessions, streamed events, approvals, profiles, and voice-related calls. Together they form the runtime seam between Hermes transport details and feature state.
1. **Hermes Domain Models**: The session model represents one of the core data contracts shared across channels and features. Use it as an anchor before exploring the adjacent run, job, provider, profile, and tool-call models.
1. **Chat Experience**: The chat screen assembles connection state, streamed assistant activity, tool output, approvals, and user input into the primary Navivox experience. It demonstrates how the app shell consumes the Hermes channel and domain layers.
1. **Voice Pipeline**: Voice capture is split into an abstract service, recording policy, and speech-to-text coordination. This separation keeps platform recognition behavior and bounded continuous capture replaceable without changing chat orchestration.
1. **Enrollment Flow**: The enrollment screen handles the trusted setup path for connecting Navivox to Hermes. Read it after the API and routing layers to see how endpoint configuration becomes an interactive user flow.
1. **Native Platform Bridges**: Android and iOS application delegates connect Flutter to native lifecycle and platform-channel behavior. These hosts explain where durable key, speech, handoff, and OS integration concerns leave Dart code.
1. **Validation and Release**: The platform smoke workflow validates supported targets, while the alpha release workflow packages source-distributed artifacts. Together they show the evidence gates behind the support claims introduced in the README.

## File hotspots

- **2026-07-13-android-auth-profiles.md** (document, complex) — `docs/superpowers/plans/2026-07-13-android-auth-profiles.md` _documentation, markdown, security_: Project documentation at docs/superpowers/plans/2026-07-13-android-auth-profiles.md containing 12 sections.
- **2026-07-13-needle-router.md** (document, complex) — `docs/superpowers/plans/2026-07-13-needle-router.md` _documentation, markdown, routing_: Project documentation at docs/superpowers/plans/2026-07-13-needle-router.md containing 14 sections.
- **2026-07-13-needle-spike.md** (document, complex) — `docs/superpowers/plans/2026-07-13-needle-spike.md` _documentation, markdown, docs_: Project documentation at docs/superpowers/plans/2026-07-13-needle-spike.md containing 11 sections.
- **agents_screen_test.dart** (file, complex) — `test/features/agents/agents_screen_test.dart` _test, source-code, dart, code_: Test source at test/features/agents/agents_screen_test.dart.
- **agents_screen.dart** (file, complex) — `lib/features/agents/screens/agents_screen.dart` _source-code, dart, code_: Application source at lib/features/agents/screens/agents_screen.dart.
- **app_localizations_en.dart** (file, complex) — `lib/l10n/app_localizations_en.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations_en.dart.
- **app_localizations.dart** (file, complex) — `lib/l10n/app_localizations.dart` _source-code, dart, code_: Application source at lib/l10n/app_localizations.dart.
- **app_shell.dart** (file, complex) — `lib/shared/widgets/app_shell.dart` _source-code, dart, code_: Application source at lib/shared/widgets/app_shell.dart.
- **approval_stop_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/approval_stop_tests.dart.
- **audit_hermes_readiness.sh** (file, complex) — `scripts/audit_hermes_readiness.sh` _source-code, shell, hermes_: Application source at scripts/audit_hermes_readiness.sh containing 9 functions.
- **cactus.dart** (file, complex) — `lib/features/voice_commands/ffi/cactus.dart` _source-code, dart, voice_: Application source at lib/features/voice_commands/ffi/cactus.dart.
- **connection_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart.
- **direct_chat_tests.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_tests/direct_chat_tests.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_tests/direct_chat_tests.dart.
- **fake_hermes_channel.dart** (file, complex) — `test/features/hermes_chat/support/fake_hermes_channel.dart` _test, source-code, dart, hermes_: Test source at test/features/hermes_chat/support/fake_hermes_channel.dart.
- **handleHermesApi** (function, complex) — `serve_web.mjs:72-300` _function, javascript, implementation_: Function handleHermesApi implements behavior in serve_web.mjs.
- **hermes_api_channel_messaging.dart** (file, complex) — `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart.
- **hermes_api_channel_profiles.dart** (file, complex) — `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart.
- **hermes_api_channel_providers.dart** (file, complex) — `lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart.
- **hermes_api_channel_test.dart** (file, complex) — `test/core/hermes/channel/hermes_api_channel_test.dart` _test, source-code, dart, hermes_: Test source at test/core/hermes/channel/hermes_api_channel_test.dart.
- **hermes_api_client.dart** (file, complex) — `lib/core/hermes/client/hermes_api_client.dart` _source-code, dart, hermes_: Application source at lib/core/hermes/client/hermes_api_client.dart.

## Notes for future agents

- Prefer this Markdown file for quick orientation.
- Use the full JSON graph when you need exact node IDs, line ranges, or relationship details.
- Re-run `/understand` after major code changes; it refreshes this file automatically unless `--no-agent-map` is used.
