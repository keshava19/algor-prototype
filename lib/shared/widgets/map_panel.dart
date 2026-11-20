import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/domain/fictional_data.dart';
import '../../core/theme/app_theme.dart';

class MapPanel extends StatefulWidget {
  const MapPanel({
    super.key,
    required this.truckPosition,
    required this.isExcursion,
    this.height = 260,
  });

  final ({double lat, double lng}) truckPosition;
  final bool isExcursion;
  final double height;

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  int _tileErrors = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final routePoints = [
      for (final waypoint in routeWaypoints) LatLng(waypoint.lat, waypoint.lng),
    ];
    final truck = LatLng(widget.truckPosition.lat, widget.truckPosition.lng);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(color: scheme.outlineVariant),
              ),
            ),
            FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(routePoints),
                  padding: const EdgeInsets.all(28),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
                backgroundColor: AppColors.navy,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.algorfield.algor_field',
                  errorTileCallback: (_, _, _) {
                    if (mounted) setState(() => _tileErrors++);
                  },
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: AppColors.cyan.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: truck,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.isExcursion
                              ? AppColors.danger
                              : AppColors.cyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navy, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            if (_tileErrors > 6)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Offline map preview',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}
