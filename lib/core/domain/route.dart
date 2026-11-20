import 'fictional_data.dart';

({double lat, double lng}) positionOnRoute(int tick) {
  final totalKm = routeWaypoints.last.km;
  final fraction = (tick / totalTripMinutes).clamp(0.0, 1.0);
  final targetKm = fraction * totalKm;
  for (var index = 1; index < routeWaypoints.length; index++) {
    final start = routeWaypoints[index - 1];
    final end = routeWaypoints[index];
    if (targetKm <= end.km) {
      final segment = (targetKm - start.km) / (end.km - start.km);
      return (
        lat: start.lat + (end.lat - start.lat) * segment,
        lng: start.lng + (end.lng - start.lng) * segment,
      );
    }
  }
  final last = routeWaypoints.last;
  return (lat: last.lat, lng: last.lng);
}
