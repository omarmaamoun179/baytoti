---
name: flutter-api-generator
description: >
  Generate the full Clean Architecture data pipeline from a REST API endpoint definition. Use when
  the user provides a REST endpoint, API schema, JSON response, or Postman collection and wants
  the corresponding model, data source, repository, and use case generated.
  Trigger on "generate api", "integrate endpoint", "add api call", "wire up this endpoint",
  "create data layer for", "fromJson for this", "connect to this api", or when the user pastes
  a JSON response and asks to integrate it. Also trigger if they say "I have this API" or
  "backend gave me this endpoint".
allowed-tools: Read, Write, Glob, Grep, Bash
---

# API Integration Generator

Generate the complete Clean Architecture data pipeline from an API endpoint definition.

## Input Formats

The user may provide any of these:
- **REST endpoint** (method + URL + response JSON)
- **JSON response sample**
- **Swagger/OpenAPI spec**
- **Verbal description** ("there's an endpoint that returns a list of schools with name, address, rating")

## Process

### Step 1: Parse the API Contract

Extract:
- **Operation type**: GET / POST / PUT / PATCH / DELETE
- **Endpoint**: e.g., `GET /api/v1/schools/{id}`, `POST /api/v1/bookings`
- **Request params**: path params, query params, request body
- **Response shape**: all fields with types, nested objects, lists
- **Nullable fields**: which fields can be null
- **Pagination**: is it paginated? Cursor or offset?

If anything is ambiguous, make a reasonable assumption and note it.

### Step 2: Detect Project Patterns

Before generating, read the existing codebase to match conventions:

```bash
# Find an existing model to match pattern
find lib/features -name '*_model.dart' -not -name '*.g.dart' | head -3

# Find existing data source to match pattern  
find lib/features -name '*_remote_data_source.dart' -o -name '*_remote_datasource.dart' | head -3

# Find existing repository impl
find lib/features -name '*_repository_impl.dart' | head -3

# Check error handling pattern
grep -r 'ServerException\|Either\|DioException' lib/core/ --include='*.dart' | head -5

# Check API client
find lib/core -name '*dio*' -o -name '*client*' -o -name '*api*' | head -5
```

Read 1-2 of these files to understand:
- How `fromJson` is written (factory constructor vs static method vs json_serializable)
- How data sources call the API (Dio, http, GraphQL client)
- Error handling pattern (try/catch → Either, GraphResult, etc.)
- Whether `toJson` is needed (for mutations/POST)

### Step 3: Generate Files

Generate in this exact order (dependency order):

---

#### 3a. Entity (domain/entities/)

Pure Dart class. No JSON, no framework dependencies.

```dart
import 'package:equatable/equatable.dart';

class SchoolProfileEntity extends Equatable {
  final String id;
  final String name;
  final String? address;
  final double rating;
  final List<SchoolBranchEntity> branches;

  const SchoolProfileEntity({
    required this.id,
    required this.name,
    this.address,
    required this.rating,
    required this.branches,
  });

  @override
  List<Object?> get props => [id, name, address, rating, branches];
}
```

**Rules:**
- Use `required` for non-nullable fields
- Use `this.field` shorthand for nullable fields
- Extend `Equatable` with ALL fields in `props`
- Nested objects → separate entity class
- Lists → `List<ChildEntity>`

---

#### 3b. Model (data/models/)

Extends entity. Adds JSON serialization.

```dart
import '../../domain/entities/school_profile_entity.dart';
import 'school_branch_model.dart';

class SchoolProfileModel extends SchoolProfileEntity {
  const SchoolProfileModel({
    required super.id,
    required super.name,
    super.address,
    required super.rating,
    required super.branches,
  });

  factory SchoolProfileModel.fromJson(Map<String, dynamic> json) {
    return SchoolProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      rating: (json['rating'] as num).toDouble(),
      branches: (json['branches'] as List<dynamic>?)
          ?.map((e) => SchoolBranchModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'branches': (branches as List<SchoolBranchModel>)
          .map((e) => e.toJson())
          .toList(),
    };
  }
}
```

