import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class FinanceProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  double get balance {
    double total = 0;
    for (var t in _transactions) {
      total += t.type == "income" ? t.amount : -t.amount;
    }
    return total;
  }

  void setTransactions(List<TransactionModel> list) {
    _transactions = list;
    notifyListeners();
  }

  void addTransaction(TransactionModel t) {
    _transactions.add(t);
    notifyListeners();
  }

  String formatCurrency(double amount) {
    return "\$ ${amount.toStringAsFixed(2)}";
  }

  String getCategoryName(int id) {
    // luego lo conectas a backend
    return "Categoria $id";
  }
}