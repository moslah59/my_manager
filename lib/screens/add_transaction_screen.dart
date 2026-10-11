import 'package:flutter/material.dart';
import 'package:my_manager/models/transaction.dart';
import 'package:my_manager/services/transaction_service.dart';
import 'package:my_manager/theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  final dynamic transactionKey;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.transactionKey,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String selectedType = 'Expense';
  String selectedCategory = 'General';
  DateTime selectedDate = DateTime.now();

  final TransactionService transactionService = TransactionService();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get isEditing => widget.transaction != null;

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Food', 'label': 'খাবার', 'icon': Icons.restaurant_rounded},
    {'name': 'Shopping', 'label': 'কেনাকাটা', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Salary', 'label': 'বেতন', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Transport', 'label': 'যাতায়াত', 'icon': Icons.directions_subway_rounded},
    {'name': 'Bills', 'label': 'বিল', 'icon': Icons.receipt_long_rounded},
    {'name': 'Entertainment', 'label': 'বিনোদন', 'icon': Icons.movie_rounded},
    {'name': 'Health', 'label': 'চিকিৎসা', 'icon': Icons.medical_services_rounded},
    {'name': 'Education', 'label': 'শিক্ষা', 'icon': Icons.school_rounded},
    {'name': 'General', 'label': 'সাধারণ', 'icon': Icons.payments_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      selectedType = t.type;
      selectedCategory = t.category;
      selectedDate = t.date;
      descriptionController.text = t.description;
      amountController.text = t.amount == t.amount.truncateToDouble()
          ? t.amount.toInt().toString()
          : t.amount.toString();
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> saveTransaction() async {
    if (!formKey.currentState!.validate()) return;

    final double parsedAmount = double.parse(amountController.text.trim());
    final transaction = Transaction(
      type: selectedType,
      category: selectedCategory,
      description: descriptionController.text.trim(),
      amount: parsedAmount,
      date: selectedDate,
    );

    try {
      if (isEditing) {
        await transactionService.updateTransaction(
          widget.transactionKey,
          transaction,
        );
      } else {
        await transactionService.addTransaction(transaction);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'লেনদেন আপডেট করা হয়েছে'
                : 'লেনদেন সফলভাবে সংরক্ষণ করা হয়েছে',
          ),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${date.day}/${date.month}/${date.year}';
    }
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType == 'Expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'New Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dual Type Toggle (Expense / Income)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedType = 'Expense';
                            if (selectedCategory == 'Salary') {
                              selectedCategory = 'General';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isExpense
                                ? [
                                    BoxShadow(
                                      color: AppColors.expense.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: isExpense ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Expense (খরচ)',
                                style: TextStyle(
                                  color: isExpense ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedType = 'Income';
                            if (selectedCategory == 'Food') {
                              selectedCategory = 'Salary';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isExpense ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isExpense
                                ? [
                                    BoxShadow(
                                      color: AppColors.income.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: !isExpense ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Income (আয়)',
                                style: TextStyle(
                                  color: !isExpense ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Amount Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '৳',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: isExpense ? AppColors.expense : AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            autofocus: !isEditing,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Amount is required';
                              }
                              final val = double.tryParse(value.trim());
                              if (val == null || val <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Selector Chips
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat['name'];
                    final Color catColor = CategoryUtils.getColor(cat['name']);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          cat['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : catColor,
                        ),
                        label: Text(
                          '${cat['name']} (${cat['label']})',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        onSelected: (val) {
                          setState(() {
                            selectedCategory = cat['name'] as String;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Description
              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Grocery shopping, Salary bonus, Coffee...',
                  prefixIcon: const Icon(Icons.description_outlined, color: AppColors.textMuted),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Date Picker
              const Text(
                'DATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: selectDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Save Button
              ElevatedButton.icon(
                onPressed: saveTransaction,
                icon: Icon(
                  isEditing ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(
                  isEditing ? 'Update Transaction' : 'Save Transaction',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense ? AppColors.primary : AppColors.incomeDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}