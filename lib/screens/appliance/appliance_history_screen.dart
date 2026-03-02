import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

  /// Build daily energy chart (last 7 days)
  Widget _buildDailyChart(Map<String, double> data) {
    if (data.isEmpty) {
      return _buildEmptyChartPlaceholder('Not enough data for chart');
    }

    // Parse and sort dates; keep only last 7 days
    final entries = data.entries.toList();
    final sortedEntries = entries
        .map((e) {
          try {
            return MapEntry(DateTime.parse(e.key), e.value);
          } catch (_) {
            return null;
          }
        })
        .whereType<MapEntry<DateTime, double>>()
        .toList()
        ..sort((a, b) => a.key.compareTo(b.key)); // old → new

    // Keep last 7 days
    final last7 = sortedEntries.length > 7
        ? sortedEntries.sublist(sortedEntries.length - 7)
        : sortedEntries;

    if (last7.length < 2) {
      return _buildEmptyChartPlaceholder('Not enough data for chart');
    }

    // Find max value for Y-axis scaling
    final maxValue = last7.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxValue * 1.2).ceilToDouble();

    // Create chart spots
    final spots = List<FlSpot>.generate(last7.length, (index) {
      return FlSpot(index.toDouble(), last7[index].value);
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withOpacity(0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 32, 16),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: false,
              horizontalInterval: yAxisMax / 4,
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < last7.length) {
                      final date = last7[index].key;
                      return Text(
                        DateFormat('MMM d').format(date),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 40,
                  interval: yAxisMax / 4,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primaryColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryColor,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
            minX: 0,
            maxX: (last7.length - 1).toDouble(),
            minY: 0,
            maxY: yAxisMax,
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '${barSpot.y.toStringAsFixed(2)} kWh',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build monthly energy chart (last 6 months)
  Widget _buildMonthlyChart(Map<String, double> data) {
    if (data.isEmpty) {
      return _buildEmptyChartPlaceholder('Not enough data for chart');
    }

    // Parse and sort by month; keep last 6 months
    final entries = data.entries.toList();
    final sortedEntries = entries
        .map((e) {
          try {
            final parts = e.key.split('-');
            if (parts.length == 2) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final date = DateTime(year, month);
              return MapEntry(date, e.value);
            }
            return null;
          } catch (_) {
            return null;
          }
        })
        .whereType<MapEntry<DateTime, double>>()
        .toList()
        ..sort((a, b) => a.key.compareTo(b.key)); // old → new

    // Keep last 6 months
    final last6 = sortedEntries.length > 6
        ? sortedEntries.sublist(sortedEntries.length - 6)
        : sortedEntries;

    if (last6.length < 2) {
      return _buildEmptyChartPlaceholder('Not enough data for chart');
    }

    // Find max value for Y-axis scaling
    final maxValue = last6.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yAxisMax = (maxValue * 1.2).ceilToDouble();

    // Create chart spots
    final spots = List<FlSpot>.generate(last6.length, (index) {
      return FlSpot(index.toDouble(), last6[index].value);
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withOpacity(0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 32, 16),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: false,
              horizontalInterval: yAxisMax / 4,
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < last6.length) {
                      final date = last6[index].key;
                      return Text(
                        DateFormat('MMM').format(date),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  reservedSize: 40,
                  interval: yAxisMax / 4,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primaryColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryColor,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
            ],
            minX: 0,
            maxX: (last6.length - 1).toDouble(),
            minY: 0,
            maxY: yAxisMax,
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    return LineTooltipItem(
                      '${barSpot.y.toStringAsFixed(2)} kWh',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Placeholder when not enough data
  Widget _buildEmptyChartPlaceholder(String message) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryColor.withOpacity(0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey.withOpacity(0.6),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

        return SingleChildScrollView(
          child: Column(
            children: [
              // Energy Chart with margin
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _buildDailyChart(data),
              ),
              // History List Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Daily Energy History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              // History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
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
              const SizedBox(height: 16), // Bottom padding
            ],
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

        return SingleChildScrollView(
          child: Column(
            children: [
              // Energy Chart with margin
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _buildMonthlyChart(data),
              ),
              // History List Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Monthly Energy History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              // History List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          child: Icon(
                            Icons.calendar_month,
                            color: AppTheme.primaryColor,
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
              const SizedBox(height: 16), // Bottom padding
            ],
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