import 'dart:math' as math;

/// Straight-line distance and simple road ETA heuristics (no routing API).
class GeoEta {
  GeoEta._();

  static const double _earthRadiusKm = 6371.0;

  /// Returns great-circle distance between two WGS84 points in kilometers.
  static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// Heuristic ETA in whole minutes from straight-line [distanceKm] at [averageSpeedKmh].
  static int etaMinutesFromDistanceKm(double distanceKm, {double averageSpeedKmh = 35}) {
    if (distanceKm.isNaN || distanceKm.isInfinite) return 0;
    if (distanceKm <= 0) return 1;
    if (averageSpeedKmh <= 0) return 1;
    final minutes = (distanceKm / averageSpeedKmh * 60).ceil();
    return minutes.clamp(1, 24 * 60);
  }

  /// Provider → customer ETA using haversine distance and [averageSpeedKmh].
  static int etaMinutesBetweenPoints(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng, {
    double averageSpeedKmh = 35,
  }) {
    final km = haversineKm(fromLat, fromLng, toLat, toLng);
    return etaMinutesFromDistanceKm(km, averageSpeedKmh: averageSpeedKmh);
  }
}
