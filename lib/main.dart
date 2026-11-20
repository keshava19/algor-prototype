import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/domain/sample_assets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final signature = await rootBundle.load('assets/images/signature_sample.png');
  SampleAssets.signaturePng = signature.buffer.asUint8List();
  runApp(const ProviderScope(child: AlgorFieldApp()));
}
