sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T data) success, required R Function(Object error) failure}) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    }
    return failure((this as Failure<T>).error);
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Object error;
}
