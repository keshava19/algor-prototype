import 'package:intl/intl.dart';

import '../domain/fictional_data.dart';

final _clockFormat = DateFormat('HH:mm');
final _dateTimeFormat = DateFormat('d MMM yyyy HH:mm');

String formatClock(int tick) => _clockFormat.format(scenarioTime(tick));

String formatDateTime(int tick) => _dateTimeFormat.format(scenarioTime(tick));

String formatTemp(double celsius) => '${celsius.toStringAsFixed(1)} °C';

String formatCoordinate(double lat, double lng) =>
    '${lat.abs().toStringAsFixed(2)}° ${lat >= 0 ? 'N' : 'S'}, '
    '${lng.abs().toStringAsFixed(2)}° ${lng >= 0 ? 'E' : 'W'}';

String formatWatermark(({double lat, double lng}) position, int tick) =>
    '${formatCoordinate(position.lat, position.lng)} · '
    '${formatDateTime(tick)} IST · $vehiclePlate';

String formatRemaining(int tick) {
  final remaining = etaTick - tick;
  if (remaining <= 0) return 'Arriving';
  final hours = remaining ~/ 60;
  final minutes = remaining % 60;
  return '$hours h $minutes m';
}

String formatCountdown(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$secs';
}
