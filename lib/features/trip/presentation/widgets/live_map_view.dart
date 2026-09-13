import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/location_point.dart';

class LiveMapView extends StatefulWidget {
  final List<LocationPoint> points;
  final LocationPoint? currentLocation;
  final bool isDarkMode;
  final bool isTracking;
  final bool autoCenter;

  const LiveMapView({
    super.key,
    required this.points,
    this.currentLocation,
    this.isDarkMode = true,
    this.isTracking = false,
    this.autoCenter = true,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_followUser && widget.currentLocation != null) {
      final target = widget.currentLocation!.toLatLng();
      _mapController.move(target, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenter() {
    setState(() => _followUser = true);
    if (widget.currentLocation != null) {
      _mapController.move(
        widget.currentLocation!.toLatLng(),
        AppConstants.defaultZoom,
      );
    } else if (widget.points.isNotEmpty) {
      _mapController.move(
        widget.points.last.toLatLng(),
        AppConstants.defaultZoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerPos = widget.currentLocation?.toLatLng() ??
        (widget.points.isNotEmpty
            ? widget.points.last.toLatLng()
            : AppConstants.defaultLocation);

    final polylineCoords = widget.points.map((p) => p.toLatLng()).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPos,
            initialZoom: AppConstants.defaultZoom,
            minZoom: 4,
            maxZoom: 19,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _followUser) {
                setState(() => _followUser = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              subdomains: AppConstants.mapSubdomains,
              userAgentPackageName: 'com.rider.app',
              tileBuilder: widget.isDarkMode
                  ? (context, tileWidget, tile) {
                      return ColorFiltered(
                        colorFilter: const ColorFilter.matrix(<double>[
                          -0.75, 0,     0,     0, 210,
                          0,     -0.75, 0,     0, 210,
                          0,     0,     -0.70, 0, 220,
                          0,     0,     0,     1, 0,
                        ]),
                        child: tileWidget,
                      );
                    }
                  : null,
            ),

            if (polylineCoords.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylineCoords,
                    strokeWidth: 9.0,
                    color: AppColors.cyan.withAlpha(80),
                  ),
                  Polyline(
                    points: polylineCoords,
                    strokeWidth: 4.5,
                    color: AppColors.cyan,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (widget.points.isNotEmpty)
                  Marker(
                    point: widget.points.first.toLatLng(),
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withAlpha(150),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),

                if (widget.currentLocation != null)
                  Marker(
                    point: widget.currentLocation!.toLatLng(),
                    width: 48,
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseScale = 1.0 + (_pulseController.value * 0.35);
                        final pulseOpacity = 1.0 - (_pulseController.value * 0.6);

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: pulseScale,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan.withAlpha(
                                    (pulseOpacity * 100).toInt(),
                                  ),
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: (widget.currentLocation?.heading ?? 0) *
                                   (3.14159265 / 180.0),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.cyan.withAlpha(180),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),

        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'map_recenter_btn',
            backgroundColor: _followUser ? AppColors.cyan : AppColors.surface,
            foregroundColor: _followUser ? Colors.black : AppColors.textPrimary,
            onPressed: _recenter,
            child: Icon(
              _followUser
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
