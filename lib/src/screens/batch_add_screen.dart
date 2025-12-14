import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';

class BatchAddScreen extends StatefulWidget {
  const BatchAddScreen({super.key});

  @override
  State<BatchAddScreen> createState() => _BatchAddScreenState();
}

class _BatchAddScreenState extends State<BatchAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  double _amountPerMember = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmountPerMember);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmountPerMember);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateAmountPerMember() {
    setState(() {
      _amountPerMember = double.tryParse(_amountController.text) ?? 0.0;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final double amount = double.parse(_amountController.text);
        final String note = _noteController.text.trim();
        final int memberCount = appState.members.length;

        await appState.batchAdd(amount, note: note);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added \\৳${amount.toStringAsFixed(2)} to $memberCount members (total \৳${(amount * memberCount).toStringAsFixed(2)})'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to batch add: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final int memberCount = appState.members.length;
    final double totalAmount = _amountPerMember * memberCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Add Contributions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kSpacingS),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Per Member',
                  hintText: 'e.g., 50.00',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: kSpacingS),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g., Monthly contribution',
                ),
              ),
              SizedBox(height: kSpacingM),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Members to update: $memberCount', style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: kSpacingXS),
                      Text('Total amount to be added: \৳${totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Confirm Batch Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
