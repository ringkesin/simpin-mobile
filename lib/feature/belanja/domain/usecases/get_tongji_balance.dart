import '../repositories/belanja_repository.dart';

/// Use case untuk get Tongji balance
class GetTongjiBalance {
  final BelanjaRepository repository;

  GetTongjiBalance(this.repository);

  Future<BelanjaResult<int>> call() {
    return repository.getTongjiBalance();
  }
}
