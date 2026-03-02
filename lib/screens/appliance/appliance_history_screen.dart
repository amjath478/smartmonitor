import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/appliance.dart';
import '../../theme/app_theme.dart';

class ApplianceHistoryScreen extends StatefulWidget {
  final Appliance appliance;

  const ApplianceHistoryScreen({
    super.key,
    required this.appliance,
  });

  @override
  State<ApplianceHistoryScreen> createState() => _ApplianceHistoryScreenState();
}

class _ApplianceHistoryScreenState extends State<ApplianceHistoryScreen> {
  late String _historyType = 'daily'; // 'daily' or 'monthly'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appliance.id),
        backgroundColor: widget.appliance.peak 
            ? AppTheme.errorColor.withOpacity(0.1) 
            : null,
      ),
      body: Column(
        children: [
          // Current Status Card with real-time updates
          Consumer<FirebaseService>(
            builder: (context, firebaseService, child) {
              return StreamBuilder<List<Device>>(
                stream: firebaseService.getDevicesStream(),
                initialData: const [],
                builder: (context, snapshot) {
                  // Find the current appliance from the stream
                  Appliance? currentAppliance;
                  for (final device in snapshot.data ?? []) {
                    final found = device.appliances.firstWhere(
                      (app) => app.id == widget.appliance.id,
                      orElse: () => widget.appliance,
                    );
                    if (found.id == widget.appliance.id) {
                      currentAppliance = found;
                      break;
                    }
                  }
                  currentAppliance ??= widget.appliance;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    child: Card(
                      color: currentAppliance.peak 
                          ? AppTheme.errorColor.withOpacity(0.1)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current Status',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (currentAppliance.peak)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'PEAK ALERT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatusItem(
                                      icon: Icons.electric_bolt,
                                      label: 'Current',
                                      value: '${currentAppliance.live.current.toStringAsFixed(2)} A',
                                      color: currentAppliance.peak 
                                          ? AppTheme.errorColor 
                                          : AppTheme.primaryColor,
                                    ),
                                    _StatusItem(
                                      icon: Icons.flash_on,
                                      label: 'Power',
                                      value: '${currentAppliance.live.power.toStringAsFixed(0)} W',
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatusItem(
                                      icon: Icons.bolt,
                                      label: 'Today',
                                      value: '${currentAppliance.stats.todayEnergy.toStringAsFixed(2)} kWh',
                                      color: Colors.green,
                                    ),
                                    _StatusItem(
                                      icon: Icons.calendar_month,
                                      label: 'Month',
                                      value: '${currentAppliance.stats.monthEnergy.toStringAsFixed(2)} kWh',
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Energy History Section with Toggle
          Expanded(
            child: Consumer<FirebaseService>(
              builder: (context, firebaseService, child) {
                return Column(
                  children: [
                    // Toggle Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'daily',
                            label: Text('Daily'),
                            icon: Icon(Icons.calendar_today),
                          ),
                          ButtonSegment(
                            value: 'monthly',
                            label: Text('Monthly'),
                            icon: Icon(Icons.calendar_month),
                          ),
                        ],
                        selected: {_historyType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _historyType = newSelection.first;
                          });
                        },
                      ),
                    ),
                    // History List
                    Expanded(
                      child: _historyType == 'daily'
                          ? _buildDailyHistory(context, firebaseService)
                          : _buildMonthlyHistory(context, firebaseService),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHistory(BuildContext context, FirebaseService firebaseService) {
    return StreamBuilder<Map<String, double>>(
      stream: firebaseService.getDailyEnergyHistory(
        widget.appliance.deviceId ?? '',
        widget.appliance.id,
      ),
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
                  'Error loading history',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No daily history available',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        // Sort by date descending (latest first)
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.builder(
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final dateStr = entry.key;
              final energy = entry.value;

              try {
                final date = DateTime.parse(dateStr);
                final formattedDate = DateFormat('MMM d, yyyy').format(date);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '${energy.toStringAsFixed(2)} kWh',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMonthlyHistory(BuildContext context, FirebaseService firebaseService) {
    return StreamBuilder<Map<String, double>>(
      stream: firebaseService.getMonthlyEnergyHistory(
        widget.appliance.deviceId ?? '',
        widget.appliance.id,
      ),
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
                  'Error loading history',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No monthly history available',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        // Sort by month descending (latest first)
        final sortedEntries = data.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

        return Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.builder(
            itemCount: sortedEntries.length,
            itemBuilder: (context, index) {
              final entry = sortedEntries[index];
              final monthStr = entry.key;
              final energy = entry.value;

              try {
                // Parse YYYY-MM format
                final parts = monthStr.split('-');
                if (parts.length == 2) {
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final date = DateTime(year, month);
                  final formattedMonth = DateFormat('MMMM yyyy').format(date);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      formattedMonth,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${energy.toStringAsFixed(2)} kWh',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }
              } catch (_) {
                return const SizedBox.shrink();
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}