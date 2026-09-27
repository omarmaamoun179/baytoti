---
name: flutter-test-generator
description: >
  Generate comprehensive unit, widget, and BLoC/Cubit tests for Flutter features following Clean
  Architecture patterns. Use this skill whenever the user asks to write tests, generate tests,
  create test files, add test coverage, or mentions "unit test", "widget test", "bloc test",
  "cubit test", "test coverage", "mock", "mocktail", "mockito", "bloc_test", or "test this".
  Also trigger when the user says "add tests for this feature", "test the use case", "I need tests",
  "cover this with tests", or any request involving Flutter/Dart testing. Trigger even for implicit
  testing requests like "make sure this works" or "verify this cubit" in a Flutter context.
  This skill generates tests that follow the Arrange-Act-Assert pattern, use proper mocking,
  and cover both happy paths and edge cases — the stuff that gets skipped under deadline pressure.
---

# Flutter Test Generator

Generate structured, comprehensive tests for Flutter features following Clean Architecture + BLoC/Cubit patterns.

## Project Conventions (Rolli_app)

This repo already has the stack wired up — assume the following unless the file under test clearly deviates:

| Concern | Project convention |
|---------|-------------------|
| Mocking | `mocktail` (no codegen) |
| BLoC/Cubit tests | `bloc_test` |
| Equality | `equatable` (states/entities extend `Equatable` with sealed hierarchies) |
| Functional error type | `dartz` — `Either<ServerException, T>` via `DioClient`. Inspect the SUT's return type to confirm. |
| Freezed | Not used — states are hand-written sealed classes with `Equatable`. |
| DI | `get_it` via `sl` — in tests, instantiate the SUT directly with mocks; do not touch `sl`. |
| Cubit base class | Most cubits extend `BaseCubit<T>` (`core/abstract/base_cubit.dart`). This is transparent for tests. |

Use `ServerException` (from `core/error/exceptions.dart`) as the error type. Do not reference `Failure`, `ServerFailure`, `ServerException`, or `GraphResult` — those are not part of this project.

## Test File Structure

Mirror the source structure under `test/`:

```
test/features/<feature_name>/
├── data/
│   ├── models/
│   │   └── <feature>_model_test.dart
│   ├── data_sources/
│   │   └── <feature>_remote_data_source_test.dart
│   └── repositories/
│       └── <feature>_repository_impl_test.dart
├── domain/
│   └── use_cases/
│       └── get_<feature>_test.dart
└── presentation/
    ├── cubit/
    │   └── <feature>_cubit_test.dart
    └── pages/
        └── <feature>_page_test.dart       # widget test (optional)
```

## Generation Strategy

### Step 1: Identify the SUT (System Under Test)

The user may provide:
- A single file → generate tests for that file
- A feature directory → generate tests for all layers
- A cubit/bloc only → generate cubit tests + use case tests

### Step 2: Generate Mocks

At the top of each test file, generate mocks for all dependencies:

```dart
// Using mocktail
import 'package:mocktail/mocktail.dart';

class MockGetUserProfile extends Mock implements GetUserProfile {}
class MockUserProfileRepository extends Mock implements UserProfileRepository {}
```

If `mockito` is used instead:
```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([GetUserProfile, UserProfileRepository])
import '<feature>_cubit_test.mocks.dart';
```

### Step 3: Generate Tests by Layer

---

### A. Use Case Tests

Pattern: verify the use case delegates to the repository correctly.

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// imports...

void main() {
  late GetUserProfile useCase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    useCase = GetUserProfile(mockRepository);
  });

  group('GetUserProfile', () {
    const tUserId = 'user-123';
    const tUserProfile = UserProfileEntity(
      id: tUserId,
      name: 'John Doe',
      email: 'john@example.com',
    );

    test('should return UserProfileEntity from repository on success', () async {
      // Arrange
      when(() => mockRepository.getUserProfileById(tUserId))
          .thenAnswer((_) async => const Right(tUserProfile));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Right(tUserProfile));
      verify(() => mockRepository.getUserProfileById(tUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerException when repository fails', () async {
      // Arrange
      final tException = ServerException(message: 'Server error');
      when(() => mockRepository.getUserProfileById(tUserId))
          .thenAnswer((_) async => Left(tException));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, Left(tException));
    });
  });
}
```

**Coverage requirements**:
- ✅ Happy path (returns data)
- ✅ Failure path (returns `Left(ServerException)`)
- ✅ Verify repository called exactly once
- ✅ Verify no other interactions

---

### B. Cubit/BLoC Tests

Use `bloc_test` package for declarative state assertions.

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// imports...

void main() {
  late UserProfileCubit cubit;
  late MockGetUserProfile mockGetUserProfile;

  setUp(() {
    mockGetUserProfile = MockGetUserProfile();
    cubit = UserProfileCubit(getUserProfile: mockGetUserProfile);
  });

  tearDown(() => cubit.close());

  test('initial state is UserProfileInitial', () {
    expect(cubit.state, isA<UserProfileInitial>());
  });

  group('fetchUserProfile', () {
    const tUserId = 'user-123';
    const tProfile = UserProfileEntity(
      id: tUserId,
      name: 'John Doe',
      email: 'john@example.com',
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'emits [Loading, Loaded] when fetch succeeds',
      build: () {
        when(() => mockGetUserProfile(tUserId))
            .thenAnswer((_) async => const Right(tProfile));
        return cubit;
      },
      act: (cubit) => cubit.fetchUserProfile(tUserId),
      expect: () => [
        isA<UserProfileLoading>(),
        isA<UserProfileLoaded>().having((s) => s.data, 'data', tProfile),
      ],
      verify: (_) {
        verify(() => mockGetUserProfile(tUserId)).called(1);
      },
    );

    blocTest<UserProfileCubit, UserProfileState>(
      'emits [Loading, Error] when fetch fails',
      build: () {
        when(() => mockGetUserProfile(tUserId))
            .thenAnswer((_) async => Left(ServerException(message: 'Server error')));
        return cubit;
      },
      act: (cubit) => cubit.fetchUserProfile(tUserId),
      expect: () => [
        isA<UserProfileLoading>(),
        isA<UserProfileError>().having((s) => s.message, 'message', 'Server error'),
      ],
    );
  });
}
```

