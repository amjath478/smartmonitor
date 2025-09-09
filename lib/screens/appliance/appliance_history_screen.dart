import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/appliance.dart';
import '../../theme/app_theme.dart';

class ApplianceHistoryScreen extends StatelessWidget {
  final Appliance appliance;

  const ApplianceHistoryScreen({
    super.key,
    required this.appliance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appliance.id),
        backgroundColor: appliance.peak 
            ? AppTheme.errorColor.withOpacity(0.1) 
            : null,
      ),
      body: Column(
        children: [
          // Current Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              color: appliance.peak 
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
                        if (appliance.peak)
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatusItem(
                          icon: Icons.electric_bolt,
                          label: 'Current',
                          value: '${appliance.current.toStringAsFixed(2)} A',
                          color: appliance.peak 
                              ? AppTheme.errorColor 
                              : AppTheme.primaryColor,
                        ),
                        _StatusItem(
                          icon: Icons.router,
                          label: 'Device',
                          value: appliance.deviceId,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _StatusItem(
                          icon: Icons.access_time,
                          label: 'Updated',
                          value: DateFormat('HH:mm').format(appliance.timestamp),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // History Section
          Expanded(
            child: Consumer<FirebaseService>(
              builder: (context, firebaseService, child) {
                return StreamBuilder<List<Appliance>>(
                  stream: firebaseService.getApplianceHistoryStream(
                    appliance.deviceId,
                    appliance.id,
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

                    final history = snapshot.data ?? [];
                    
                    if (history.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64),
                            SizedBox(height: 16),
                            Text('No history available'),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Recent History',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: item.peak 
                                        ? AppTheme.errorColor 
                                        : AppTheme.primaryColor,
                                    child: Icon(
                                      item.peak ? Icons.warning : Icons.electric_bolt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    '${item.current.toStringAsFixed(2)} A',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    DateFormat('MMM d, yyyy • HH:mm:ss')
                                        .format(item.timestamp),
                                  ),
                                  trailing: item.peak
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'PEAK',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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