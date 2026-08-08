import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/taifa_dimens.dart';
import '../../../../app/theme/taifa_theme.dart';
import '../../application/social_providers.dart';
import '../widgets/transaction_tile.dart';
import 'social_widgets.dart';

class TransactionSearchScreen extends ConsumerStatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  ConsumerState<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends ConsumerState<TransactionSearchScreen> {
  final _queryController = TextEditingController();
  String? _type;
  int _page = 1;

  static const _types = [
    ('All types', null),
    ('Send money', 'send_money'),
    ('Receive money', 'receive_money'),
    ('Top up', 'top_up'),
    ('Withdrawal', 'withdrawal'),
    ('Refund', 'refund'),
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.taifa;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TaifaSpacing.screenH),
          child: Column(
            children: [
              const SizedBox(height: TaifaSpacing.sm),
              const SocialScreenHeader(title: 'Transaction History'),
              const SizedBox(height: TaifaSpacing.md),
              TextField(
                controller: _queryController,
                style: TextStyle(color: palette.textPrimary, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Search by counterparty or note',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                ),
                onSubmitted: (_) => setState(() => _page = 1),
              ),
              const SizedBox(height: TaifaSpacing.sm),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  separatorBuilder: (_, _) => const SizedBox(width: TaifaSpacing.xs),
                  itemBuilder: (_, i) {
                    final (label, value) = _types[i];
                    final selected = _type == value;
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 10)),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _type = value;
                        _page = 1;
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: TaifaSpacing.md),
              Expanded(
                child: FutureBuilder(
                  future: ref.read(socialRepositoryProvider).searchTransactions(
                    type: _type,
                    query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
                    page: _page,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not search transactions.\n${snapshot.error}', textAlign: TextAlign.center));
                    }
                    final result = snapshot.data!;
                    if (result.results.isEmpty) {
                      return const SocialEmptyState(icon: Icons.receipt_rounded, message: 'No transactions match.');
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: result.results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: TaifaSpacing.xs),
                            itemBuilder: (_, i) => TransactionTile(transaction: result.results[i]),
                          ),
                        ),
                        if (result.numPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: TaifaSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  onPressed: _page > 1 ? () => setState(() => _page--) : null,
                                ),
                                Text('Page $_page of ${result.numPages}', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  onPressed: _page < result.numPages ? () => setState(() => _page++) : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
