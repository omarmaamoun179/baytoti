import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/services/network_service.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'fake_network.dart';

CartCubit cartCubitOver([NetworkService? network, SessionNotifier? session]) {
  final repository =
      CartRepositoryImpl(CartRemoteDataSource(network ?? FakeNetwork()));
  return CartCubit(
    GetCartUseCase(repository),
    AddToCartUseCase(repository),
    UpdateCartItemUseCase(repository),
    RemoveCartItemUseCase(repository),
    session ?? SessionNotifier(),
  );
}

Widget withGuestCart(Widget child) =>
    BlocProvider<CartCubit>(create: (_) => cartCubitOver(), child: child);
