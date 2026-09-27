# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Baytouti (بيتوتي), the customer app** — a marketplace for Kuwait's producing
families. Built from the Claude Design project
`abedcbee-1f5b-4ec4-b8fb-6675543c7a53` (reading it needs `/design-login`):

- `Baytouti Customer App.dc.html` — the 13 screens this app implements.
- `Baytouti API Spec.dc.html` — the backend contract. **Field names in it are
  what the models read; renaming one means changing the app.**
- `_ds/modernist-…/styles.css` — the design system the customer file
  overrides with its own tokens.
- `Baytouti Vendor App.dc.html` and the BRD belong to the vendor app, not here.

`lib/core` started as a copy of `../cloack_vendor/lib/core` and was reworked
for Baytouti's contract. The copies are not linked. `../cloack_vendor` and
`../cloack` still hold worked examples of the patterns below.

## Git

Connected to `https://github.com/omarmaamoun179/baytoti.git` on `main`. The
user makes every commit and push themselves — Claude Code commits or pushes
here only when explicitly asked to.

## Commands

Use Flutter 3.47.3 (Dart 3.13), the SDK `.vscode/settings.json` pins and the
first `flutter` on `PATH`. 3.35.2 cannot satisfy `sdk: ^3.11.1`.

```bash
F=/Users/omar/flutter_ver/flutter_3.47.3/bin/flutter
$F pub get
$F analyze                        # must be clean — no issues, not "no errors"
$F test
$F run
```

**Do not run `dart format`.** The code is not formatted with the current
formatter, so it rewrites unrelated indentation across most files. Match the
surrounding style by hand: `=>` bodies continue at 6 spaces with their block
indented 8.

**No comments in any file** — not `//`, `///` or `/* */` in Dart, not `#` in
YAML, tests included. Reasoning worth keeping goes in this file.

### Build-time switches

```bash
flutter run --dart-define=USE_MOCK_DATA=false      # the live API instead of fixtures
flutter run --dart-define=BASE_URL=https://staging.example.com/v1/
```

`useMockData` (`core/di/injection_container.dart`) defaults to **true** and
only decides which data source each repository is built with.
**`api.baytouti.com` does not exist yet** (NXDOMAIN on 2026-09-23), so every
feature — auth included — has a fixture source, and the app is only usable on
fixtures today.

`lib/main.dart` is one line; everything before the first frame is in
`core/app/bootstrap.dart`: binding → localization → DI → session restore →
`runApp`. Nothing may reach the network before `runApp` (the requests
inspector's controller is created disabled by whoever asks first).

## The fixture backend

`features/catalog/data/fixtures/` is a stand-in for the server:
`FixtureData` holds the design's own content (four families, six products,
categories, reviews, order steps, notifications) in Arabic and English, and
`FixtureBackend` (a lazy singleton) answers every endpoint **in the
contract's exact JSON shape** and keeps the state a server would — favourites,
follows, the cart, orders, OTP requests. A mock data source is
`await _backend.wait()` then `Model.fromJson(_backend.x(lang))`, so the
models are exercised against the contract even with no backend. The
language comes from `ContentLanguage` (the same language the remote sends as
`Accept-Language`). Fixture rules: OTP `0000` is refused as `otp_invalid`,
any other four digits sign in; coupon `BAYT10` is valid; order `ord_1998` is
delivered and can be rated.

## Current state

All 13 screens of the design are built and run on fixtures. Known gaps and
deliberate departures:

- **No live backend**, so every remote data source is written against the
  contract but has never answered a real request.
- **`POST /auth/refresh` is unused**: an expired access token (the contract
  says 3600 s) ends the session instead of being renewed.
- **Explore's `nearby` tab sends no `lat`/`lng`** — the app has no location.
- **Screens the design routes to but does not draw**: "Favourites and
  following" opens Explore, "Addresses" opens checkout, "Support" opens
  notifications, and "My orders" opens the newest order
  (`OrderPage.latest` resolves `GET /orders`). No favourites list, address
  book or orders list exists.
- **The prototype's "Simulate status progress" button is not built**;
  fixture order `ord_1998` is delivered so the rating card can be seen.
- **The exhibition banner's QR action is inert** — the contract stubs it.
- **Two client-side price calculations**, both previews: the product bar's
  line total (price × quantity) and checkout's total when the chosen
  fulfilment fee differs from the cart's shipping
  (`OrderTotals.withShipping`). Everything else shows server displays.
- **Fixture photos are bundled**, not served: `FixtureBackend` answers with
  image objects whose `url` is an asset path (`assets/images/catalog/…`,
  built by `AppAssets`), and `NetworkPhoto` renders an `assets/` URL from the
  bundle and anything else from the network. All are CC0 — sources in
  `assets/CREDITS.md`, which is kept outside the bundled folders.
  `test/assets_test.dart` fails if a referenced photo is missing.
