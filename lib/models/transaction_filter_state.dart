import 'package:flutter/material.dart';
import 'package:duwitku/models/transaction.dart';

class TransactionFilterState {
  final DateTimeRange dateRange;
  final List<int> selectedCategoryIds;
  final RangeValues? amountRange;
  final List<TransactionType> selectedTypes;
  final String searchQuery;

  const TransactionFilterState({
    required this.dateRange,
    this.selectedCategoryIds = const [],
    this.amountRange,
    this.selectedTypes = const [],
    this.searchQuery = '',
  });

  TransactionFilterState copyWith({
    DateTimeRange? dateRange,
    List<int>? selectedCategoryIds,
    RangeValues? amountRange,
    List<TransactionType>? selectedTypes,
    String? searchQuery,
  }) {
    return TransactionFilterState(
      dateRange: dateRange ?? this.dateRange,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      amountRange: amountRange ?? this.amountRange,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
