import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:tourer_dalal/src/utils/snackbar_utils.dart'; // New import

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _initialAmountController = TextEditingController();
  final TextEditingController _initialContributionPerRoundController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _initialAmountController.dispose();
    _initialContributionPerRoundController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final String name = _nameController.text.trim();
        final double initialAmount = double.tryParse(_initialAmountController.text) ?? 0.0;
        final double initialContributionPerRound = double.tryParse(_initialContributionPerRoundController.text) ?? 0.0;

        await appState.addMember(
          name,
          initialAmount: initialAmount,
          initialContributionPerRound: initialContributionPerRound,
        );

        if (mounted) {
          Navigator.of(context).pop();
          SnackbarUtils.showUndoSnackBar(
            context, 
            '$name added successfully!',
            () {
              appState.undoLastAction();
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add member: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kSpacingS),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                  hintText: 'Enter member\'s name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: kSpacingS),
              TextFormField(
                controller: _initialAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Amount (Optional)',
                  hintText: 'e.g., 100.00',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: kSpacingS),
              TextFormField(
                controller: _initialContributionPerRoundController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Contribution Per Round (Optional)',
                  hintText: 'e.g., 50.00',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Add Member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}