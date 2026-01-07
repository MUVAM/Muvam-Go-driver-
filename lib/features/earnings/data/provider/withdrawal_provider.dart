import 'package:flutter/material.dart';
import 'package:muvam_rider/core/services/withdrawal_service.dart';
import 'package:muvam_rider/features/earnings/data/models/bank.dart';

class WithdrawalProvider with ChangeNotifier {
  final WithdrawalService _withdrawalService = WithdrawalService();

  List<Bank> _banks = [];
  Bank? _selectedBank;
  bool _isLoading = false;
  bool _isWithdrawing = false;
  String? _errorMessage;
  String? _successMessage;

  List<Bank> get banks => _banks;
  Bank? get selectedBank => _selectedBank;
  bool get isLoading => _isLoading;
  bool get isWithdrawing => _isWithdrawing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> fetchBanks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _banks = await _withdrawalService.getBanks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectBank(Bank bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  Future<bool> withdraw({
    required String accountName,
    required String accountNumber,
    required double amount,
  }) async {
    if (_selectedBank == null) {
      _errorMessage = 'Please select a bank';
      notifyListeners();
      return false;
    }

    _isWithdrawing = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final response = await _withdrawalService.withdrawFunds(
        accountName: accountName,
        accountNumber: accountNumber,
        bankName: _selectedBank!.name,
        bankCode: _selectedBank!.code,
        amount: amount,
      );

      _successMessage = response['message'] ?? 'Withdrawal successful';
      _isWithdrawing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isWithdrawing = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _selectedBank = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
