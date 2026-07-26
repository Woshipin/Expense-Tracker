import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/toast.dart';
import '../categories/category_view.dart';
import '../shared/crud_helpers.dart';

// ============================================================
// MODELS
// ============================================================

class CalendarRecord {
  final int id;
  final String type; // 'expense' | 'income'
  final String title;
  final String description;
  final double price;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm
  final int paymentMethodId;
  final int categoryId;

  CalendarRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.date,
    required this.time,
    required this.paymentMethodId,
    required this.categoryId,
  });

  factory CalendarRecord.fromJson(Map<String, dynamic> json) {
    final rawDate = '${json['date'] ?? ''}';
    final rawTime = '${json['time'] ?? ''}';
    return CalendarRecord(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      type: '${json['type'] ?? 'expense'}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      date: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      time: rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime,
      paymentMethodId: int.tryParse('${json['payment_method_id'] ?? 0}') ?? 0,
      categoryId: int.tryParse('${json['category_id'] ?? 0}') ?? 0,
    );
  }
}

class PaymentMethodItem {
  final int id;
  final String name;
  final int typeId;
  final int status;
  PaymentMethodItem({
    required this.id,
    required this.name,
    required this.typeId,
    required this.status,
  });
  factory PaymentMethodItem.fromJson(Map<String, dynamic> json) {
    return PaymentMethodItem(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      name: '${json['name'] ?? ''}',
      typeId: int.tryParse('${json['type_id'] ?? 1}') ?? 1,
      status: int.tryParse('${json['status'] ?? 1}') ?? 1,
    );
  }
}

String _pad2(int n) => n.toString().padLeft(2, '0');
String _formatDate(int y, int m, int d) => '$y-${_pad2(m)}-${_pad2(d)}';
String _formatPrice(num price) => price.toStringAsFixed(2);

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

