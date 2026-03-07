import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../services/peak_monitor_service.dart';
import '../../services/local_notification_service.dart';
import '../../models/appliance.dart';
import '../../widgets/ai_chat_sheet.dart';
import '../appliance/appliance_history_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/appliance_card.dart';
import 'widgets/peak_warning_banner.dart';
import 'widgets/add_appliance_dialog.dart';
import 'widgets/edit_appliance_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  PeakMonitorService? _monitor;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseService = context.read<FirebaseService>();
      _monitor = PeakMonitorService(firebaseService, LocalNotificationService());
      _monitor?.start();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _monitor?.dispose();
    super.dispose();
  }

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
                child: const Text('Profile'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
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
                                      _showDeleteDialog(
                                          context, firebaseService, appliance);
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat button with pulse/glow
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: FloatingActionButton(
                heroTag: 'chatFab',
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: _openAIChatSheet,
                child: const Icon(Icons.smart_toy),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stylish add appliance button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddApplianceDialog(),
                  );
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAIChatSheet() {
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid ?? 'anonymous';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIChatSheet(userId: userId),
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
                  appliance.deviceId ?? '',
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
