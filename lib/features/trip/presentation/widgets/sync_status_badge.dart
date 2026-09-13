import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final VoidCallback? onTap;

  const SyncStatusBadge({
    super.key,
    required this.isOnline,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    IconData icon;

    if (!isOnline) {
      badgeColor = AppColors.amber;
      label = pendingCount > 0 ? 'Offline ($pendingCount)' : 'Offline';
      icon = Icons.cloud_off_rounded;
    } else if (isSyncing) {
      badgeColor = AppColors.cyan;
      label = 'Backing up...';
      icon = Icons.sync_rounded;
    } else if (pendingCount > 0) {
      badgeColor = AppColors.amber;
      label = '$pendingCount Saved Locally';
      icon = Icons.cloud_queue_rounded;
    } else {
      badgeColor = AppColors.emerald;
      label = 'Backed Up';
      icon = Icons.cloud_done_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                ),
              )
            else
              Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
