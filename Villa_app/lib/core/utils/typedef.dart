import 'package:dartz/dartz.dart';
import 'package:villabistromobile/core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef Result<T> = Either<Failure, T>;
typedef EitherVoidResult = Either<Failure, void>;
