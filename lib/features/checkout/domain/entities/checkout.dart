import 'package:equatable/equatable.dart';

class CheckoutAddress extends Equatable {
  final String id;
  final String label;
  final String line;
  final bool isDefault;

  const CheckoutAddress({
    required this.id,
    required this.label,
    required this.line,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, label, line, isDefault];
}

extension CheckoutAddresses on List<CheckoutAddress> {
  CheckoutAddress? get preferred =>
      where((a) => a.isDefault).firstOrNull ?? firstOrNull;

  CheckoutAddress? byId(String? id) => where((a) => a.id == id).firstOrNull;
}

class PlaceOrderParams extends Equatable {
  final String addressId;
  final String? notes;

  const PlaceOrderParams({required this.addressId, this.notes});

  @override
  List<Object?> get props => [addressId, notes];
}
