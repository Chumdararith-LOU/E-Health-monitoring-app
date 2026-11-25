// FR-10, FR-11 / US-10, US-11: max / min / average per period, and a chart
// per measure with normal-range bands.
// Fetches live /summary + /series from the API when signed in with a dev token,
// falling back cleanly to local demo readings when the API is offline or empty.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_models.dart';
import '../../api/reports_repository.dart';
import '../../data/ranges.dart';
import '../../data/stats.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../history/reading_detail_screen.dart';
import '../shell.dart';

/// 7, 30, 90 days; -1 = custom.
const _custom = -1;
const _hideDevBanner = bool.fromEnvironment('HIDE_DEV');

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _period = 30;
  DayRange? _customRange;

  String? _lastQueryKey;
  int _reqId = 0;
  LivePatientReport? _liveReport;
  ApiClientException? _apiError;
  bool _apiLoading = false;

  DayRange _currentRange() =>
      _period == _custom && _customRange != null ? _customRange! : lastNDays(_period == _custom ? 30 : _period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLiveReport(AppScope.of(context));
  }

  void _syncLiveReport(AppState st, {bool force = false}) {
    final patient = st.patient;
    final token = st.token;
    if (patient == null || token == null || !st.canView(patient.id)) {
      _lastQueryKey = null;
      _reqId++;
      _liveReport = null;
      _apiError = null;
      _apiLoading = false;
      return;
    }

    final range = _currentRange();
    final apiDays = range.days.clamp(1, 365);
    final fieldKeys = [
      for (final k in measureOrder) k.name,
      for (final f in st.data.fields) f.id,
    ];
    final queryKey = '$token|${patient.id}|$apiDays|${fieldKeys.join(",")}';
    if (!force && queryKey == _lastQueryKey) return;

    _lastQueryKey = queryKey;
    final currentReq = ++_reqId;
    _apiLoading = true;
    _apiError = null;

    unawaited(
      st.reportsRepo
          .fetchPatientReport(patient.id, fieldKeys: fieldKeys, days: apiDays, token: token)
          .then((report) {
        if (!mounted || currentReq != _reqId) return;
        setState(() {
          _liveReport = report;
          _apiError = null;
          _apiLoading = false;
        });
      }).catchError((Object err) {
        if (!mounted || currentReq != _reqId) return;
        setState(() {
          _liveReport = null;
          _apiError = err is ApiClientException
              ? err
              : const ApiClientException(status: 0, code: 'unknown', messageKey: 'errors.internal_error');
          _apiLoading = false;
        });
      }),
    );
  }

  Future<void> _pickRange() async {
    final c = _customRange;
    final r = await showDateRangeSheet(context, initial: c == null ? null : (c.from, c.to));
    if (r != null) {
      setState(() {
        _customRange = customRange(r.$1, r.$2);
        _period = _custom;
        _syncLiveReport(AppScope.read(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final patient = st.patient;
    if (patient == null) {
      return AppScreen(children: [EmptyState(icon: Mdi.chartLine, title: t('noLinkedPatients'))]);
    }

    final range = _currentRange();
    final apiDays = range.days.clamp(1, 365);
    final readings = inRange(st.readingsOf(patient.id), range).reversed.toList();
    final fields = st.data.fields;
    final liveSummary = _liveReport?.summary;
    final liveSeries = _liveReport?.series;

    final rows = [
      for (final k in measureOrder)
        (
          t('m_${k.name}'),
          measures[k]!.unit,
          pickFieldStat(liveSummary, k.name, statOf(readings, (r) => r.valueOf(k))),
          0,
        ),
      for (final f in fields)
        (
          i18n.name(f),
          f.unit,
          pickFieldStat(liveSummary, f.id, statOf(readings, (r) => r.extra[f.id])),
          f.decimals,
        ),
    ];

    List<ChartPoint> demoPts(double? Function(Reading) get) => [
          for (final r in readings)
            if (get(r) != null) ChartPoint(r.takenAt, get(r)!, r.id),
        ];
    List<ChartPoint> pts(String fieldKey, double? Function(Reading) get) =>
        pickChartPoints(liveSeries, fieldKey, demoPts(get));
    (double, double) band(MeasureKey k) => (measures[k]!.normalMin, measures[k]!.normalMax);

    final from = range.from;
    final now = DateTime.now();
    final to = DateTime.fromMillisecondsSinceEpoch(math.min(range.to.millisecondsSinceEpoch, now.millisecondsSinceEpoch));

    final charts = [
      (t('bp'), 'mmHg', 0, [
        ChartSeries(
          key: 'sys',
          label: t('m_systolic'),
          color: C.series1,
          points: pts('systolic', (r) => r.systolic),
          band: band(MeasureKey.systolic),
        ),
        ChartSeries(
          key: 'dia',
          label: t('m_diastolic'),
          color: C.series2,
          points: pts('diastolic', (r) => r.diastolic),
          band: band(MeasureKey.diastolic),
        ),
      ]),
      (t('m_glucose'), 'mg/dL', 0, [
        ChartSeries(
          key: 'glu',
          label: t('m_glucose'),
          color: C.series1,
          points: pts('glucose', (r) => r.glucose),
          band: band(MeasureKey.glucose),
        ),
      ]),
      (t('m_pulse'), 'bpm', 0, [
        ChartSeries(
          key: 'pul',
          label: t('m_pulse'),
          color: C.series1,
          points: pts('pulse', (r) => r.pulse),
          band: band(MeasureKey.pulse),
        ),
      ]),
      for (final f in fields)
        (i18n.name(f), f.unit, f.decimals, [
          ChartSeries(key: f.id, label: i18n.name(f), color: C.series1, points: pts(f.id, (r) => r.extra[f.id])),
        ]),
    ];

    void openReading(String id) {
      final match = st.readingById(id) ??
          readings.where((r) => r.takenAt.toIso8601String() == id).firstOrNull;
      if (match != null) {
        push(context, ReadingDetailScreen(id: match.id));
      }
    }

    final recordedDays = liveSummary != null && liveSummary.fields.isNotEmpty
        ? math.max(0, apiDays - liveSummary.missedDays)
        : daysWithReadings(readings);

    Widget th(String s, {int flex = 10, TextAlign align = TextAlign.right}) => Expanded(
          flex: flex,
          child: AppText(s, variant: TextVariant.caption, weight: W.semibold, color: C.textMuted, align: align),
        );

    return AppScreen(children: [
      const PatientSwitcher(),
      Segmented<int>(
        label: t('period'),
        value: _period,
        onChanged: (p) {
          if (p == _custom) {
            _pickRange();
          } else {
            setState(() {
              _period = p;
              _syncLiveReport(st);
            });
          }
        },
        options: [
          SegOption(7, t('nDays', {'n': 7})),
          SegOption(30, t('nDays', {'n': 30})),
          SegOption(90, t('nDays', {'n': 90})),
          SegOption(_custom, t('filterCustom')),
        ],
      ),
      if (_apiError != null) ...[
        AppBanner(
          kind: BannerKind.error,
          icon: _apiError!.status == 403 ? Mdi.lockOutline : Mdi.alertCircleOutline,
          text: i18n.apiError(_apiError!.messageKey),
        ),
        if (_apiError!.status != 403)
          AppButton(
            variant: BtnVariant.secondary,
            compact: true,
            label: t('retry'),
            onPressed: () => setState(() => _syncLiveReport(st, force: true)),
          ),
      ] else if (!_hideDevBanner && _apiLoading)
        AppBanner(text: t('liveApiLoading'))
      else if (!_hideDevBanner && liveSummary != null)
        AppBanner(
          text: t('liveApiConnected', {
                'fields': liveSummary.fields.length,
                'missed': liveSummary.missedDays,
                'outOfRange': liveSummary.outOfRangeCount,
              }) +
              (liveSummary.fields.isEmpty && !hasLiveSeriesData(liveSeries) ? ' ${t('liveApiDemoFallback')}' : ''),
        ),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppText('${i18n.date(range.from)} – ${i18n.date(range.to)}', weight: W.semibold),
        AppText(t('daysRecorded', {'n': recordedDays, 'total': range.days}),
            variant: TextVariant.caption, color: C.textMuted),
      ]),
      AppCard(children: [
        AppText(t('summary'), variant: TextVariant.heading),
        Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.sm),
            child: Gap(children: [th(' ', flex: 16), th(t('min')), th(t('avg')), th(t('max'))]),
          ),
          for (final (label, unit, stat, dec) in rows) ...[
            const AppDivider(),
            Semantics(
              label: '$label: ${t('min')} ${i18n.n(stat.min, dec)}, ${t('avg')} ${i18n.n(stat.avg, dec)}, '
                  '${t('max')} ${i18n.n(stat.max, dec)} $unit',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.sm),
                child: Gap(children: [
                  Expanded(
                    flex: 16,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText(label, variant: TextVariant.label, weight: W.medium),
                      AppText(unit, variant: TextVariant.caption, color: C.textMuted),
                    ]),
                  ),
                  Expanded(flex: 10, child: AppText(i18n.n(stat.min, dec), align: TextAlign.right)),
                  Expanded(flex: 10, child: AppText(i18n.n(stat.avg, dec), align: TextAlign.right, weight: W.bold)),
                  Expanded(flex: 10, child: AppText(i18n.n(stat.max, dec), align: TextAlign.right)),
                ]),
              ),
            ),
          ],
        ]),
      ]),
      for (final (title, unit, dec, series) in charts)
        _ChartCard(
          key: ValueKey('$title-$_period-${from.millisecondsSinceEpoch}'),
          title: title,
          unit: unit,
          series: series,
          from: from,
          to: to,
          decimals: dec,
          onOpen: openReading,
        ),
      AppButton(
        variant: BtnVariant.ghost,
        icon: Mdi.filePdfBox,
        label: t('exportPdf'),
        onPressed: () => showToast(context, t('exportSoon'), info: true),
      ),
    ]);
  }
}

