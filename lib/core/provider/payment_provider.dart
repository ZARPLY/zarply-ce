import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final WalletRepository _walletRepository = WalletRepositoryImpl();

  String? _recipientAddress;
  ProgramAccount? _recipientTokenAccount;
  bool _isLoadingTokenAccount = false;
  String? _tokenAccountError;

  String? get recipientAddress => _recipientAddress;
  ProgramAccount? get recipientTokenAccount => _recipientTokenAccount;
  bool get isLoadingTokenAccount => _isLoadingTokenAccount;
  String? get tokenAccountError => _tokenAccountError;
  bool get hasValidRecipient => _recipientTokenAccount != null;

  /// Set recipient address and fetch their token account
  Future<void> setRecipientAddress(String address) async {
    if (_recipientAddress == address) return; // No change needed

    _recipientAddress = address;
    _recipientTokenAccount = null;
    _tokenAccountError = null;

    if (address.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoadingTokenAccount = true;
    notifyListeners();

    try {
      _recipientTokenAccount = await _walletRepository.getAssociatedTokenAccount(address);

      if (_recipientTokenAccount == null) {
        _tokenAccountError = 'Recipient does not have a token account for this token';
      } else {
        _tokenAccountError = null;
      }
    } catch (e) {
      _tokenAccountError = 'Could not verify recipient token account: $e';
      _recipientTokenAccount = null;
    } finally {
      _isLoadingTokenAccount = false;
      notifyListeners();
    }
  }

  /// Clear current recipient data
  void clearRecipient() {
    _recipientAddress = null;
    _recipientTokenAccount = null;
    _tokenAccountError = null;
    _isLoadingTokenAccount = false;
    notifyListeners();
  }
}
