import 'package:flutter/material.dart';
import 'package:tourer_dalal/src/config/constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black, // Changed to black for contrast
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tourer Dalal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                Text(
                  'Financial Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            routeName: Routes.dashboard,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.group,
            title: 'Members',
            routeName: Routes.members,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: 'Transactions',
            routeName: Routes.transactions,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.picture_as_pdf,
            title: 'PDF Report',
            routeName: Routes.pdfReport,
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            routeName: Routes.settings,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required String routeName}) {
    final bool isSelected = ModalRoute.of(context)?.settings.name == routeName;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.white),
      title: Text(
        title,
        style: isSelected ? TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold) : const TextStyle(color: Colors.white),
      ),
      onTap: () {
        if (!isSelected) {
          // Pop the drawer first, then push the new route
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(routeName);
        } else {
          Navigator.of(context).pop(); // Close drawer if already on the page
        }
      },
    );
  }
}