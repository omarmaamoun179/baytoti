---
name: flutter-feature-scaffolder
description: >
  Scaffold a complete Flutter feature module following Clean Architecture + BLoC/Cubit patterns.
  Use this skill whenever the user asks to create a new feature, screen, module, or page in a Flutter project,
  or mentions "scaffold", "generate feature", "new feature", "add screen", "create module", "BLoC feature",
  "Cubit feature", or any request that involves generating the folder structure and boilerplate files for a
  Flutter feature. Also trigger when the user says things like "I need a login page", "build me an orders feature",
  or "set up the profile module". Even if the user just names a feature casually like "add a settings screen",
  use this skill. This skill ensures consistent architecture across the entire codebase.
---

# Flutter Feature Scaffolder — Rolli_app

Generate a complete, production-ready Flutter feature module aligned with the conventions documented in this repo's `CLAUDE.md`.

## Architecture Layers

Every feature follows this exact structure (matches existing features like `booking`, `new_cart`, `new_profile`):

```
lib/features/<feature_name>/
├── data/
│   ├── models/
│   │   └── <feature>_model.dart                 # json_serializable + .toEntity()
│   ├── datasources/                             # NOTE: no underscore
│   │   └── <feature>_remote_data_source.dart
│   └── repositories/
│       └── <feature>_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── <feature>_entity.dart                # pure Dart, Equatable
│   ├── repositories/
│   │   └── <feature>_repository.dart            # abstract contract
│   └── usecases/                                # NOTE: no underscore
│       └── <verb>_<feature>_usecase.dart        # suffix `_usecase` is the project norm
└── presentation/
    ├── cubit/                                   # prefer Cubit; use bloc/ only for complex event flows
    │   ├── <feature>_cubit.dart
    │   └── <feature>_state.dart
    ├── pages/
    │   └── <feature>_page.dart
    └── widgets/
        └── <feature>_body.dart
```

Do **not** generate a barrel file (`<feature>.dart`) — it isn't the repo convention.

## Step-by-Step Process

### 1. Gather Context

Before generating, determine:
- **Feature name** (snake_case): e.g., `user_profile`, `order_history`
- **State management**: default **Cubit**. Only generate BLoC (with events) if the user asks or the feature has complex event sequences.
- **API client**: Use `DioClient` (`core/network/dio_client.dart`) — returns `Either<ServerException, T>`.
- **Entity fields**: ask only if not obvious.

For a simple request like "scaffold a notifications feature", assume sensible defaults (Cubit, `DioClient`, one basic entity) and state the assumptions.

### 2. File Templates

#### Entity — `domain/entities/<feature>_entity.dart`
```dart
import 'package:equatable/equatable.dart';

class <Feature>Entity extends Equatable {
  final String id;
  // ... fields

  const <Feature>Entity({required this.id});

  @override
  List<Object?> get props => [id];
}
```

#### Model — `data/models/<feature>_model.dart`
Uses `json_serializable`. Always provides `.toEntity()` (models live in `data/`, never leak to presentation).
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/<feature>_entity.dart';

part '<feature>_model.g.dart';

@JsonSerializable()
class <Feature>Model {
  final String id;

  const <Feature>Model({required this.id});

  factory <Feature>Model.fromJson(Map<String, dynamic> json) =>
      _$<Feature>ModelFromJson(json);

  Map<String, dynamic> toJson() => _$<Feature>ModelToJson(this);

  <Feature>Entity toEntity() => <Feature>Entity(id: id);
}
```
Remind the user to run: `dart run build_runner build --delete-conflicting-outputs`.

#### Remote data source — `data/datasources/<feature>_remote_data_source.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/<feature>_model.dart';

abstract class <Feature>RemoteDataSource {
  Future<Either<ServerException, <Feature>Model>> get<Feature>ById(String id);
}

class <Feature>RemoteDataSourceImpl implements <Feature>RemoteDataSource {
  final DioClient _client;
  <Feature>RemoteDataSourceImpl(this._client);

  @override
  Future<Either<ServerException, <Feature>Model>> get<Feature>ById(String id) async {
    try {
      final response = await _client.get('/api/v1/<feature>/$id');
      return Right(<Feature>Model.fromJson(response.data as Map<String, dynamic>));
    } on ServerException catch (e) {
      return Left(e);
    }
  }
}
```

#### Repository contract — `domain/repositories/<feature>_repository.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../entities/<feature>_entity.dart';

abstract class <Feature>Repository {
  Future<Either<ServerException, <Feature>Entity>> get<Feature>ById(String id);
}
```

#### Repository impl — `data/repositories/<feature>_repository_impl.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/<feature>_entity.dart';
import '../../domain/repositories/<feature>_repository.dart';
import '../datasources/<feature>_remote_data_source.dart';

class <Feature>RepositoryImpl implements <Feature>Repository {
  final <Feature>RemoteDataSource _remote;
  <Feature>RepositoryImpl(this._remote);

  @override
  Future<Either<ServerException, <Feature>Entity>> get<Feature>ById(String id) async {
    final result = await _remote.get<Feature>ById(id);
    return result.map((model) => model.toEntity());
  }
}
```

#### Use case — `domain/usecases/get_<feature>_usecase.dart`
Project convention: **no shared base class**. Plain class with `call()`.
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../entities/<feature>_entity.dart';
import '../repositories/<feature>_repository.dart';

class Get<Feature>UseCase {
  final <Feature>Repository _repository;
  Get<Feature>UseCase(this._repository);

  Future<Either<ServerException, <Feature>Entity>> call(String id) =>
      _repository.get<Feature>ById(id);
}
```

