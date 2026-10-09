
import 'package:flutter/material.dart';
import 'package:my_manager/models/transaction.dart';
import 'package:my_manager/screens/add_transaction_screen.dart';
import 'package:my_manager/services/transaction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService transactionService =
  TransactionService();

  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // Load transactions from Hive
  void loadTransactions() {
    final savedTransactions =
    transactionService.getTransactions();

    if (!mounted) return;

    setState(() {
      transactions = savedTransactions;
    });
  }

  // Total Income
  double get totalIncome {
    return transactions
        .where((transaction) => transaction.type == 'Income')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Total Expense
  double get totalExpense {
    return transactions
        .where((transaction) => transaction.type == 'Expense')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Total Balance
  double get totalBalance {
    return totalIncome - totalExpense;
  }

  // Open Add Transaction Screen
  Future<void> openAddTransactionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (!mounted) return;

    loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Manager'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // Total Balance Card
            SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '৳${totalBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Income & Expense Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        children: [
                          const Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '৳${totalIncome.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        children: [
                          const Text(
                            'Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '৳${totalExpense.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Transactions Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Transaction List
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: transactions.length,

                itemBuilder: (context, index) {
                  final Transaction transaction =
                  transactions[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        transaction.type == 'Income'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          transaction.type == 'Income'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: transaction.type == 'Income'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),

                      title: Text(
                        transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '${transaction.date.day}/'
                            '${transaction.date.month}/'
                            '${transaction.date.year}',
                      ),

                      trailing: Text(
                        '${transaction.type == 'Income' ? '+' : '-'}'
                            ' ৳${transaction.amount.toStringAsFixed(0)}',

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transaction.type == 'Income'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Add Transaction Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openAddTransactionScreen,
                icon: const Icon(Icons.add),
                label: const Text('Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
