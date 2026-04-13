import 'boostdrive_maps_web_types.dart';
import 'google_maps_web_loader_stub.dart'
    if (dart.library.html) 'google_maps_web_loader_web.dart' as impl;

Future<BoostdriveMapsWebLoad> ensureBoostdriveMapsReadyOnWeb() =>
    impl.ensureBoostdriveMapsReadyOnWeb();