**Coverage requirements**:
- ✅ Initial state assertion
- ✅ Happy path: Loading → Loaded (verify data)
- ✅ Error path: Loading → Error (verify message)
- ✅ Verify use case called
- ✅ tearDown closes cubit

**Additional edge case tests to generate when applicable**:
- Multiple rapid calls (debounce behavior)
- Empty data returns
- Null fields in entity
- Network timeout simulation

---

### C. Repository Impl Tests

Verify the repository delegates to data source and maps models to entities.

```dart
void main() {
  late UserProfileRepositoryImpl repository;
  late MockUserProfileRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockUserProfileRemoteDataSource();
    repository = UserProfileRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getUserProfileById', () {
    const tUserId = 'user-123';
    const tModel = UserProfileModel(id: tUserId, name: 'John', email: 'j@x.com');

    test('should return entity when data source succeeds', () async {
      when(() => mockDataSource.getUserProfileById(tUserId))
          .thenAnswer((_) async => tModel);

      final result = await repository.getUserProfileById(tUserId);

      expect(result, isA<Right>());
      result.fold(
        (_) => fail('should be Right'),
        (entity) {
          expect(entity.id, tUserId);
          expect(entity.name, 'John');
        },
      );
    });

    test('should return ServerException when data source returns Left', () async {
      when(() => mockDataSource.getUserProfileById(tUserId))
          .thenAnswer((_) async => Left(ServerException(message: '500')));

      final result = await repository.getUserProfileById(tUserId);

      expect(result, isA<Left>());
    });
  });
}
```

---

### D. Model Tests

```dart
void main() {
  group('UserProfileModel', () {
    const tModel = UserProfileModel(id: '123', name: 'John', email: 'j@x.com');

    test('fromJson creates correct model', () {
      final json = {'id': '123', 'name': 'John', 'email': 'j@x.com'};
      final result = UserProfileModel.fromJson(json);
      expect(result, tModel);
    });

    test('toJson returns correct map', () {
      final result = tModel.toJson();
      expect(result, {'id': '123', 'name': 'John', 'email': 'j@x.com'});
    });

    test('fromJson handles null optional fields gracefully', () {
      final json = {'id': '123', 'name': 'John', 'email': null};
      // Behavior depends on field nullability
      expect(() => UserProfileModel.fromJson(json), returnsNormally);
    });
  });
}
```

---

### E. Widget Tests (Optional — generate when user asks)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileCubit extends MockCubit<UserProfileState>
    implements UserProfileCubit {}

void main() {
  late MockUserProfileCubit mockCubit;

  setUp(() {
    mockCubit = MockUserProfileCubit();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider<UserProfileCubit>.value(
        value: mockCubit,
        child: const UserProfilePage(),
      ),
    );
  }

  testWidgets('shows loading indicator when state is Loading', (tester) async {
    when(() => mockCubit.state).thenReturn(UserProfileLoading());

    await tester.pumpWidget(buildWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows profile data when state is Loaded', (tester) async {
    const profile = UserProfileEntity(id: '1', name: 'John', email: 'j@x.com');
    when(() => mockCubit.state).thenReturn(const UserProfileLoaded(profile));

    await tester.pumpWidget(buildWidget());

    expect(find.text('John'), findsOneWidget);
  });

  testWidgets('shows error message when state is Error', (tester) async {
    when(() => mockCubit.state).thenReturn(const UserProfileError('Oops'));

    await tester.pumpWidget(buildWidget());

    expect(find.text('Oops'), findsOneWidget);
  });
}
```

---

## Output Rules

1. **Generate all test files** — don't just show one example and say "do the same for others"
2. **Use test data constants** — define `tModel`, `tEntity`, `tId` at the top of each group for reuse
3. **Include `registerFallbackValue`** if using mocktail with custom types:
   ```dart
   setUpAll(() {
     registerFallbackValue(FakeUserProfileEntity());
   });
   ```
4. **Group tests logically** — one `group()` per method/behavior
5. **Name tests descriptively** — `'should return Left(ServerException) when repository fails'` not `'test 1'`
6. **Always close Cubits/BLoCs** in `tearDown`

## After Generation

Provide:
- List of test files created
- How to run: `flutter test test/features/<feature>/`
- Any missing dependencies to add to `dev_dependencies` in `pubspec.yaml`
- Coverage command: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`