// ============================================================
// MAIN CALENDAR VIEW
// ============================================================

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _currentDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  List<CalendarRecord> _calendarData = [];
  bool _isLoading = false;

  List<TypeItem> _typesList = [];
  List<CategoryItem> _allCategories = [];
  List<PaymentMethodItem> _allMethods = [];

  String? _selectedDateStr;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
    _fetchCalendarData();
  }

  // 动态获取 active 状态的 Types, Categories 和 Payment Methods
  Future<void> _fetchOptions() async {
    try {
      final results = await Future.wait([
        ApiClient().dio.get('/types', queryParameters: {'status': '1'}),
        ApiClient().dio.get('/categories', queryParameters: {'status': '1'}),
        ApiClient().dio.get(
          '/payment-methods',
          queryParameters: {'status': '1'},
        ),
      ]);

      final rawTypes = parsePaged(results[0].data).items;
      final rawCats = parsePaged(results[1].data).items;
      final rawMethods = parsePaged(results[2].data).items;

      if (!mounted) return;
      setState(() {
        _typesList = rawTypes
            .map((t) => TypeItem.fromJson(t))
            .where((t) => t.status == 1)
            .toList();
        _allCategories = rawCats
            .map((c) => CategoryItem.fromJson(c))
            .where((c) => c.status == 1)
            .toList();
        _allMethods = rawMethods
            .map((m) => PaymentMethodItem.fromJson(m))
            .where((m) => m.status == 1)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchCalendarData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().dio.get(
        '/calendar',
        queryParameters: {
          'year': _currentDate.year,
          'month': _currentDate.month,
        },
      );
      final payload = response.data;
      final List<dynamic> raw = payload is Map<String, dynamic>
          ? (payload['data'] as List<dynamic>? ?? [])
          : (payload as List<dynamic>? ?? []);
      setState(() {
        _calendarData = raw
            .map((e) => CalendarRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (_) {
      if (mounted)
        SunsetToast.show(
          context,
          'Failed to fetch calendar data.',
          type: SunsetToastType.error,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CalendarRecord> _getRecordsForDate(String dateStr) =>
      _calendarData.where((r) => r.date == dateStr).toList();

  Future<void> _handlePrevMonth() async {
    setState(
      () =>
          _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1),
    );
    await _fetchCalendarData();
  }

  Future<void> _handleNextMonth() async {
    setState(
      () =>
          _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1),
    );
    await _fetchCalendarData();
  }

  Future<void> _saveRecord(
    String endpoint,
    Map<String, dynamic> data,
    int? editingId,
  ) async {
    if (editingId != null) {
      await ApiClient().dio.put('$endpoint/$editingId', data: data);
    } else {
      await ApiClient().dio.post(endpoint, data: data);
    }
  }

  Future<void> _deleteRecord(CalendarRecord record) async {
    final endpoint = record.type == 'income' ? '/incomes' : '/expenses';
    try {
      await ApiClient().dio.delete('$endpoint/${record.id}');
      if (mounted) SunsetToast.show(context, 'Record deleted successfully');
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['error'] ?? e.response?.data['message'])
          : null;
      if (mounted)
        SunsetToast.show(
          context,
          message?.toString() ?? 'Failed to delete record',
          type: SunsetToastType.error,
        );
    }
  }

  Future<void> _handleDayClick(int day) async {
    final dateStr = _formatDate(_currentDate.year, _currentDate.month, day);
    setState(() => _selectedDateStr = dateStr);
    await _openRecordListDialog(dateStr);
  }

  Future<void> _openRecordListDialog(String dateStr) async {
    await showDialog<void>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (dialogContext) => RecordListDialog(
        dateStr: dateStr,
        initialRecords: _getRecordsForDate(dateStr),
        refreshRecords: () async {
          await _fetchCalendarData();
          return _getRecordsForDate(dateStr);
        },
        onOpenForm: (record) {
          Navigator.pop(dialogContext);
          _openFormDialog(record, dateStr);
        },
        onDelete: _deleteRecord,
      ),
    );
  }

  Future<void> _openFormDialog(
    CalendarRecord? record,
    String? contextDateStr,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (dialogContext) => RecordFormDialog(
        editing: record,
        defaultDateStr: contextDateStr,
        typesList: _typesList,
        allCategories: _allCategories,
        allMethods: _allMethods,
        onSave: _saveRecord,
      ),
    );
    if (saved == true) await _fetchCalendarData();
    if (contextDateStr != null && mounted)
      await _openRecordListDialog(contextDateStr);
  }

  double _getResponsiveAspectRatio(double width) {
    if (width >= 1100) return 1.6;
    if (width >= 700) return 1.2;
    return 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final startOffset = firstWeekday - 1;
    final now = DateTime.now();
    final todayStr = _formatDate(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: SunsetColors.bgStart,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 900;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 18,
                24,
                isWide ? 32 : 18,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isWide),
                  const SizedBox(height: 20),
                  _buildCalendarCard(
                    year,
                    month,
                    daysInMonth,
                    startOffset,
                    todayStr,
                    width,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🌟 移动端 Add Record 按钮强行保持单行 (whitespace-nowrap & shrink-0)
  Widget _buildHeader(bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Calendar',
                style: TextStyle(
                  color: SunsetColors.dark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Review your transactions day-by-day.',
                style: TextStyle(
                  color: Color(0x992D2520),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _openFormDialog(null, _selectedDateStr),
          icon: const Icon(Icons.add, size: 16),
          label: const Text(
            'Add Record',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: SunsetColors.secondary,
            foregroundColor: Colors.white,
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(
    int year,
    int month,
    int daysInMonth,
    int startOffset,
    String todayStr,
    double width,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SunsetColors.primary.withValues(alpha: 0.20),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_monthNames[month - 1]} $year',
                    style: const TextStyle(
                      color: SunsetColors.dark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SunsetColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _navButton(icon: Icons.chevron_left, onTap: _handlePrevMonth),
                  const SizedBox(width: 8),
                  _navButton(
                    icon: Icons.chevron_right,
                    onTap: _handleNextMonth,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d.toUpperCase(),
                        style: TextStyle(
                          color: SunsetColors.dark.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: _getResponsiveAspectRatio(width),
            ),
            itemBuilder: (context, index) {
              if (index < startOffset)
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0x33F1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );

              final dayNum = index - startOffset + 1;
              final dateStr = _formatDate(year, month, dayNum);
              final isToday = dateStr == todayStr;
              final dayRecords = _getRecordsForDate(dateStr);
              final hasExpense = dayRecords.any((r) => r.type == 'expense');
              final hasIncome = dayRecords.any((r) => r.type == 'income');

              return InkWell(
                onTap: () => _handleDayClick(dayNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFFFFF7ED) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? SunsetColors.primary
                          : SunsetColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isToday
                              ? SunsetColors.primary
                              : SunsetColors.dark.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (hasExpense || hasIncome)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasExpense)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (hasIncome)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SunsetColors.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Icon(icon, size: 20, color: SunsetColors.dark),
      ),
    );
  }
}

// ============================================================
// RECORD LIST DIALOG (Transactions 列表弹窗)
// ============================================================

class RecordListDialog extends StatefulWidget {
  final String dateStr;
  final List<CalendarRecord> initialRecords;
  final Future<List<CalendarRecord>> Function() refreshRecords;
  final void Function(CalendarRecord? record) onOpenForm;
  final Future<void> Function(CalendarRecord record) onDelete;

  const RecordListDialog({
    super.key,
    required this.dateStr,
    required this.initialRecords,
    required this.refreshRecords,
    required this.onOpenForm,
    required this.onDelete,
  });

  @override
  State<RecordListDialog> createState() => _RecordListDialogState();
}

class _RecordListDialogState extends State<RecordListDialog> {
  late List<CalendarRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = widget.initialRecords;
  }

  Future<void> _handleDelete(CalendarRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: SunsetColors.dark.withValues(alpha: 0.42),
      builder: (_) => DeleteConfirmDialog(record: record),
    );
    if (confirmed == true) {
      await widget.onDelete(record);
      final fresh = await widget.refreshRecords();
      if (mounted) setState(() => _records = fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50.withValues(alpha: 0.55),
                border: Border(
                  bottom: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        color: SunsetColors.dark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color(0xFFFFF7ED),
              child: Text(
                widget.dateStr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SunsetColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Flexible(
              child: _records.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      alignment: Alignment.center,
                      child: Text(
                        'No transactions on this date.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildRecordTile(_records[index]),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SunsetColors.dark.withValues(
                          alpha: 0.66,
                        ),
                        side: BorderSide(color: Colors.grey.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onOpenForm(null),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SunsetColors.dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 Edit 和 Delete 操作图标常亮直接显示，附带灰底框
  Widget _buildRecordTile(CalendarRecord r) {
    final isIncome = r.type == 'income';
    final accent = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SunsetColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      r.time,
                      style: TextStyle(
                        color: SunsetColors.dark.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.type.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}RM ${_formatPrice(r.price)}',
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => widget.onOpenForm(r),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _handleDelete(r),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD / EDIT RECORD FORM DIALOG
// ============================================================

class RecordFormDialog extends StatefulWidget {
  final CalendarRecord? editing;
  final String? defaultDateStr;
  final List<TypeItem> typesList;
  final List<CategoryItem> allCategories;
  final List<PaymentMethodItem> allMethods;
  final Future<void> Function(
    String endpoint,
    Map<String, dynamic> data,
    int? editingId,
  )
  onSave;

  const RecordFormDialog({
    super.key,
    required this.editing,
    required this.defaultDateStr,
    required this.typesList,
    required this.allCategories,
    required this.allMethods,
    required this.onSave,
  });

  @override
  State<RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<RecordFormDialog> {
  late int _activeTypeId;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _date;
  late String _time;
  int? _paymentMethodId;
  int? _categoryId;
  Map<String, dynamic> _errors = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    if (widget.editing != null) {
      final r = widget.editing!;
      _titleController = TextEditingController(text: r.title);
      _priceController = TextEditingController(text: _formatPrice(r.price));
      _descriptionController = TextEditingController(text: r.description);
      _date = r.date;
      _time = r.time;
      _paymentMethodId = r.paymentMethodId;
      _categoryId = r.categoryId;

      _activeTypeId = r.categoryId > 0
          ? (widget.allCategories
                .firstWhere(
                  (c) => c.id == r.categoryId,
                  orElse: () => CategoryItem(
                    id: 0,
                    name: '',
                    typeId: 1,
                    icon: '',
                    color: Colors.black,
                    description: '',
                    status: 1,
                  ),
                )
                .typeId)
          : (widget.typesList.isNotEmpty ? widget.typesList.first.id : 1);
    } else {
      _titleController = TextEditingController();
      _priceController = TextEditingController();
      _descriptionController = TextEditingController();
      _date =
          widget.defaultDateStr ?? _formatDate(now.year, now.month, now.day);
      _time = '${_pad2(now.hour)}:${_pad2(now.minute)}';

      final defaultType = widget.typesList.isNotEmpty
          ? widget.typesList.first
          : null;
      _activeTypeId = defaultType != null ? defaultType.id : 1;

      final cats = widget.allCategories
          .where((c) => c.typeId == _activeTypeId)
          .toList();
      final methods = widget.allMethods
          .where((m) => m.typeId == _activeTypeId)
          .toList();
      _categoryId = cats.isNotEmpty ? cats.first.id : null;
      _paymentMethodId = methods.isNotEmpty ? methods.first.id : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _errors = {};
      _isSaving = true;
    });

    final currentTypeObj = widget.typesList.firstWhere(
      (t) => t.id == _activeTypeId,
      orElse: () => TypeItem(id: _activeTypeId, name: 'Expense', status: 1),
    );
    final isIncome = currentTypeObj.name.toLowerCase().contains('income');
    final endpoint = isIncome ? '/incomes' : '/expenses';

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': _priceController.text.trim(),
      'date': _date,
      'time': _time,
      'payment_method_id': _paymentMethodId != null ? '$_paymentMethodId' : '',
      'category_id': _categoryId != null ? '$_categoryId' : '',
    };

    try {
      await widget.onSave(endpoint, data, widget.editing?.id);
      if (mounted) {
        SunsetToast.show(
          context,
          widget.editing != null
              ? 'Record updated successfully!'
              : 'Record added successfully!',
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errs = e.response?.data is Map
            ? e.response?.data['errors']
            : null;
        if (errs is Map && mounted) {
          setState(() => _errors = Map<String, dynamic>.from(errs));
        }
      } else {
        final message = e.response?.data is Map
            ? (e.response?.data['error'] ?? e.response?.data['message'])
            : null;
        if (mounted)
          SunsetToast.show(
            context,
            message?.toString() ?? 'Operation failed.',
            type: SunsetToastType.error,
          );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _errorFor(String field) {
    final e = _errors[field];
    if (e is List && e.isNotEmpty) return e.first.toString();
    return null;
  }

  // 🌟 修改后的 DatePicker (纯白背景 + 橙色主题)
  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: SunsetColors.primary, // 选中的橙色
            surface: Colors.white,         // 弹窗背景为纯白
            onSurface: SunsetColors.dark,
          ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: Colors.white, // 日历卡片纯白背景
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = _formatDate(picked.year, picked.month, picked.day));
    }
  }

  // 🌟 修改后的 TimePicker (纯白背景 + 橙色主题)
  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: SunsetColors.primary, // 时钟指针橙色
            surface: Colors.white,         // 弹窗背景为纯白
            onSurface: SunsetColors.dark,
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Colors.white, // 时钟卡片纯白背景
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _time = '${_pad2(picked.hour)}:${_pad2(picked.minute)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCats = widget.allCategories
        .where((c) => c.typeId == _activeTypeId)
        .toList();
    final activeMethods = widget.allMethods
        .where((m) => m.typeId == _activeTypeId)
        .toList();

    final bool hasNoCategories = activeCats.isEmpty;
    final bool hasNoMethods = activeMethods.isEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.editing != null ? 'Edit Record' : 'Add Record',
                      style: const TextStyle(
                        color: SunsetColors.dark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 1. 可横向平滑滚动的 Types 选项卡
                    _buildTypeTabs(),

                    // 🌟 2. Basic Details 模块卡片
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: SunsetColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'BASIC DETAILS',
                                style: TextStyle(
                                  color: SunsetColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _label('TITLE'),
                          TextField(
                            controller: _titleController,
                            decoration: sunsetFieldDecoration(
                              'E.g. Item Title',
                            ),
                          ),
                          if (_errorFor('title') != null)
                            _errorText(_errorFor('title')!),

                          const SizedBox(height: 14),
                          _label('AMOUNT (RM)'),
                          TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: sunsetFieldDecoration('0.00'),
                          ),
                          if (_errorFor('price') != null)
                            _errorText(_errorFor('price')!),

                          const SizedBox(height: 14),
                          _label('DESCRIPTION (OPTIONAL)'),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: sunsetFieldDecoration(
                              'Enter description...',
                            ),
                          ),
                          if (_errorFor('description') != null)
                            _errorText(_errorFor('description')!),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🌟 3. Categorization & Time 模块卡片
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 18,
                                color: SunsetColors.dark.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CATEGORIZATION',
                                style: TextStyle(
                                  color: SunsetColors.dark.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('DATE'),
                                    InkWell(
                                      onTap: _pickDate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: SunsetColors.primary
                                                .withValues(alpha: 0.80),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 15,
                                              color: SunsetColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _date,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_errorFor('date') != null)
                                      _errorText(_errorFor('date')!),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('TIME'),
                                    InkWell(
                                      onTap: _pickTime,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: SunsetColors.primary
                                                .withValues(alpha: 0.80),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 15,
                                              color: SunsetColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _time,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_errorFor('time') != null)
                                      _errorText(_errorFor('time')!),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          _label('CATEGORY'),
                          if (hasNoCategories)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "No Category found for this type.",
                                      style: TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _categoryId,
                              decoration: sunsetFieldDecoration(
                                'Select Category',
                              ),
                              items: activeCats
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                          if (_errorFor('category_id') != null)
                            _errorText(_errorFor('category_id')!),

                          const SizedBox(height: 14),
                          _label('PAYMENT METHOD'),
                          if (hasNoMethods)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "No Payment Method found for this type.",
                                      style: TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _paymentMethodId,
                              decoration: sunsetFieldDecoration(
                                'Select Method',
                              ),
                              items: activeMethods
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m.id,
                                      child: Text(m.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethodId = v),
                            ),
                          if (_errorFor('payment_method_id') != null)
                            _errorText(_errorFor('payment_method_id')!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isSaving || hasNoCategories || hasNoMethods)
                          ? null
                          : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SunsetColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _isSaving ? 'Saving...' : 'Save Record',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 可横向平滑滚动的 Types 选项卡组件
  Widget _buildTypeTabs() {
    if (widget.typesList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "No active Transaction Types found.",
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.typesList.map((t) {
            final selected = _activeTypeId == t.id;
            final isIncome = t.name.toLowerCase().contains('income');
            final activeTextColor = isIncome
                ? const Color(0xFF059669)
                : const Color(0xFFEF4444);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: InkWell(
                onTap: widget.editing != null
                    ? null
                    : () {
                        setState(() {
                          _activeTypeId = t.id;
                          final cats = widget.allCategories
                              .where((c) => c.typeId == t.id)
                              .toList();
                          final methods = widget.allMethods
                              .where((m) => m.typeId == t.id)
                              .toList();
                          _categoryId = cats.isNotEmpty ? cats.first.id : null;
                          _paymentMethodId = methods.isNotEmpty
                              ? methods.first.id
                              : null;
                        });
                      },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    t.name,
                    style: TextStyle(
                      color: selected ? activeTextColor : Colors.grey.shade600,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xB32D2520),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    ),
  );
  Widget _errorText(String message) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      message,
      style: const TextStyle(color: Colors.red, fontSize: 12),
    ),
  );
}

// ============================================================
// DELETE CONFIRMATION DIALOG
// ============================================================

class DeleteConfirmDialog extends StatefulWidget {
  final CalendarRecord record;
  const DeleteConfirmDialog({super.key, required this.record});

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delete Record',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Are you sure you want to delete this record? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SunsetColors.dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.record.title.toUpperCase()} (${widget.record.type.toUpperCase()})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'RM ${_formatPrice(widget.record.price)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: SunsetColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SunsetColors.dark.withValues(
                        alpha: 0.66,
                      ),
                      side: BorderSide(color: Colors.grey.shade200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : () async {
                            setState(() => _isDeleting = true);
                            Navigator.pop(context, true);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _isDeleting ? 'Deleting...' : 'Delete',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
