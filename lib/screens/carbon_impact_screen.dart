import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/appliance.dart';
import '../theme/app_theme.dart';

// constant emission factor (kg CO2 per kWh)
const double emissionFactor = 0.82;

class CarbonImpactScreen extends StatelessWidget {
  final String deviceId;
  final String? applianceId;

  const CarbonImpactScreen({
    super.key,
    required this.deviceId,
    this.applianceId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Impact'),
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
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final devices = snapshot.data ?? [];
              final device = devices.firstWhere(
                (d) => d.id == deviceId,
                orElse: () => Device(id: deviceId, appliances: []),
              );

              if (device.appliances.isEmpty) {
                return const Center(
                  child: Text('No appliance data available for this device.'),
                );
              }

              // compute totals
              double totalEnergy = 0.0;
              for (var app in device.appliances) {
                totalEnergy += app.stats.monthEnergy;
              }
              final totalCo2 = totalEnergy * emissionFactor;

              String badgeText;
              Color badgeColor;
              if (totalCo2 < 10) {
                badgeText = 'Low Impact';
                badgeColor = Colors.green;
              } else if (totalCo2 <= 30) {
                badgeText = 'Moderate';
                badgeColor = Colors.orange;
              } else {
                badgeText = 'High';
                badgeColor = AppTheme.errorColor;
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // section 1: device total impact
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'Device Total (Monthly)',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              // big circular card
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${totalCo2.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Energy: $totalEnergy kWh',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // section 2: per appliance list
                      Text(
                        'Appliances',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...device.appliances.map((app) {
                        final co2 = app.stats.monthEnergy * emissionFactor;
                        Color indicatorColor;
                        if (co2 < 10) {
                          indicatorColor = Colors.green;
                        } else if (co2 <= 30) {
                          indicatorColor = Colors.orange;
                        } else {
                          indicatorColor = AppTheme.errorColor;
                        }
                        return ListTile(
                          leading: Icon(Icons.eco, color: AppTheme.primaryColor),
                          title: Text(app.id),
                          subtitle: Text(
                              'Energy: ${app.stats.monthEnergy.toStringAsFixed(2)} kWh\nCO2: ${co2.toStringAsFixed(1)} kg'),
                          isThreeLine: true,
                          trailing: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: indicatorColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
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
