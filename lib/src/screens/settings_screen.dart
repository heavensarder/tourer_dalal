import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:path_provider/path_provider.dart'; // For getApplicationDocumentsDirectory
import 'package:sqflite/sqflite.dart'; // For getDatabasesPath
import 'package:share_plus/share_plus.dart'; // For sharing the file
import 'dart:io'; // For File
import 'package:path/path.dart' as p; // For join - NEW ALIAS
import 'package:intl/intl.dart'; // For DateFormat

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _currencySymbolController = TextEditingController();
  final TextEditingController _lowBalanceThresholdController = TextEditingController();
  bool _allowDeletingTransactions = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _currencySymbolController.text = appState.currencySymbol;
    _lowBalanceThresholdController.text = appState.lowBalanceThreshold?.toString() ?? '';
    _allowDeletingTransactions = appState.allowDeletingTransactions;
  }

  @override
  void dispose() {
    _currencySymbolController.dispose();
    _lowBalanceThresholdController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAllData(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Clear All Data'),
          content: const Text('Are you sure you want to delete ALL members and transactions? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await Provider.of<AppState>(context, listen: false).clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data cleared successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear data: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, 'tourer_dalal.db')); // Use p.join

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database file not found.')),
          );
        }
        return;
      }

      // Use getApplicationDocumentsDirectory for a more general approach, or getTemporaryDirectory
      // For sharing, getTemporaryDirectory is often sufficient.
      final tempDir = await getTemporaryDirectory();
      final String newPath = p.join(tempDir.path, 'tourer_dalal_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.db'); // Use p.join
      final File newFile = await dbFile.copy(newPath);

      await Share.shareXFiles([XFile(newFile.path)], text: 'Tourer Dalal Database Backup');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export database: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(kSpacingS),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(kSpacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('General Settings', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: kSpacingS),
                  TextFormField(
                    controller: _currencySymbolController,
                    decoration: const InputDecoration(
                      labelText: 'Currency Symbol',
                      hintText: 'e.g., \$, Tk, ৳',
                    ),
                    onChanged: (value) {
                      appState.setCurrencySymbol(value.isEmpty ? '৳' : value);
                    },
                  ),
                  SizedBox(height: kSpacingS),
                  TextFormField(
                    controller: _lowBalanceThresholdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low Balance Threshold (Optional)',
                      hintText: 'e.g., 50.00',
                    ),
                    onChanged: (value) {
                      final double? threshold = double.tryParse(value);
                      appState.setLowBalanceThreshold(threshold);
                    },
                  ),
                  SizedBox(height: kSpacingS),
                  SwitchListTile(
                    title: const Text('Allow Deleting Transactions'),
                    subtitle: const Text('Enable to show delete option for transactions'),
                    value: _allowDeletingTransactions,
                    onChanged: (value) {
                      setState(() {
                        _allowDeletingTransactions = value;
                      });
                      appState.setAllowDeletingTransactions(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: kSpacingM),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Export Database'),
                  subtitle: const Text('Create a backup of your data'),
                  onTap: () => _exportDatabase(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all members and transactions'),
                  onTap: () => _confirmClearAllData(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
