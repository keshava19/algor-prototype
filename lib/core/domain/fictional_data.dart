import 'models.dart';

const appTitle = 'Algor Field (Concept)';
const conceptFooterText = 'Concept prepared for Algor — mock data only';
const awbNumber = '172-45678901';
const awbLabel = 'AWB $awbNumber';
const vehiclePlate = 'MH 04 KF 4001';
const driverName = 'S. Pawar';
const driverInitials = 'SP';
const consigneeName = 'R. Menon';
const consigneeHub = 'DelPharma Distribution Hub, Gurugram';
const defaultSealNumber = 'SL-2291';
const loggerId = 'LG-2214';
const productLabel = 'Pharma · 2–8 °C';
const laneLabel = 'Mumbai (BOM) → Delhi (DEL)';
const scenarioDateLabel = '21 Nov 2026';
const bandMin = 2.0;
const bandMax = 8.0;
const setPointTemp = 4.0;
const excursionTemp = 8.9;
const totalTripMinutes = 1110;
const initialTick = 45;
const excursionJumpTick = 130;
const outForDeliveryTick = 1050;
const deliveredTick = 1053;
const etaTick = 1110;
const defaultEscalationSeconds = 120;
const demoEscalationSeconds = 30;
const controlRoomNote = 'Simulated call for concept demo';
const offlineToggleLabel = 'Offline (dead zone)';
const epodHeldLabel = 'e-POD held locally — will send on reconnect';
const excursionTitle = 'Reefer 8.9 °C — outside 2–8 °C band';
const excursionLocation = 'Near Nashik hub · MH 04 KF 4001';
const acknowledgeLabel = 'Acknowledge';
const logActionLabel = 'Log action';
const callControlRoomLabel = 'Call control room';
const downloadAuditPdfLabel = 'Download audit PDF';
const sealVerifiedLabel = 'Seal verified';
const deliveredLabel = 'Delivered';

String offlineBanner(int items) =>
    'Offline mode: highway dead zone — $items '
    '${items == 1 ? 'item' : 'items'} queued, will sync';

DateTime scenarioTime(int tick) =>
    DateTime(2026, 11, 21, 4, 15).add(Duration(minutes: tick));

typedef RouteWaypoint = ({double lat, double lng, double km});

const routeWaypoints = <RouteWaypoint>[
  (lat: 19.0760, lng: 72.8777, km: 0),
  (lat: 19.9975, lng: 73.7898, km: 165),
  (lat: 20.9042, lng: 74.7749, km: 315),
  (lat: 22.7196, lng: 75.8577, km: 585),
  (lat: 26.2183, lng: 78.1828, km: 1055),
  (lat: 27.1767, lng: 78.0081, km: 1175),
  (lat: 28.6139, lng: 77.2090, km: 1405),
];

const defaultChecklist = <ChecklistEntry>[
  ChecklistEntry(title: 'Pre-cooled to set-point', reading: '4.0 °C'),
  ChecklistEntry(title: 'Logger armed', reading: 'LG-2214'),
  ChecklistEntry(title: 'Dock seal intact', reading: 'Intact'),
  ChecklistEntry(title: 'Reefer clean', reading: 'Clean'),
];

const canonicalCustody = <CustodyEvent>[
  CustodyEvent(title: 'Dispatched', tick: 0, detail: 'Mumbai (BOM)'),
  CustodyEvent(title: 'Pre-trip checklist confirmed', tick: 8),
  CustodyEvent(title: 'AWB scanned', tick: 10),
  CustodyEvent(title: 'Seal verified', tick: 12, detail: 'SL-2291'),
  CustodyEvent(
    title: 'Excursion detected',
    tick: 130,
    detail: '8.9 °C near Nashik hub',
  ),
  CustodyEvent(
    title: 'Excursion acknowledged',
    tick: 131,
    detail: 'Compressor reset',
  ),
  CustodyEvent(title: 'Out for delivery', tick: 1050),
  CustodyEvent(
    title: 'Delivered · e-POD generated · Sent for invoicing',
    tick: 1053,
  ),
];
