import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base UseCase interface
/// All use cases should implement this interface
/// T = Return Type, Params = Parameters
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// UseCase with no parameters
abstract class UseCaseNoParams<T> {
  Future<Either<Failure, T>> call();
}

/// UseCase that returns a Stream
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// UseCase that returns a Stream with no parameters
abstract class StreamUseCaseNoParams<T> {
  Stream<T> call();
}