- **`AuthCubit.updateCustomer` is in memory only**: after a restart the
  profile shows the sign-in name until `/me` answers.
- The auth header has a back button the design omits, so a guest sent to
  sign in by a protected tab can leave.

## The API contract, as core reads it

- **Base URL** `https://api.baytouti.com/v1/` (`core/utils/constants.dart`,
  trailing slash required). Paths in `ApiEndPoint`.
- **No envelope.** A 2xx body *is* the resource; `checkedResponse(response)`
  returns an `ApiResponse` whose `.json` is that body, and throws on failure.
- **Errors** are `{"error": {"code", "message", "field", "details"}}`. `code`
  is stable (`otp_invalid`, `otp_expired`, `rate_limited`,
  `stock_insufficient`, `coupon_invalid`) and reaches the cubit as
  `Failure.code`; `message` is already localised and safe to show; a `field`
  makes it a `ValidationFailure` keyed by that field.
- **Money** is integer fils plus a localised display string: `Money.of(json,
  'price')` reads `price_fils`/`price_display`. Show `display`, never format
  a server amount yourself. `Money.format` exists only for fixtures.
- **Lists** are cursor pages: `{items, next_cursor}` → `Paged<T>`
  (`hasMore` is `nextCursor != null`, never the row count).
- **Locale** goes out as `Accept-Language: ar-KW|en-KW`; content (product
  names, order labels, notification text) comes back already localised. The
  app translates only its own chrome.
- **Auth**: `request-otp` → `verify-otp` returns access and refresh tokens
  (`TokenStore`). `POST /auth/refresh` exists in the contract but nothing calls
  it: a 401 on a call sent with the stored token ends the session
  (`NetworkServiceImpl` → `AuthCubit.sessionExpired`). Public calls pass
  `skipAuthRefresh: true`. Catalogue reads work without a token; the cart,
  checkout, orders, favourites, follows, notifications and `/me` need one.
- **The cart is server-owned**: every mutation answers the full recalculated
  cart and the app never adds prices up.

## Architecture

Clean architecture per feature under `lib/features/<name>/`:
`data/` + `domain/` + `presentation/`. Data flows one way: **data source →
repository → use case → cubit → widget**. A cubit depends on use cases, never
on a repository. Only the data layer knows about HTTP or storage; everything
above sees `Either<Failure, T>` (dartz).

Features: `catalog` (shared product/family/category/totals entities and
models, favourites, the fixture backend, `ProductCard`), `auth`, `home`,
`explore`, `search`, `product`, `family`, `cart`, `checkout`, `orders`,
`notifications`, `profile`, `shell` (the tab bar). A feature may import
another feature's `domain` entities and `catalog`; it never imports another
feature's `data` from `presentation`.

### Dependency injection

`get_it` as `sl`, wired once by `initDependencies()` in
`core/di/injection_container.dart` (a `part of` `di_exports.dart`). A feature
adds its own `_registerXFeature()` there. `registerSingleton` for core
services, `registerLazySingleton` for data sources, repositories, use cases
and app-wide cubits, `registerFactory` for one cubit per screen. Each data
source is `useMockData ? XMockDataSource(sl<FixtureBackend>(),
sl<ContentLanguage>()) : XRemoteDataSource(sl<NetworkService>())`.

App-wide cubits, provided in `core/app/app.dart`: `NetworkCubit`, `AuthCubit`
(the signed-in customer; the only thing that calls
`SessionNotifier.signedIn()`/`signedOut()`) and `CartCubit` (the tab badge;
loads when a session starts and empties when it ends, by listening to
`SessionNotifier`). State that belongs to an account follows
`SessionNotifier`, not another cubit.

### Error handling — MANDATORY

`Either` for all fallible operations; errors are caught in the DATA SOURCE,
never in the repository. The error type is `Failure`
(`core/domain/failure.dart`, sealed): `NetworkFailure` (offline, retryable),
`ServerFailure`, `CacheFailure`, `UnexpectedFailure`, `ValidationFailure`
(carries `fieldErrors`). Every failure may carry the API's `code`.

- **Data source**: every method returns `Future<Either<Failure, T>>` and its
  whole body runs inside `guardedRequest('XDataSource.method', () async {…},
  fallbackMessage: '<key>')` (`guardedStorage` for local storage). Parsing
  stays inside, so a bad payload becomes `UnexpectedFailure`, never a
  connection error. Never return an empty list or a fallback on failure.
- **Repository**: no try/catch. Single calls are pass-through; multi-step
  flows fold once and guard side effects (see `AuthRepositoryImpl.verifyOtp`).