#### Cubit state — `presentation/cubit/<feature>_state.dart`
```dart
part of '<feature>_cubit.dart';

sealed class <Feature>State extends Equatable {
  const <Feature>State();
  @override
  List<Object?> get props => [];
}

final class <Feature>Initial extends <Feature>State {}
final class <Feature>Loading extends <Feature>State {}

final class <Feature>Loaded extends <Feature>State {
  final <Feature>Entity data;
  const <Feature>Loaded(this.data);
  @override
  List<Object?> get props => [data];
}

final class <Feature>Error extends <Feature>State {
  final String message;
  const <Feature>Error(this.message);
  @override
  List<Object?> get props => [message];
}
```

#### Cubit — `presentation/cubit/<feature>_cubit.dart`
Extends `BaseCubit<T>` (guards emit-after-close).
```dart
import 'package:equatable/equatable.dart';
import '../../../../core/abstract/base_cubit.dart';
import '../../domain/entities/<feature>_entity.dart';
import '../../domain/usecases/get_<feature>_usecase.dart';

part '<feature>_state.dart';

class <Feature>Cubit extends BaseCubit<<Feature>State> {
  final Get<Feature>UseCase _get<Feature>;

  <Feature>Cubit(this._get<Feature>) : super(<Feature>Initial());

  Future<void> fetch<Feature>(String id) async {
    emit(<Feature>Loading());
    final result = await _get<Feature>(id);
    result.fold(
      (err) => emit(<Feature>Error(err.message)),
      (data) => emit(<Feature>Loaded(data)),
    );
  }
}
```

#### Page — `presentation/pages/<feature>_page.dart`
Use required shared widgets: `CustomScaffold` + `ProfileAppBar`. Use `ToastUtils` for feedback (never `ScaffoldMessenger`).
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../new_profile/presentation/widget/profile_header.dart';
import '../cubit/<feature>_cubit.dart';
import '../widgets/<feature>_body.dart';

class <Feature>Page extends StatelessWidget {
  const <Feature>Page({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: ProfileAppBar(
        tittleWidget: const Text('<Feature>'),
        showBackButton: true,
      ),
      body: BlocBuilder<<Feature>Cubit, <Feature>State>(
        builder: (context, state) => switch (state) {
          <Feature>Initial() => const SizedBox.shrink(),
          <Feature>Loading() => const Center(child: CircularProgressIndicator()),
          <Feature>Loaded(:final data) => <Feature>Body(data: data),
          <Feature>Error(:final message) => Center(child: Text(message)),
        },
      ),
    );
  }
}
```

### 3. DI Registration

Project uses `get_it` via `sl` exported from `core/di/di_exports.dart`. Add an `init<Feature>Feature()` function and call it from `core/di/injection_container.dart → init()`.

Create `lib/features/<feature>/<feature>_di.dart` (or register inline in `injection_container.dart` — match what neighbouring features do):
```dart
import '../../core/di/di_exports.dart';
import '../../core/network/dio_client.dart';
import 'data/datasources/<feature>_remote_data_source.dart';
import 'data/repositories/<feature>_repository_impl.dart';
import 'domain/repositories/<feature>_repository.dart';
import 'domain/usecases/get_<feature>_usecase.dart';
import 'presentation/cubit/<feature>_cubit.dart';

void init<Feature>Feature() {
  // Cubit — Factory (per screen)
  sl.registerFactory(() => <Feature>Cubit(sl()));

  // Use cases — LazySingleton
  sl.registerLazySingleton(() => Get<Feature>UseCase(sl()));

  // Repository — LazySingleton
  sl.registerLazySingleton<<Feature>Repository>(
    () => <Feature>RepositoryImpl(sl()),
  );

  // Data source — LazySingleton
  sl.registerLazySingleton<<Feature>RemoteDataSource>(
    () => <Feature>RemoteDataSourceImpl(sl<DioClient>()),
  );
}
```
Registration rules (from CLAUDE.md):
- `registerSingleton` — core services (DioClient, CacheService)
- `registerLazySingleton` — repositories, use cases, persistent cubits
- `registerFactory` — per-screen Blocs/Cubits
- `registerFactoryParam` — Blocs needing constructor parameters

### 4. Routing

Add the route to `AppRoutes` in `core/routing/routes.dart` and wire it into the `go_router` config. Pass data via `state.extra` when needed.

### 5. Styling & Sizing

- Colors: `AppColors` (`core/utils/app_colors.dart`) — do not hardcode.
- Text styles: `AppStrings` (`core/utils/app_strings.dart`).
- Sizing: `SizeConfig` wrapper over `flutter_screenutil`. Design ref 375×812.
- Use `MediaQueryValues` extension over `MediaQuery.of(context)` (project preference).

### 6. Localization

Add Arabic + English keys to `assets/translations/{ar,en}.json` (nested). Use `'section.key'.tr()` or `AppLocalizations.getString()`.

### 7. Output

Write all files. Then summarise:
- Files created.
- DI registration added / pending.
- Route added / pending.
- Translation keys added / pending.
- `build_runner` needed (for `.g.dart`).
- Suggested: generate tests via `flutter-test-generator`.
