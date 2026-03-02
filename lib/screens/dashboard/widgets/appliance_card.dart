
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/appliance.dart';
import '../../../theme/app_theme.dart';

class ApplianceCard extends StatelessWidget {
  final Appliance appliance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ApplianceCard({
    super.key,
    required this.appliance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // compute display time based on stats.lastCalcTime or live.timestamp
    final DateTime displayTime = (appliance.stats.lastCalcTime != 0)
        ? DateTime.fromMillisecondsSinceEpoch(appliance.stats.lastCalcTime * 1000,
                isUtc: true)
            .toLocal()
        : DateTime.fromMillisecondsSinceEpoch(appliance.live.timestamp,
                isUtc: true)
            .toLocal();
    final timeText = DateFormat('MMM d, hh:mm a').format(displayTime);
    final todayEnergy = appliance.stats.todayEnergy;
    final monthEnergy = appliance.stats.monthEnergy;
    
    return Card(
      elevation: appliance.peak ? 6 : 2,
      color: appliance.peak 
          ? AppTheme.errorColor.withOpacity(0.08)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: appliance.peak
            ? BorderSide(color: AppTheme.errorColor.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: title and menu (clean and simple)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appliance.id,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (String value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!();
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Timestamp below title
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          timeText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Current display: large and prominent (only current value)
                  Row(
                    children: [
                      Icon(
                        Icons.electric_bolt,
                        color: appliance.peak 
                            ? AppTheme.errorColor 
                            : AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${appliance.current.toStringAsFixed(2)} A',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: appliance.peak 
                                ? AppTheme.errorColor 
                                : AppTheme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Energy stats: stacked vertical layout
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today: ${todayEnergy.toStringAsFixed(2)} kWh',
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Month: ${monthEnergy.toStringAsFixed(2)} kWh',
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Footer: only device identifier
                  Row(
                    children: [
                      Icon(
                        Icons.router,
                        size: 13,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          appliance.deviceId ?? 'N/A',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // PEAK badge as corner overlay (top-right)
          if (appliance.peak)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'PEAK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}