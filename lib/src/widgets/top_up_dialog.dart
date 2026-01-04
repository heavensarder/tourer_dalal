import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:tourer_dalal/src/utils/snackbar_utils.dart'; // New import

class TopUpDialog extends StatefulWidget {
  final int memberId;
  final String memberName;

  const TopUpDialog({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends State<TopUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTopUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final double amount = double.parse(_amountController.text);
        final String note = _noteController.text.trim();

        await appState.topUpMember(widget.memberId, amount, note: note);
        if (mounted) {
          Navigator.of(context).pop();
          SnackbarUtils.showUndoSnackBar(
            context,
            'Successfully topped up ${widget.memberName}',
            () {
              appState.undoLastAction();
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to top up: $e')),
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
    return AlertDialog(
      title: Text('Top Up ${widget.memberName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount to top up',
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
            SizedBox(height: kSpacingXS),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                hintText: 'e.g., Monthly contribution',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitTopUp,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Top Up'),
        ),
      ],
    );
  }
}
