import 'package:duwitku/models/transaction.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key});

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late DateTimeRange _dateRange;
  List<int> _selectedCategoryIds = [];
  RangeValues? _amountRange;
  List<TransactionType> _selectedTypes = [];

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(transactionFilterProvider);
    _dateRange = filterState.dateRange;
    _selectedCategoryIds = List.from(filterState.selectedCategoryIds);
    _amountRange = filterState.amountRange;
    _selectedTypes = List.from(filterState.selectedTypes);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final maxAmountAsync = ref.watch(maxTransactionAmountProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transaksi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  ref.read(transactionFilterProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle('Tanggal'),
                ListTile(
                  title: Text(
                    '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _dateRange = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Tipe Transaksi'),
                Wrap(
                  spacing: 8.0,
                  children: TransactionType.values.map((type) {
                    final isSelected = _selectedTypes.contains(type);
                    return FilterChip(
                      label: Text(
                        type == TransactionType.income
                            ? 'Pemasukan'
                            : 'Pengeluaran',
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Kategori'),
                categoriesAsync.when(
                  data: (categories) {
                    return Wrap(
                      spacing: 8.0,
                      children: categories.map((category) {
                        final isSelected = _selectedCategoryIds.contains(
                          category.id,
                        );
                        return FilterChip(
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategoryIds.add(category.id);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Gagal memuat kategori'),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Rentang Jumlah'),
                maxAmountAsync.when(
                  data: (maxData) {
                    final maxAmount = maxData > 0 ? maxData : 10000000.0;
                    // Ensure current range is valid
                    var start = _amountRange?.start ?? 0;
                    var end = _amountRange?.end ?? maxAmount;

                    if (end > maxAmount) end = maxAmount;
                    if (start > end) start = 0;

                    final currentRange = RangeValues(start, end);

                    return Column(
                      children: [
                        RangeSlider(
                          values: currentRange,
                          min: 0,
                          max: maxAmount,
                          divisions: 100,
                          labels: RangeLabels(
                            NumberFormat.compactCurrency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                            ).format(currentRange.start),
                            NumberFormat.compactCurrency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                            ).format(currentRange.end),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _amountRange = values;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(currentRange.start),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(currentRange.end),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final notifier = ref.read(transactionFilterProvider.notifier);
                notifier.setDateRange(_dateRange);
                notifier.setCategoryIds(_selectedCategoryIds);
                notifier.setAmountRange(_amountRange);
                notifier.setTypes(_selectedTypes);
                Navigator.pop(context);
              },
              child: const Text('Terapkan Filter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