class _ChartCard extends StatefulWidget {
  const _ChartCard({
    super.key,
    required this.title,
    required this.unit,
    required this.series,
    required this.from,
    required this.to,
    required this.decimals,
    required this.onOpen,
  });

  final String title;
  final String unit;
  final List<ChartSeries> series;
  final DateTime from, to;
  final int decimals;
  final ValueChanged<String> onOpen;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  bool _asTable = false;

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final t = i18n.t;
    final series = widget.series;
    final empty = series.every((s) => s.points.isEmpty);

    Widget table() {
      Widget cell(String s, {int flex = 10, bool head = false, TextAlign align = TextAlign.right}) => Expanded(
            flex: flex,
            child: AppText(
              s,
              variant: head ? TextVariant.caption : TextVariant.label,
              weight: head ? W.semibold : null,
              color: head ? C.textMuted : C.text,
              align: align,
              maxLines: head ? 1 : null,
            ),
          );
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Sp.sm),
          child: Gap(children: [
            cell(t('date'), flex: 14, head: true, align: TextAlign.left),
            for (final s in series) cell(s.label, head: true),
          ]),
        ),
        for (final p in series.first.points.reversed) ...[
          const AppDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Sp.sm),
            child: Gap(children: [
              cell(i18n.dateShort(p.t), flex: 14, align: TextAlign.left),
              for (final s in series)
                cell(i18n.n(s.points.where((q) => q.id == p.id).firstOrNull?.v, widget.decimals)),
            ]),
          ),
        ],
      ]);
    }

    return AppCard(children: [
      Row(children: [
        Expanded(child: AppText(widget.title, variant: TextVariant.heading)),
        AppText(widget.unit, variant: TextVariant.caption, color: C.textMuted),
      ]),
      if (empty)
        AppText(t('noData'), color: C.textMuted)
      else if (_asTable)
        table()
      else
        LineChart(
          series: series,
          from: widget.from,
          to: widget.to,
          decimals: widget.decimals,
          onOpen: widget.onOpen,
        ),
      if (!empty)
        AppButton(
          variant: BtnVariant.ghost,
          compact: true,
          icon: _asTable ? Mdi.chartLine : Mdi.table,
          label: _asTable ? t('chartView') : t('tableView'),
          onPressed: () => setState(() => _asTable = !_asTable),
        ),
    ]);
  }
}