**Type mapping rules:**
| API Type | Dart Type | fromJson Cast |
|---|---|---|
| String | `String` | `as String` |
| String? | `String?` | `as String?` |
| Int | `int` | `as int` |
| Float/Double | `double` | `(json['x'] as num).toDouble()` |
| Boolean | `bool` | `as bool` |
| ID | `String` | `as String` |
| List<T> | `List<T>` | `(json['x'] as List).map(...)` |
| Nested Object | `ChildModel` | `ChildModel.fromJson(json['x'])` |
| Nullable List | `List<T>` | `(json['x'] as List?)?.map(...) ?? []` |
| DateTime | `DateTime` | `DateTime.parse(json['x'] as String)` |
| Enum | `MyEnum` | `MyEnum.values.byName(json['x'])` |

**Generate `toJson` only if:**
- The endpoint is a mutation/POST/PUT
- The user explicitly asks for it
- The model is used as request body

---

#### 3c. Data Source (data/datasources/)

Abstract + implementation. Match the project's existing API client.

```dart
// Abstract
abstract class SchoolProfileRemoteDataSource {
  Future<SchoolProfileModel> getSchoolProfile(String id);
  Future<List<SchoolProfileModel>> getSchoolProfiles({int page, int limit});
}

// Implementation using Dio
class SchoolProfileRemoteDataSourceImpl implements SchoolProfileRemoteDataSource {
  final DioClient _client;

  SchoolProfileRemoteDataSourceImpl(this._client);

  @override
  Future<SchoolProfileModel> getSchoolProfile(String id) async {
    final response = await _client.get('/api/v1/schools/$id');
    return SchoolProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
```

---

#### 3d. Repository Contract (domain/repositories/)

```dart
abstract class SchoolProfileRepository {
  Future<Either<ServerException, SchoolProfileEntity>> getSchoolProfile(String id);
  Future<Either<ServerException, List<SchoolProfileEntity>>> getSchoolProfiles({
    int page = 1,
    int limit = 20,
  });
}
```

**Error type is `Either<ServerException, T>`** — `ServerException` lives in `core/error/exceptions.dart`.

---

#### 3e. Repository Implementation (data/repositories/)

```dart
class SchoolProfileRepositoryImpl implements SchoolProfileRepository {
  final SchoolProfileRemoteDataSource _remoteDataSource;

  SchoolProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<ServerException, SchoolProfileEntity>> getSchoolProfile(String id) async {
    try {
      final model = await _remoteDataSource.getSchoolProfile(id);
      return Right(model);
    } on ServerException catch (e) {
      return Left(e);
    } on DioException catch (e) {
      return Left(ServerException(e.message ?? 'Network error'));
    } catch (e) {
      return Left(ServerException(e.toString()));
    }
  }
}
```

---

#### 3f. Use Case (domain/usecases/)

```dart
class GetSchoolProfile {
  final SchoolProfileRepository _repository;

  GetSchoolProfile(this._repository);

  Future<Either<ServerException, SchoolProfileEntity>> call(String id) {
    return _repository.getSchoolProfile(id);
  }
}
```

Match the project's use case pattern — some projects have a base `UseCase<Output, Params>` class, others use plain classes with `call()`.

---

### Step 4: Generate Child Models

If the response has nested objects, generate entity + model pairs for each:
- Detect nested objects and lists in the JSON
- Generate in dependency order (deepest nesting first)
- Place in the same feature's `models/` and `entities/` directories

### Step 5: DI Registration Snippet

Generate the registration code for the project's DI container:

```dart
// Add to injection_container.dart or init<Feature>Feature()
sl.registerLazySingleton<SchoolProfileRemoteDataSource>(
  () => SchoolProfileRemoteDataSourceImpl(sl()),
);
sl.registerLazySingleton<SchoolProfileRepository>(
  () => SchoolProfileRepositoryImpl(sl()),
);
sl.registerFactory(() => GetSchoolProfile(sl()));
```

### Step 6: Summary

```
## Generated Files

### Domain Layer
- entities/school_profile_entity.dart
- entities/school_branch_entity.dart
- repositories/school_profile_repository.dart
- usecases/get_school_profile.dart

### Data Layer
- models/school_profile_model.dart
- models/school_branch_model.dart
- datasources/school_profile_remote_datasource.dart
- repositories/school_profile_repository_impl.dart

### DI Registration
[snippet to add to injection_container.dart]

### Next Steps
- Wire cubit to use case
- Add route to page
- Generate tests with /flutter-test-generator
```
