import 'package:flutter/material.dart';
import 'package:my_manager/models/transaction.dart';
import 'package:my_manager/screens/add_transaction_screen.dart';
import 'package:my_manager/screens/cloud_backup_screen.dart';
import 'package:my_manager/services/export_report_service.dart';
import 'package:my_manager/services/transaction_service.dart';
import 'package:my_manager/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService transactionService = TransactionService();
  final ExportReportService _exportService = ExportReportService();

  List<Transaction> transactions = [];
  List<dynamic> transactionKeys = [];
  bool _exporting = false;
  bool _hideBalance = false;
  String _selectedFilter = 'All'; // 'All', 'Income', 'Expense'
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      );
    }
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
    return '$integerPart.${parts[1]}';
  }

  void loadTransactions() {
    final records = transactionService.getTransactionsWithKeys();

    final entries = records
        .map((item) => {
      'key': item['key'],
      'transaction': item['transaction'] as Transaction,
    })
        .toList();

    entries.sort(
          (a, b) => (b['transaction'] as Transaction)
          .date
          .compareTo((a['transaction'] as Transaction).date),
    );

    if (!mounted) return;

    setState(() {
      transactionKeys = entries.map((item) => item['key']).toList();
      transactions =
          entries.map((item) => item['transaction'] as Transaction).toList();
    });
  }

  double get totalIncome => transactions
      .where((t) => t.type.toLowerCase() == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type.toLowerCase() == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalBalance => totalIncome - totalExpense;

  List<Map<String, dynamic>> get filteredEntries {
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];

      // Type filter
      if (_selectedFilter != 'All' &&
          t.type.toLowerCase() != _selectedFilter.toLowerCase()) {
        continue;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchDesc = t.description.toLowerCase().contains(query);
        final matchCategory = t.category.toLowerCase().contains(query);
        if (!matchDesc && !matchCategory) {
          continue;
        }
      }

      result.add({
        'key': transactionKeys[i],
        'transaction': t,
        'originalIndex': i,
      });
    }
    return result;
  }

  Future<void> openAddTransactionScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (result == true || mounted) {
      loadTransactions();
    }
  }

  Future<void> editTransaction(int originalIndex) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transaction: transactions[originalIndex],
          transactionKey: transactionKeys[originalIndex],
        ),
      ),
    );

    if (result == true || mounted) {
      loadTransactions();
    }
  }

  Future<void> deleteTransaction(int originalIndex) async {
    final transaction = transactions[originalIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.expenseLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.expense,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'মুছে ফেলতে চান?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '"${transaction.description}" লেনদেনটি কি তালিকা থেকে মুছে ফেলবেন?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await transactionService.deleteTransaction(transactionKeys[originalIndex]);

      if (!mounted) return;

      loadTransactions();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লেনদেন সফলভাবে মুছে ফেলা হয়েছে'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('মুছতে ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _runExportAction(Future<void> Function() action) async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      await action();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _showExportMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আর্থিক রিপোর্ট এক্সপোর্ট',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Download or share your financial records',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // CSV Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.table_chart_rounded, color: AppColors.income, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'CSV ফরম্যাট (Excel & Google Sheets)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _runExportAction(() => _exportService.downloadCsv(context));
                            },
                            icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.income),
                            label: const Text('Download CSV', style: TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _runExportAction(() => _exportService.shareCsv(context));
                            },
                            icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.accent),
                            label: const Text('Share CSV', style: TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // PDF Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, color: AppColors.expense, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'PDF ফরম্যাট (প্রিন্ট ও পড়ার উপযোগী)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _runExportAction(() => _exportService.downloadPdf(context));
                            },
                            icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.expense),
                            label: const Text('Download PDF', style: TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _runExportAction(() => _exportService.sharePdf(context));
                            },
                            icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.accent),
                            label: const Text('Share PDF', style: TextStyle(color: AppColors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'আজ, ${date.day}/${date.month}';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return 'গতকাল, ${date.day}/${date.month}';
    }

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'সার্চ করুন (বিবরণ বা ক্যাটাগরি)...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
        )
            : Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Manager',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'স্মার্ট ফাইন্যান্স ট্র্যাকার',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close Search' : 'Search',
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Export & Download',
            onPressed: _exporting ? null : _showExportMenu,
            icon: _exporting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
                : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.file_download_outlined,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cloud Backup & Sync',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CloudBackupScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.cloud_sync_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Hero Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                          Color(0xFF334155),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL BALANCE (মোট ব্যালেন্স)',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _hideBalance = !_hideBalance);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  _hideBalance
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _hideBalance ? '৳ •••••••' : '৳ ${formatAmount(totalBalance)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Income & Expense Dual Pills inside hero card
                        Row(
                          children: [
                            // Income Pill
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.income.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward_rounded,
                                        size: 16,
                                        color: AppColors.income,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Income (আয়)',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _hideBalance ? '••••' : '৳${formatAmount(totalIncome)}',
                                            style: const TextStyle(
                                              color: AppColors.income,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Expense Pill
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 16,
                                        color: AppColors.expense,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Expense (খরচ)',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _hideBalance ? '••••' : '৳${formatAmount(totalExpense)}',
                                            style: const TextStyle(
                                              color: AppColors.expense,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Filter Chips (All, Income, Expense)
                  Row(
                    children: [
                      _buildFilterChip('All', 'সব (${transactions.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Income',
                        'আয় (${transactions.where((t) => t.type.toLowerCase() == 'income').length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Expense',
                        'খরচ (${transactions.where((t) => t.type.toLowerCase() == 'expense').length})',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Transactions List
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'কোনো ফলাফল পাওয়া যায়নি'
                            : 'এখনো কোনো লেনদেন যুক্ত করা হয়নি',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '"$_searchQuery" এর সাথে কোনো রেকর্ড মেলেনি'
                            : 'নিচের বোতামে ট্যাপ করে আয় বা খরচের হিসাব যোগ করুন',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = filtered[index];
                    final Transaction t = item['transaction'] as Transaction;
                    final int origIndex = item['originalIndex'] as int;
                    final bool isIncome = t.type.toLowerCase() == 'income';
                    final Color catColor = CategoryUtils.getColor(t.category);
                    final IconData catIcon = CategoryUtils.getIcon(t.category);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        onTap: () => editTransaction(origIndex),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(catIcon, color: catColor, size: 22),
                        ),
                        title: Text(
                          t.description,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTransactionDate(t.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}৳${formatAmount(t.amount)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isIncome ? AppColors.incomeDark : AppColors.expenseDark,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (action) {
                                if (action == 'edit') {
                                  editTransaction(origIndex);
                                } else if (action == 'delete') {
                                  deleteTransaction(origIndex);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                      SizedBox(width: 8),
                                      Text('এডিট করুন'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: AppColors.expense),
                                      SizedBox(width: 8),
                                      Text('মুছে ফেলুন', style: TextStyle(color: AppColors.expense)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddTransactionScreen,
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'নতুন হিসাব',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final bool isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
