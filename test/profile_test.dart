import 'dart:async';

import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/auth/domain/entities/customer.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_data.dart';
import 'package:baytoti/features/profile/data/datasources/profile_data_source.dart';
import 'package:baytoti/features/profile/data/models/profile_model.dart';
import 'package:baytoti/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:baytoti/features/profile/domain/entities/profile.dart';
import 'package:baytoti/features/profile/domain/repositories/profile_repository.dart';
import 'package:baytoti/features/profile/domain/usecases/profile_usecases.dart';
import 'package:baytoti/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:baytoti/features/profile/presentation/cubit/profile_state.dart';
import 'package:baytoti/features/profile/presentation/phone_display.dart';
import 'package:baytoti/features/profile/presentation/widgets/profile_identity.dart';
import 'package:baytoti/features/profile/presentation/widgets/profile_row.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements ProfileRepository {
  Future<Either<Failure, Profile>> Function() answer;
  int calls = 0;

  _FakeRepository(this.answer);

  @override
  Future<Either<Failure, Profile>> getProfile() {
    calls++;
    return answer();
  }
}

const Profile _profile = Profile(
  id: 'usr_18',
  fullName: 'Noura',
  phone: '+96551502244',
  stats: ProfileStats(orderCount: 14, favouriteCount: 23, followingCount: 6),
);

const Failure _offline = NetworkFailure(message: 'You are offline.');

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('the /me contract', () {
    test('the fixture account parses in both languages', () {
      final backend = FixtureBackend();

      for (final lang in ['ar', 'en']) {
        final profile = ProfileModel.fromJson(backend.me(lang));

        expect(profile.id, 'usr_18');
        expect(profile.fullName, FixtureData.defaultCustomerName);
        expect(profile.phone, FixtureData.defaultCustomerPhone);
        expect(profile.avatarUrl, isNull);
        expect(profile.language, lang);
        expect(
          profile.stats,
          const ProfileStats(
            orderCount: 2,
            favouriteCount: 1,
            followingCount: 1,
          ),
        );
      }
    });

    test('an avatar is read as a url or as an image', () {
      String? avatarOf(Object? avatar) =>
          ProfileModel.fromJson({'id': 'usr_1', 'avatar': avatar}).avatarUrl;

      expect(avatarOf('https://x/a.jpg'), 'https://x/a.jpg');
      expect(avatarOf({'url': 'https://x/b.jpg'}), 'https://x/b.jpg');
      expect(avatarOf(null), isNull);
    });

    test('missing stats read as zero', () {
      final profile = ProfileModel.fromJson({'id': 'usr_1'});

      expect(profile.stats, const ProfileStats());
      expect(profile.fullName, isEmpty);
    });

    test('the profile hands the signed-in customer its fresh details', () {
      expect(
        _profile.customer,
        const Customer(id: 'usr_18', fullName: 'Noura', phone: '+96551502244'),
      );
      expect(_profile.stats.favouritesAndFollowing, 29);
    });
  });

  group('the phone as the design prints it', () {
    test('a Kuwaiti number splits four and four after the dial code', () {
      expect(formatPhoneForDisplay('+96551502244'), '+965 5150 2244');
      expect(formatPhoneForDisplay('96551502244'), '+965 5150 2244');
    });

    test('anything else is shown as the server sent it', () {
      expect(formatPhoneForDisplay('+201064780620'), '+201064780620');
      expect(formatPhoneForDisplay('51502244'), '51502244');
      expect(formatPhoneForDisplay(''), '');
    });
  });

  group('the fixture source through the repository', () {
    test('the account is read in the requested language', () async {
      final repository = ProfileRepositoryImpl(
        ProfileMockDataSource(FixtureBackend(), () async => 'en'),
      );

      final result = await repository.getProfile();
      final profile = result.fold(
        (failure) => throw StateError('$failure'),
        (profile) => profile,
      );

      expect(profile.language, 'en');
      expect(profile.stats.orderCount, 2);
    });
  });

  group('ProfileCubit', () {
    test('the account loads', () async {
      final cubit = ProfileCubit(
        GetProfileUseCase(_FakeRepository(() async => const Right(_profile))),
      );
      final states = <ProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();
      await _settle();

      expect(states.map((s) => s.status), [
        ProfileStatus.loading,
        ProfileStatus.loaded,
      ]);
      expect(cubit.state.profile, _profile);

      await sub.cancel();
      await cubit.close();
    });

    test('a failed first read reports the failure', () async {
      final cubit = ProfileCubit(
        GetProfileUseCase(_FakeRepository(() async => const Left(_offline))),
      );

      await cubit.load();

      expect(cubit.state.status, ProfileStatus.error);
      expect(cubit.state.profile, isNull);
      expect(cubit.state.errorMessage, 'You are offline.');
      await cubit.close();
    });

    test('a failed refresh keeps the account', () async {
      final repository = _FakeRepository(() async => const Right(_profile));
      final cubit = ProfileCubit(GetProfileUseCase(repository));
      await cubit.load();

      repository.answer = () async => const Left(_offline);
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.loaded);
      expect(cubit.state.profile, _profile);
      expect(cubit.state.errorMessage, 'You are offline.');
      await cubit.close();
    });

    test('two loads at once send one request', () async {
      final gate = Completer<Either<Failure, Profile>>();
      final repository = _FakeRepository(() => gate.future);
      final cubit = ProfileCubit(GetProfileUseCase(repository));

      final first = cubit.load();
      final second = cubit.load();
      gate.complete(const Right(_profile));
      await Future.wait([first, second]);

      expect(repository.calls, 1);
      expect(cubit.state.profile, _profile);
      await cubit.close();
    });
  });
  group('profile widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) =>
        tester.pumpWidget(ScreenUtilScope(
          child: Builder(
            builder: (_) => MaterialApp(
              theme: AppTheme.light,
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(body: Column(children: [child])),
              ),
            ),
          ),
        ));

    testWidgets('the identity prints the phone left to right', (tester) async {
      await pump(
        tester,
        const ProfileIdentity(name: 'نورة العنزي', phone: '+96551502244'),
      );

      final phone = find.text('+965 5150 2244');
      expect(phone, findsOneWidget);
      expect(
        Directionality.of(tester.element(phone)),
        TextDirection.ltr,
      );
      expect(find.text('نورة العنزي'), findsOneWidget);
    });

    testWidgets('a row shows its meta and answers a tap', (tester) async {
      var taps = 0;
      await pump(
        tester,
        ProfileRow(label: 'My orders', meta: '14', onTap: () => taps++),
      );

      expect(find.text('14'), findsOneWidget);
      await tester.tap(find.text('My orders'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
