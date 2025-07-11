import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:zarply/features/pay/data/repositories/payment_review_content_repository_impl.dart';
import 'package:zarply/features/pay/domain/repositories/payment_review_content_repository.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  group('PaymentReviewContentRepository – getTransactionDetails()', () {
    late MockWalletSolanaService mockWalletService;
    late PaymentReviewContentRepository repository;
    late MockTransactionDetails fakeTx; 

    setUp(() {
      mockWalletService = MockWalletSolanaService();
      repository = PaymentReviewContentRepositoryImpl(
        walletSolanaService: mockWalletService,
      );
      fakeTx = MockTransactionDetails(); 
    });

    test('returns TransactionDetails fetched from wallet service', () async {
      const signature = 'test_signature';
      when(mockWalletService.getTransactionDetails(signature))
          .thenAnswer((_) async => fakeTx);

      final result = await repository.getTransactionDetails(signature);

      expect(result, fakeTx);
      verify(mockWalletService.getTransactionDetails(signature)).called(1);
      verifyNoMoreInteractions(mockWalletService);
    });
  });
}
