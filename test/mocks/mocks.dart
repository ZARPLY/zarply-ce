import 'package:mockito/annotations.dart';
import 'package:solana/dto.dart' show TransactionDetails;
import 'package:zarply/features/wallet/data/services/wallet_solana_service.dart'
    show WalletSolanaService;

part 'mocks.mocks.dart';

@GenerateMocks(<Type>[
  WalletSolanaService, 
  TransactionDetails,
])
void main() {}   
