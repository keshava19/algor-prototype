import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/client_view/client_shipment_detail.dart';
import '../features/client_view/client_shipments_screen.dart';
import '../features/driver_flow/driver_flow_screen.dart';
import '../features/ops_monitor/ops_monitor_screen.dart';
import '../features/role_picker/role_picker_screen.dart';
import '../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const RolePickerScreen(),
          ),
          GoRoute(
            path: '/ops',
            builder: (context, state) => const OpsMonitorScreen(),
          ),
          GoRoute(
            path: '/driver',
            builder: (context, state) => const DriverFlowScreen(),
          ),
          GoRoute(
            path: '/client',
            builder: (context, state) => const ClientShipmentsScreen(),
          ),
          GoRoute(
            path: '/client/live',
            builder: (context, state) =>
                const ClientShipmentDetail(sample: false),
          ),
          GoRoute(
            path: '/client/sample',
            builder: (context, state) =>
                const ClientShipmentDetail(sample: true),
          ),
        ],
      ),
    ],
  ),
);
