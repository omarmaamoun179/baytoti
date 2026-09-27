import 'package:equatable/equatable.dart';

abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
