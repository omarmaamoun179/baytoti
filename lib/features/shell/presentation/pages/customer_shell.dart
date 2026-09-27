import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../widgets/bottom_nav_bar.dart';

class CustomerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool showNav;

  const CustomerShell({
    super.key,
    required this.navigationShell,
    this.showNav = true,
  });

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showNav
          ? BlocSelector<CartCubit, CartState, int>(
              selector: (state) => state.itemCount,
              builder: (context, count) => BottomNavBar(
                currentIndex: navigationShell.currentIndex,
                cartCount: count,
                onTap: _onTap,
              ),
            )
          : null,
    );
  }
}
