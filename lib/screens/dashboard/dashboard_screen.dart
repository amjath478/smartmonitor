/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/appliance.dart';
import '../appliance/appliance_history_screen.dart';
import 'widgets/appliance_card.dart';
import 'widgets/peak_warning_banner.dart';
import 'widgets/add_appliance_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Monitor'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Sign Out'),
                onTap: () {
                  context.read<AuthService>().signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FirebaseService>(
        builder: (context, firebaseService, child) {
          return StreamBuilder<List<Device>>(
            stream: firebaseService.getDevicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final devices = snapshot.data ?? [];
              
              if (devices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first appliance to get started'),
                    ],
                  ),
                );
              }

              final allAppliances = devices
                  .expand((device) => device.appliances)
                  .toList()
                  ..sort((a, b) => b.current.compareTo(a.current));

              final hasPeakWarnings = devices.any((device) => device.hasPeakAppliances);

              return Column(
                children: [
                  if (hasPeakWarnings) const PeakWarningBanner(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await firebaseService.refreshData();
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final appliance = allAppliances[index];
                                  return ApplianceCard(
                                    appliance: appliance,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ApplianceHistoryScreen(
                                            appliance: appliance,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: allAppliances.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddApplianceDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
//4th commit
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../models/appliance.dart';
import '../appliance/appliance_history_screen.dart';
import 'widgets/appliance_card.dart';
import 'widgets/peak_warning_banner.dart';
import 'widgets/add_appliance_dialog.dart';
import 'widgets/edit_appliance_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Monitor'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Sign Out'),
                onTap: () {
                  context.read<AuthService>().signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FirebaseService>(
        builder: (context, firebaseService, child) {
          return StreamBuilder<List<Device>>(
            stream: firebaseService.getDevicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final devices = snapshot.data ?? [];
              
              if (devices.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.devices,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text('Add your first appliance to get started'),
                    ],
                  ),
                );
              }

              final allAppliances = devices
                  .expand((device) => device.appliances)
                  .toList()
                  ..sort((a, b) => b.current.compareTo(a.current));

              final hasPeakWarnings = devices.any((device) => device.hasPeakAppliances);

              return Column(
                children: [
                  if (hasPeakWarnings) const PeakWarningBanner(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await firebaseService.refreshData();
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final appliance = allAppliances[index];
                                  return ApplianceCard(
                                    appliance: appliance,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ApplianceHistoryScreen(
                                            appliance: appliance,
                                          ),
                                        ),
                                      );
                                    },
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => EditApplianceDialog(
                                          appliance: appliance,
                                        ),
                                      );
                                    },
                                    onDelete: () {
                                      _showDeleteDialog(context, firebaseService, appliance);
                                    },
                                  );
                                },
                                childCount: allAppliances.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddApplianceDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FirebaseService firebaseService, Appliance appliance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appliance'),
          content: Text('Are you sure you want to delete "${appliance.id}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await firebaseService.deleteAppliance(
                  appliance.deviceId,
                  appliance.id,
                );
                
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete appliance. Please try again.'),
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