- **Cubit**: never catches; folds into an emitted state; both branches emit.
  The one exception to "`Future<void>` + emit": an action whose caller must
  react to *its own* outcome — `CartCubit.add`, `CartCubit.applyCoupon` —
  returns `Future<Failure?>`, because every page under the shell stays mounted
  and a state listener would fire on all of them.

`mapExceptionToFailure` is where a message becomes displayable: above it,
`Failure.message` is always safe to show. Any sentinel used as a message
(`fallbackMessage`, `messageForStatus`) needs an entry in
`assets/translations/` and in `errorMessageKeys` in
`test/translations_test.dart`.

### Routing

One `GoRouter` in `core/routing/app_router.dart`, paths in `routes.dart`. Five
tabs in a `StatefulShellRoute`: `/home`, `/explore`, `/search`, `/cart`,
`/profile`. **Detail screens nest under the tab they were opened from** —
`/explore/families/fam_2`, `/cart/checkout`, `/profile/orders/ord_2041` — so
the tab bar stays, as the design draws it, and back stays inside the tab.
Open them with the `AppNavigation` extension (`context.openProduct(id)`,
`openFamily`, `openOrder`, `openNotifications`, `pushInTab(segment)`), which
prefixes the current tab. The shell hides the tab bar on product pages, the
one screen the design draws without it. `/welcome`, `/auth` and `/otp` are
root routes for guests.

The guard reads `SessionNotifier`. Protected: the `/cart` and `/profile` tabs
and any path with an `orders`, `checkout` or `notifications` segment. A guest
is sent to `/auth?from=<location>` and, once verified, back to `from`.
`test/route_guard_test.dart` asserts every registered path is classified.
Guest actions that need an account (add to cart, favourite, follow, the bell)
go through `requireSignIn(context)` / `addToCart(context, …)` in
`features/cart/presentation/cart_actions.dart`.

Pages that show server content key their `BlocProvider` on the locale —
`BlocProvider(key: ValueKey(context.locale.languageCode), …)` — so switching
language re-reads the content in the new language.

## Presentation conventions

**Page files stay under 200 lines, 250 absolute maximum.** Widgets go in the
feature's `presentation/widgets/`; layout specific to one page stays in that
page as a `_buildX` method. **Provider placement:** `XPage` creates the
`BlocProvider`, a separate `_XView` consumes it.

**Styling** follows the design's CSS one to one:

- Colors: `context.palette` (`AppPalette`), named after the design's CSS
  variables — `bg`, `surface`, `text`, `divider`, `accent`, `accent100`,
  `accent700`, `neutral200`…`neutral800`, `amber`, `amberTint`, `amberInk`,
  `danger`. `p.hairline` / `p.rule` are the 1px and 2px divider borders;
  `p.cardShadow` is `--bt-card`. Light only.
- Type: `AppStrings.w800(13, 1.3)` is `font: 800 13px/1.3` — Archivo with IBM
  Plex Sans Arabic as fallback. Color at the call site: `.c(p.text)`.
  Letter-spacing (`.spaced`) never goes on Arabic; `SectionLabel` tracks
  Latin only.
- Icons: `AppIcon(AppIcons.bell, …)` renders the design's own SVG paths
  (`flutter_svg`); directional ones mirror in RTL.
- Shared widgets in `core/widgets/`: `AppHeader`, `HeaderIconButton`,
  `AppButton`, `SectionLabel`, `SectionHeading`, `QuantityStepper`,
  `StatGrid`, `PillChip`/`ChipStrip`, `LabeledField`/`AppTextField`/
  `PhoneField`, `EmptyState`, `LoadingView`/`ErrorView`, `NetworkPhoto`
  (an empty image list shows the design's neutral placeholder),
  `PagedScrollListener`, `showAppToast`, `showConfirmSheet`, brand marks.

**Cubits** extend `BaseCubit`. A state's `copyWith` **clears**
`errorMessage` unless passed again. **Errors are shown in a toast**
(`showAppToast(context, message, isError: true)`); inside a bottom sheet use
`SheetErrorNote`.

Paginated lists: `PagedScrollListener(isLoading:, onEndOfPage:, child:)`
over one scrollable; the cubit guards `loadMore` (in flight / no cursor),
keeps a generation counter, and keeps the list when a next page fails. Search
boxes that hit the server debounce in the cubit with rxdart
(`debounceTime(500ms).distinct()`), and query objects omit absent values.

## Localization

`easy_localization`, Arabic and English, Arabic by default and RTL. Keys in
`assets/translations/{en,ar}.json` — **both files hold the same key set**
(`test/translations_test.dart`). User-facing chrome is always `'key'.tr()`.
Switch language only through `LocalizationService.change`, which updates the
UI locale and the `Accept-Language` the API and fixtures answer in.

Phone numbers are Kuwaiti: `PhoneField` pins `+965` (the design does) and
takes eight digits; send `+965` + digits in E.164.
