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
const loggerCalibration = 'calibrated Oct 2026';
const laneLabel = 'Mumbai (BOM) → Delhi (DEL)';
const scenarioDateLabel = '21 Nov 2026';
const totalTripMinutes = 1110;
const initialTick = 45;
const deadZoneStartTick = 47;
const excursionJumpTick = 130;
const deadZoneEndTick = 140;
const outForDeliveryTick = 1050;
const deliveredTick = 1053;
const etaTick = 1110;
const defaultEscalationSeconds = 120;
const demoEscalationSeconds = 30;
const controlRoomNote = 'Simulated call for concept demo';
const smsControlRoomNote = 'GSM fallback · data channel weak';
const offlineToggleLabel = 'Offline (dead zone)';
const telemetryGapLabel = 'Telemetry gap (stale feed)';
const failNextSyncLabel = 'Fail next sync';
const epodHeldLabel = 'e-POD held locally — will send on reconnect';
const excursionLocation = 'Near Nashik hub · MH 04 KF 4001';
const acknowledgeLabel = 'Acknowledge';
const logActionLabel = 'Log action';
const callControlRoomLabel = 'Call control room';
const smsControlRoomLabel = 'SMS control room';
const smsSentLabel = 'SMS sent · GSM fallback';
const downloadAuditPdfLabel = 'Download audit PDF';
const pdfPreparingLabel = 'Preparing PDF…';
const pdfFailedLabel = 'Could not prepare the PDF — try again.';
const finalRecordTitle = 'Final record';
const custodySourceDriver = 'Driver app';
const custodySourceSensor = 'Sensor feed';
const custodySourceControlRoom = 'Control room';
const custodySourceSystem = 'System';
const sealVerifiedLabel = 'Seal verified';
const deliveredLabel = 'Delivered';
const deliveryNoteLabel = 'Delivery note (optional)';
const deliveryNoteOtherLabel = 'Other';
const deliveryNoteNoneLabel = 'None';
const deliveryNoteOptions = <String>[
  'Door closed at arrival',
  'Access delay',
  deliveryNoteOtherLabel,
];

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
  CustodyEvent(
    eventId: 'EVT-001',
    title: 'Dispatched',
    tick: 0,
    detail: 'Mumbai (BOM)',
    source: custodySourceSystem,
  ),
  CustodyEvent(
    eventId: 'EVT-002',
    title: 'Pre-trip checklist confirmed',
    tick: 8,
    source: custodySourceDriver,
    actor: driverName,
  ),
  CustodyEvent(
    eventId: 'EVT-003',
    title: 'AWB scanned',
    tick: 10,
    source: custodySourceDriver,
    actor: driverName,
  ),
  CustodyEvent(
    eventId: 'EVT-004',
    title: 'Seal verified',
    tick: 12,
    detail: 'SL-2291',
    source: custodySourceDriver,
    actor: driverName,
  ),
  CustodyEvent(
    eventId: 'EVT-005',
    title: 'Excursion detected',
    tick: 130,
    detail: '8.9 °C near Nashik hub',
    source: custodySourceSensor,
  ),
  CustodyEvent(
    eventId: 'EVT-006',
    title: 'Excursion acknowledged',
    tick: 131,
    detail: 'Compressor reset',
    source: custodySourceDriver,
    actor: driverName,
  ),
  CustodyEvent(
    eventId: 'EVT-007',
    title: 'Out for delivery',
    tick: 1050,
    source: custodySourceDriver,
    actor: driverName,
  ),
  CustodyEvent(
    eventId: 'EVT-008',
    title: 'Delivered · e-POD generated · Sent for invoicing',
    tick: 1053,
    source: custodySourceSystem,
  ),
];
