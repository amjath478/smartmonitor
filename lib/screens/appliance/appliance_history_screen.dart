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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status & Forecast section
              Consumer<FirebaseService>(
                builder: (context, firebaseService, child) {
                  return StreamBuilder<List<Device>>(
                    stream: firebaseService.getDevicesStream(),
                    initialData: const [],
                    builder: (context, snapshot) {
                      // locate current appliance
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

                      // status card widget
                      final statusCard = Container(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Current Status',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    if (currentAppliance.peak)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor,
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatusItem(
                                          icon: Icons.electric_bolt,
                                          label: 'Current',
                                          value:
                                              '${currentAppliance.live.current.toStringAsFixed(2)} A',
                                          color: currentAppliance.peak
                                              ? AppTheme.errorColor
                                              : AppTheme.primaryColor,
                                        ),
                                        _StatusItem(
                                          icon: Icons.flash_on,
                                          label: 'Power',
                                          value:
                                              '${currentAppliance.live.power.toStringAsFixed(0)} W',
                                          color: Colors.orange,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatusItem(
                                          icon: Icons.bolt,
                                          label: 'Today',
                                          value:
                                              '${currentAppliance.stats.todayEnergy.toStringAsFixed(2)} kWh',
                                          color: Colors.green,
                                        ),
                                        _StatusItem(
                                          icon: Icons.calendar_month,
                                          label: 'Month',
                                          value:
                                              '${currentAppliance.stats.monthEnergy.toStringAsFixed(2)} kWh',
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

                      final forecastCard = PredictionCard(
                        deviceId: widget.appliance.deviceId ?? '',
                        applianceId: widget.appliance.id,
                        historyType: _historyType,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 600) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: statusCard),
                                  const SizedBox(width: 12),
                                  Expanded(child: forecastCard),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  statusCard,
                                  const SizedBox(height: 8),
                                  forecastCard,
                                ],
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
          
          // Energy History Section with custom buttons
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Energy History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Consumer<FirebaseService>(
            builder: (context, firebaseService, child) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Daily'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _historyType == 'daily'
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              foregroundColor: _historyType == 'daily'
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                            onPressed: () {
                              setState(() => _historyType = 'daily');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Monthly'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _historyType == 'monthly'
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              foregroundColor: _historyType == 'monthly'
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                            onPressed: () {
                              setState(() => _historyType = 'monthly');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // History Content
                  _historyType == 'daily'
                      ? _buildDailyHistory(context, firebaseService)
                      : _buildMonthlyHistory(context, firebaseService),
                ],
              );
            },
          ),
        ],
      ),
    ),
  ),
); // end Scaffold
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

        // chart fixed at top, list built as shrink-wrapped so parent scroll handles it
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildDailyChart(data),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Daily Energy History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
            const SizedBox(height: 16),
          ],
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMonthlyChart(data),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Monthly Energy History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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
            const SizedBox(height: 16),
          ],
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

/// Prediction card showing next-day forecast based on linear regression
class PredictionCard extends StatelessWidget {
  final String deviceId;
  final String applianceId;
  final String historyType; // 'daily' or 'monthly'

  const PredictionCard({
    super.key,
    required this.deviceId,
    required this.applianceId,
    required this.historyType,
  });

  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    final stream = historyType == 'monthly'
        ? firebase.getMonthlyEnergyHistory(deviceId, applianceId)
        : firebase.getDailyEnergyHistory(deviceId, applianceId);

    return StreamBuilder<Map<String, double>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data ?? {};
        // convert keys to DateTime; monthly keys lack day so append first day
        final processed = data.entries
            .map((e) {
              String key = e.key;
              DateTime? dt;
              try {
                dt = DateTime.parse(key);
              } catch (_) {
                // try adding day for month strings like YYYY-MM
                try {
                  dt = DateTime.parse('$key-01');
                } catch (_) {
                  dt = null;
                }
              }
              if (dt != null) return MapEntry(dt, e.value);
              return null;
            })
            .whereType<MapEntry<DateTime, double>>()
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        if (processed.length < 5) {
          final unit = historyType == 'monthly' ? 'months' : 'days';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Prediction unavailable. Minimum 5 $unit required.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        // compute linear regression on y-values (x = 1..n)
        final values = processed.map((e) => e.value).toList();
        final n = values.length;
        double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        for (var i = 0; i < n; i++) {
          final x = i + 1;
          final y = values[i];
          sumX += x;
          sumY += y;
          sumXY += x * y;
          sumX2 += x * x;
        }
        final denom = n * sumX2 - sumX * sumX;
        double m = 0, bIntercept = 0;
        if (denom != 0) {
          m = (n * sumXY - sumX * sumY) / denom;
          bIntercept = (sumY - m * sumX) / n;
        }

        final nextX = n + 1;
        double prediction = m * nextX + bIntercept;
        if (prediction < 0) prediction = 0;

        // print equation and data numbers
        debugPrint('Linear regression equation: y = ${m.toStringAsFixed(4)}x + ${bIntercept.toStringAsFixed(4)}');
        debugPrint('Data points used: $n');
        debugPrint('Prediction (next x=$nextX): ${prediction.toStringAsFixed(4)}');

        // r^2 calculation
        final meanY = sumY / n;
        double sst = 0, ssr = 0;
        for (var i = 0; i < n; i++) {
          final x = i + 1;
          final y = values[i];
          final yPred = m * x + bIntercept;
          sst += (y - meanY) * (y - meanY);
          ssr += (y - yPred) * (y - yPred);
        }
        double r2 = sst == 0 ? 1.0 : 1 - (ssr / sst);
        if (r2.isNaN) r2 = 0;
        r2 = r2.clamp(0, 1);
        final confidence = (r2 * 100).clamp(0, 100);
        String trend = 'Stable';
        if (m > 0) trend = 'Increasing';
        else if (m < 0) trend = 'Decreasing';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.2),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Energy Forecast',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      trend == 'Increasing'
                          ? Icons.trending_up
                          : trend == 'Decreasing'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${prediction.toStringAsFixed(2)} kWh',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Trend: $trend'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: confidence / 100,
                        color: AppTheme.primaryColor,
                        backgroundColor:
                            AppTheme.primaryColor.withOpacity(0.2),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${confidence.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Data points: $n'),
                const SizedBox(height: 8),
                Text(
                  'Confidence indicates how closely the line follows past values',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}