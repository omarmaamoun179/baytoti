# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Baytouti (بيتوتي), the customer app** — a marketplace for Kuwait's producing
families. Built from the Claude Design project
`abedcbee-1f5b-4ec4-b8fb-6675543c7a53` (reading it needs `/design-login`):

- `Baytouti Customer App.dc.html` — the 13 screens this app implements.
- `Baytouti API Spec.dc.html` — the original, fictional contract. **Superseded
  by the live backend** (see "The API contract"); don't model fields from it.
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
flutter run --dart-define=BASE_URL=https://staging.example.com/api/v1/
```

There is no mock mode. Every data source talks to the real backend; the old
fixture backend, `useMockData`, `ContentLanguage` and the bundled demo photos
were deleted on 2026-09-28.

`lib/main.dart` is one line; everything before the first frame is in
`core/app/bootstrap.dart`: binding → localization → DI → cached market
(local storage) → session restore → `runApp`. Nothing may reach the network
before `runApp` (the requests inspector's controller is created disabled by
whoever asks first).

## Tests and API samples

Tests never touch the network. `test/support/fake_network.dart` is a
`NetworkService` that answers `reply(method, url, …)` / `replySample(…)` and
records `calls`, so each test runs the real remote data source → repository →
use case → cubit over canned responses. Samples live in `test/api_samples/`:

- `betouti/` — **captured from the live Betouti API** (home, categories,
  countries, governorates, the auth 422s, a 401, a guest 500). Re-capture
  rather than hand-edit.
- `cloak/` — captured from `cloak.alqudiry-solutions.com`, the sibling app on
  the same Laravel engine (clothing domain, but the same resource structure).
- `<feature>/*.cloak_shape.json` — **hand-written** in the shape `../cloack`'s
  models and live probes read. Everything behind a login is here, because
  there is no Betouti test account.
- `location/*.pdf_guess.json` — hand-written from the backend guide's field
  names; `../cloack` has no location feature.

`test/live_public_probe.dart` is **not** part of `flutter test` (the name
doesn't end in `_test.dart`). Run it by name to check the parsers against
today's live public endpoints: `$F test test/live_public_probe.dart`.

## Current state

All screens run on the live API. Known gaps and deliberate departures:

- **Nothing behind a login has been exercised against the real server.**
  Cart, checkout, orders, wishlist, notifications, `/auth/me`, the profile
  update, location
  context and the success answers of register/login/verify-otp follow
  `../cloack` or the guide, not a captured Betouti response.
- **Sign-in and a browsing location are required before any tab.** Betouti's
  `/products` and `/stores` answer **500 for guests** (a server bug:
  `LocationContextService::getRequiredActiveLocation()` gets a null user).
  The backend also runs with debug on — 500s leak PHP stack traces; core maps
  every 5xx to `server_error` so none reaches the screen.
- **SMS is stubbed on the backend**: `request-otp` answers `data: null` and
  puts the code in `message` (`"… demo otp :833801"`). `OtpChallengeModel`
  reads it into `demoCode` and `OtpPage` shows it as a test-code note.
  **Remove that note before release.** Codes are 6 digits.
- **Countries**: the backend lists only Egypt today. The app supports Kuwait
  and Egypt (`core/utils/market.dart`): the phone field offers both, prices
  follow the chosen country (KWD 3 decimals, EGP 2).
- **Addresses** (`features/addresses`): the book at `/profile/addresses`
  lists, edits (`PUT`), deletes and sets the default (`PATCH …/default`); the
  form at `…/addresses/new` creates (`POST`, every key sent, blank optionals
  as `null`, phone in E.164 with `+`, country `Kuwait`/`Egypt`). Checkout
  reads `GET /addresses` itself and, with none, offers "Add address", which
  pushes `/cart/addresses/new`.
- **Orders**: checkout may create one order per store and opens the first;
  the full list is `/profile/orders` (`OrdersPage`, paged `GET /orders`).
  `OrderPage.latest` (the newest order) is only a fallback when checkout's
  answer names no order. Order lines may come without an image: checkout
  passes the cart lines' photos (`{productId: ImageRef}`) as the route's
  `extra`, and `OrderItemsSection` uses one when a line has none. An order
  opened from the list or a notification gets no photos, so those lines keep
  the placeholder.
- **Cancelling an order**: `OrderPage` offers "Cancel order" (behind a confirm
  sheet) while the status is `pending` or `confirmed`, i.e. until the family
  starts preparing it (`OrderStatus.isCancellable`); the server stays the
  authority and its
  refusal reaches a toast. It is `PATCH orders/{id}/cancel` with no body
  (probed 2026-09-28: PATCH answers a guest 401, POST a 405). Its success
  answer is uncaptured, so an answer without `order_number` is followed by
  `GET orders/{id}`, as `../cloack` does. `OrdersPage` re-reads its first page
  whenever an opened order is popped, so a cancelled status shows in the list.
- **Checkout** posts `{address_id, payment_method: cash_on_delivery, notes?}`
  to `orders/checkout`. `payment_method` is required (a 422 without it, seen
  2026-09-28); the backend also takes `card`, but the app has no payment
  picker, so cash on delivery is fixed in `PlaceOrderRequest.toJson`.
- **Add to cart** sends `{product_id, quantity}`. `../cloack` also sends
  `product_color_id`/`product_variant_id`; the food fork is assumed not to.
- **All stores**: the trusted-stores section on Home has a "Show all" text
  button beside its title (`HomeSection.actionLabel`/`onAction`) that pushes
  `/home/families`
  (`StoresPage`, `GET /stores`, captured in `test/api_samples/betouti/
  stores.json`). Betouti answers it as a bare `data` list with no
  `links`/`meta`, so it is read as one page, not paged; items carry `logo` and
  `banner` (no `_url`) and no `is_trusted`, so the card shows no verified
  badge and falls back to the description. It lives in the `home` feature
  because it reuses `TrustedStore` and `TrustedStoreCard`; like Home it
  reloads when the browsing location moves.
- **Removed, no backend**: coupons, order rating, following a family,
  search suggestions, device registration, the exhibition banner and its QR.
- **Explore** has no endpoint: tabs are New (`sort=newest`), Featured
  (`featured=1`) and Lowest price (`sort=price_asc`) over `GET /products`.
  Search is `GET /products?search=&category=<slug>&sort=`; `/products`
  validates `sort` to `newest|oldest|price_asc|price_desc|name_asc|name_desc`
  (`top_rated` is a 422) and `per_page` ≤ 100.
- **Notifications** carry only `entity`/`entity_id`, so product and store
  notifications can't open their page (routes need a slug); orders do.
- **Profile rows** open their own screens under the profile tab — Edit
  profile (`/profile/edit`), My orders
  (`/profile/orders`), Favourites (`/profile/favourites`, the wishlist rows'
  products), Addresses (`/profile/addresses`), Notifications. The design had
  them open stand-ins. "Support" is hidden until there is a destination (no
  endpoint, no contact details).
- **Changing the browsing location**: the "Delivery area" profile row pushes
  the root `/location?from=/profile` (the same manual picker shown after
  sign-in). The backend also accepts `{mode: auto, latitude, longitude}`; the
  app doesn't use it (no geolocation package). Home, Explore and Search stay
  mounted in the shell, so each listens to `LocationCubit` and reloads when
  `LocationContext.movedFrom` the previous one — a switch between two set
  areas only, so the first context after sign-in doesn't double-load them.
- **`POST /auth/refresh` does not exist**: a 401 on a call sent with the
  stored token ends the session.
- **One client-side price calculation**, a preview: the product bar's line
  total (price × quantity). The cart falls back to summing lines only when
  the server omits its summary.
- **Edit profile** (`EditProfilePage`, `features/profile`) changes the name,
  the email and the photo through `PATCH auth/profile`. It never sends
  `phone`: on `../cloack`'s engine that answers a 422 ("The phone field is
  prohibited"), because the number is the OTP-verified sign-in identity. The
  email is optional in the form and goes out as shown, so a blank one is
  sent as `""`, which the server reads as clearing it. Without a new photo
  the body is JSON on a `PATCH`; with one it is `multipart/form-data` with
  the file under `avatar`, sent as a `POST` carrying `_method=PATCH` because
  PHP parses a multipart body only on POST (`core/network/multipart_body.dart`,
  as `../baytoti_vendor` does). The `avatar` key comes from the user, not a
  probe: `../cloack`'s endpoint took name and email only, so an ignored photo
  is the first thing to check on the real server. The success answer is
  uncaptured; one that carries no account is followed by `GET auth/me`.
- **The saved account is in memory only**: the edit page hands it to
  `AuthCubit.updateCustomer`, and `ProfilePage` shows `AuthCubit`'s customer
  before its own `auth/me` read, so the change shows at once. The copy cached
  for session restore is not rewritten; the profile page re-reads `auth/me`
  whenever it opens.
- **Photos** are picked by `pickGalleryPhoto` (`core/utils/photo_picker.dart`,
  `image_picker`), a platform call with no repository in front of it, so its
  `PlatformException` is caught there in presentation and becomes a toast;
  choosing nothing is `null`, not an error. No permission is requested: on
  Android the system Photo Picker (`useAndroidPhotoPicker`) hands over only
  the chosen photo, so no storage permission is declared; on iOS the picker
  runs outside the app and, without `requestFullMetadata`, never asks for
  the library. `NSPhotoLibraryUsageDescription` is in `Info.plist` only
  because the App Store requires it. Photos are scaled on the device to
  1024px at quality 85, since the server's size limit is unknown.
  `EditProfileForm` and `AuthForm` (sign-up only, optional) take the picker
  as `onPickPhoto` so tests can stand in for it.
- The auth header has a back button the design omits.

## The API contract, as core reads it

Sources, in order of trust: live responses from
`https://betouti.alqudiry-solutions.com/api/v1/` (probed 2026-09-27),
`Betouti_Mobile_API_Integration_Guide_v1.0.pdf` (the backend team's guide),
and `../cloack` — the same Laravel engine at `cloak.alqudiry-solutions.com`,
whose models and `test/live_*_probe.dart` document the authenticated shapes.

- **Base URL** `https://betouti.alqudiry-solutions.com/api/v1/`
  (`core/utils/constants.dart`, trailing slash required). Every path is in
  `ApiEndPoint`, which lists only routes confirmed to exist on Betouti.
- **Envelope** `{success, message, data, errors}`. `ApiResponse.json` returns
  `data` when it is an object, else the whole envelope (so lists read
  `json['data']` next to `json['meta']`); `ApiResponse.message` is the text.
  401s are a bare `{"message": "Unauthenticated."}`.
- **Errors**: non-2xx or `success: false` throws `RequestException(message,
  errors)`; `errors` is Laravel's `{field: [message]}` and makes a
  `ValidationFailure`. Any 5xx becomes `server_error`. There is **no stable
  error code** — branch on the field, never on `Failure.code`.
- **Ids are ints** on the wire, Strings in the domain (`jsonId`). Read every
  field leniently with `core/utils/json.dart` (`jsonId`, `jsonString`,
  `jsonBool` — flags arrive as `true`/`1`/`"1"`, `jsonCount`) — never a hard
  `as` cast on a payload.
- **Products and stores are addressed by slug** (`products/{slug}`,
  `stores/{slug}`, `products?store=<slug>`, `?category=<slug>`); the id is for
  the cart and wishlist. `ProductSummary`/`FamilyRef`/`Category` carry both,
  and `context.openProduct(slug)` / `openFamily(slug)` take the slug.
  Reviews are the exception: `products/{productId}/reviews` takes the id.
- **Money** arrives as decimal strings (`"55.000"`), under `price{current,
  original}` or `base_price`/`compare_price` (`PriceModel.read` takes
  either). `Money.parse` stores thousandths of the major unit in `fils`;
  `display` formats at build time with the static `Money.languageCode` (set
  from the locale in `App.build`) and `Money.market` (set from the location
  context). No server display strings exist.
- **Lists** are Laravel pages: `{data, links, meta: {current_page, last_page,
  per_page, total}}` → `Paged.fromJson` (`hasMore` is `currentPage <
  lastPage`; query `page: paged.nextPage`).
- **Phones** go out as digits with the country code (`wirePhone`:
  `96551502244`), come back the same way; `displayPhone` groups KW and EG.
- **Auth** is password-based with a phone check on top, which departs from the
  design's phone-only screens (the user chose this): signup `register {name,
  email, phone, password, password_confirmation}` (answers the user, token
  `null`; with the optional sign-up photo the same keys go out as a
  multipart `POST` with the file under `avatar`, a key the user asked for
  and no probe has confirmed) → `request-otp {phone}` → `verify-otp {phone, otp}` (issues the
  token). Login `login {login, password}`: a verified account with a token
  signs in with no code; an unverified one keeps its token pending and goes
  through `request-otp`/`verify-otp`. `AuthOutcome` (`SignedIn` /
  `AwaitingVerification`) is the repository's result; `verify-otp` may answer
  a token, a user, both or neither, and the repository fills the gaps from
  the pending login/register.
- **Location**: `GET /countries`, `/countries/{id}/governorates` (public),
  `GET|POST /location/context` (`{mode: manual, country_id,
  governorate_id}`). `LocationCubit` (app-wide) reads the context whenever a
  session starts and reports it through `SessionNotifier.locationKnown`;
  the chosen country's code is cached locally for the market.
- **Locale** goes out as the bare app language, `Accept-Language: ar|en`.
  The backend ignores it: `/home` answers the same Arabic content either way
  (checked 2026-09-28), so catalog text stays Arabic in the English UI.
- **The cart is server-owned**: every mutation answers the recalculated cart,
  or the app re-reads `GET /cart`.

## Architecture

Clean architecture per feature under `lib/features/<name>/`:
`data/` + `domain/` + `presentation/`. Data flows one way: **data source →
repository → use case → cubit → widget**. A cubit depends on use cases, never
on a repository. Only the data layer knows about HTTP or storage; everything
above sees `Either<Failure, T>` (dartz).

Features: `catalog` (shared product/family/category/totals entities and
models, favourites/wishlist, `ProductCard`), `auth`, `location`, `home`,
`explore`, `search`, `product`, `family`, `cart`, `checkout`, `orders`,
`notifications`, `profile`, `shell` (the tab bar). A feature may import
another feature's `domain` entities and `catalog`; it never imports another
feature's `data` from `presentation`. `ProductCard` reads `CartCubit`
through the cart's `CartQuantityControl`: a product already in the cart
shows a compact stepper in place of the add button (minus at one removes
the line), so anything that pumps a card needs a `CartCubit`
(`test/support/cart_harness.dart`).

### Dependency injection

`get_it` as `sl`, wired once by `initDependencies()` in
`core/di/injection_container.dart` (a `part of` `di_exports.dart`). A feature
adds its own `_registerXFeature()` there. `registerSingleton` for core
services, `registerLazySingleton` for data sources, repositories, use cases
and app-wide cubits, `registerFactory` for one cubit per screen. Each data
source is `XRemoteDataSource(sl<NetworkService>())`.

App-wide cubits, provided in `core/app/app.dart`: `NetworkCubit`, `AuthCubit`
(the signed-in customer; the only thing that calls
`SessionNotifier.signedIn()`/`signedOut()`), `CartCubit` (the tab badge;
loads when a session starts and empties when it ends, by listening to
`SessionNotifier`) and `LocationCubit` (the browsing context and market,
also driven by `SessionNotifier`). State that belongs to an account follows
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
  react to *its own* outcome — `CartCubit.add`, `setQuantity` and `remove` —
  returns `Future<Failure?>` and leaves `errorMessage` alone, because every
  page under the shell stays mounted and a state listener would fire on all
  of them. Call them through `cart_actions.dart` (`addToCart`,
  `setCartQuantity`, `removeFromCart`), which toast the failure.

`mapExceptionToFailure` is where a message becomes displayable: above it,
`Failure.message` is always safe to show. Any sentinel used as a message
(`fallbackMessage`, `messageForStatus`) needs an entry in
`assets/translations/` and in `errorMessageKeys` in
`test/translations_test.dart`.

### Routing

One `GoRouter` in `core/routing/app_router.dart`, paths in `routes.dart`. Five
tabs in a `StatefulShellRoute`: `/home`, `/explore`, `/search`, `/cart`,
`/profile`. **Detail screens nest under the tab they were opened from** —
`/explore/families/mtbkh-amyr-1`, `/cart/checkout`, `/profile/orders/41` —
so the tab bar stays, as the design draws it, and back stays inside the tab.
Open them with the `AppNavigation` extension (`context.openProduct(slug)`,
`openFamily`, `openOrder`, `openNotifications`, `pushInTab(segment)`), which
prefixes the current tab. Tapping a tab always opens its root page
(`goBranch(index, initialLocation: true)`), never the detail screen left open
in it. The shell hides the tab bar on product pages, the one screen the
design draws without it. `/welcome`, `/auth` and `/otp` are
root routes for guests; `/location` is a root route for members.

The guard reads `SessionNotifier`. **Everything except `/welcome`, `/auth`
and `/otp` needs an account**: a guest is sent to `/auth?from=<location>` and,
once verified, back to `from`. A member whose location is known to be unset
is sent to `/location?from=<location>` (`redirectForLocation`); while it is
still loading nobody is redirected. `test/route_guard_test.dart` asserts
every registered path is classified. `requireSignIn(context)` /
`addToCart(context, …)` in `features/cart/presentation/cart_actions.dart`
remain for actions that need an account.

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
- Page kickers (`kicker_*`, the small line above each title) follow the app
  language; the design printed them in the other language on purpose, and
  that was changed at the user's request.
- Type: `AppStrings.w800(13, 1.3)` is `font: 800 13px/1.3` — Archivo with IBM
  Plex Sans Arabic as fallback. Color at the call site: `.c(p.text)`.
  Letter-spacing (`.spaced`) never goes on Arabic; `SectionLabel` tracks
  Latin only.
- Icons: `AppIcon(AppIcons.bell, …)` renders the design's own SVG paths
  (`flutter_svg`); directional ones mirror in RTL.
- Shared widgets in `core/widgets/`: `AppHeader`, `HeaderIconButton`,
  `AppButton`, `SectionLabel`, `SectionHeading`, `QuantityStepper`,
  `StatGrid`, `PillChip`/`ChipStrip`, `LabeledField`/`AppTextField`
  (`obscureText` for passwords), `PhoneTextFormField` (`intl_phone_number_input`,
  Kuwait and Egypt), `EmptyState`, `LoadingView`/`ErrorView`, `NetworkPhoto`
  (an empty image list shows the design's neutral placeholder),
  `AvatarPhoto` (round; a URL, a picked file or a person icon) and
  `AvatarPicker` (it with a "+" badge and a label to tap),
  `PagedScrollListener`, `showAppToast`, `showConfirmSheet`, brand marks.

**Cubits** extend `BaseCubit`. A state's `copyWith` **clears**
`errorMessage` unless passed again. **Errors are shown in a toast**
(`showAppToast(context, message, isError: true)`); inside a bottom sheet use
`SheetErrorNote`.

Paginated lists: `PagedScrollListener(isLoading:, onEndOfPage:, child:)`
over one scrollable; the cubit guards `loadMore` (in flight / no more pages),
keeps a generation counter, and keeps the list when a next page fails. Search
boxes that hit the server debounce in the cubit with rxdart
(`debounceTime(500ms).distinct()`), and query objects omit absent values.

## Localization

`easy_localization`, Arabic and English, Arabic by default and RTL. Keys in
`assets/translations/{en,ar}.json` — **both files hold the same key set**
(`test/translations_test.dart`). User-facing chrome is always `'key'.tr()`.
Switch language only through `LocalizationService.change`, which updates the
UI locale and the `Accept-Language` the API is sent.

Phone numbers are Kuwaiti (`+965`, eight digits) or Egyptian (`+20`, ten
digits): `PhoneTextFormField` offers both and reports E.164, the auth data
source sends `wirePhone` digits. The design pinned `+965` only.
