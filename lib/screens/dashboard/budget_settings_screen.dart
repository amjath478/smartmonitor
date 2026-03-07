import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../theme/app_theme.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  // ===== Controllers & State =====
  late TextEditingController _budgetController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String _currentUid;
  bool _isLoading = false;
  bool _isLoadingCurrentBudget = true;
  String? _currentBudget;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController();
    _currentUid = _auth.currentUser!.uid;
    _loadCurrentBudget();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ===== Load Current Budget from Firebase =====
  Future<void> _loadCurrentBudget() async {
    try {
      final snapshot = await _database
          .child('users')
          .child(_currentUid)
          .child('monthlyBudget')
          .get();

      if (mounted) {
        setState(() {
          if (snapshot.exists) {
            _currentBudget = snapshot.value.toString();
            _budgetController.text = _currentBudget!;
          }
          _isLoadingCurrentBudget = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCurrentBudget = false;
        });
      }
      debugPrint('Error loading budget: $e');
    }
  }

  // ===== Validate Input =====
  bool _validateInput(String value) {
    if (value.isEmpty) {
      setState(() {
        _inputError = 'Please enter a budget amount';
      });
      return false;
    }

    final numValue = int.tryParse(value);
    if (numValue == null) {
      setState(() {
        _inputError = 'Only numbers allowed';
      });
      return false;
    }

    if (numValue <= 0) {
      setState(() {
        _inputError = 'Budget must be greater than 0';
      });
      return false;
    }

    setState(() {
      _inputError = null;
    });
    return true;
  }

  // ===== Show Confirmation Dialog =====
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Budget Update'),
        content: const Text(
          'This will also reset your monthly alert. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveBudget();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ===== Save Budget to Firebase =====
  Future<void> _saveBudget() async {
    if (!_validateInput(_budgetController.text)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final budgetValue = int.parse(_budgetController.text);

      // Save the budget
      await _database
          .child('users')
          .child(_currentUid)
          .child('monthlyBudget')
          .set(budgetValue);

      // Reset the lastAlertSent if it exists
      await _database
          .child('users')
          .child(_currentUid)
          .child('lastAlertSent')
          .remove();

      if (mounted) {
        setState(() {
          _currentBudget = budgetValue.toString();
          _isLoading = false;
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Budget saved successfully! Monthly alert reset.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after success
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving budget: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error saving budget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoadingCurrentBudget
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Current Budget Display Card =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.electric_bolt,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Current Budget',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentBudget != null ? '₹${_currentBudget!}' : '₹ --',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Per Month',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ===== Input Section =====
                  Text(
                    'Set New Budget',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll alert you when you reach 80% of your budget',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Budget Input Field =====
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _validateInput(value);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        hintText: 'Enter monthly budget',
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        prefixText: '₹ ',
                        prefixStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _inputError != null
                                ? Colors.red.shade300
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _inputError != null
                                ? Colors.red
                                : AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                  // ===== Error Message =====
                  if (_inputError != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _inputError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ===== Save Button =====
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _showConfirmationDialog,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.9),
                                      ),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Budget',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Info Box =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'When you update your budget, the monthly alert counter will reset, and you\'ll be notified when you reach 80% of the new budget.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blue.shade700,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
