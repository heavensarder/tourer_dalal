import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourer_dalal/src/config/constants.dart';
import 'package:tourer_dalal/src/config/theme.dart';
import 'package:tourer_dalal/src/models/member.dart';
import 'package:tourer_dalal/src/providers/app_state.dart';
import 'package:tourer_dalal/src/widgets/top_up_dialog.dart';
import 'package:tourer_dalal/src/utils/snackbar_utils.dart'; // New import
import 'package:flutter_slidable/flutter_slidable.dart'; 

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  Future<void> _confirmDelete(BuildContext context, Member member) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete ${member.name}? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.deleteMember(member.id);
        if (mounted) {
          SnackbarUtils.showUndoSnackBar(
            context,
            '${member.name} deleted successfully!',
            () {
              appState.undoLastAction();
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete ${member.name}: $e')),
          );
        }
      }
    }
  }

  void _showTopUpDialog(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TopUpDialog(memberId: member.id, memberName: member.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.pushNamed(context, Routes.addMember),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.members.isEmpty) {
            return const Center(
              child: Text('No members added yet. Tap + to add one!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(kSpacingXS),
            itemCount: appState.members.length,
            itemBuilder: (context, index) {
              final member = appState.members[index];
              return Slidable(
                key: ValueKey(member.id),
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) => _showTopUpDialog(context, member),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      icon: Icons.add_circle_outline,
                      label: 'Top Up',
                    ),
                    SlidableAction(
                      onPressed: (context) => _confirmDelete(context, member),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: kSpacingXXS),
                  child: ListTile(
                    title: Text(member.name),
                    subtitle: Text('Total Paid: ${appState.currencySymbol}${member.totalPaid.toStringAsFixed(2)}'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.memberDetail,
                        arguments: member.id,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}