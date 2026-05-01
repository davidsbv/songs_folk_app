import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../repositories/events_repository.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final EventsRepository _eventsRepository = EventsRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  List<Event> _eventsInMonth = const [];
  int _monthRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedDay);
  }

  Future<void> _loadMonth(DateTime month) async {
    final requestId = ++_monthRequestId;
    setState(() => _loading = true);
    final events = await _eventsRepository.getEventsForMonth(month);
    if (!mounted) return;
    if (requestId != _monthRequestId) return;
    setState(() {
      _focusedDay = month;
      _eventsInMonth = events;
      _loading = false;
    });
  }

  List<Event> _eventsForDay(DateTime day) {
    return _eventsInMonth.where((event) {
      final from = DateTime(
        event.startAt.year,
        event.startAt.month,
        event.startAt.day,
      );
      final to = DateTime(event.endAt.year, event.endAt.month, event.endAt.day);
      final current = DateTime(day.year, day.month, day.day);
      final isAfterStart = !current.isBefore(from);
      final isBeforeEnd = !current.isAfter(to);
      return isAfterStart && isBeforeEnd;
    }).toList();
  }

  List<Event> get _eventsToShow {
    final selected = _selectedDay;
    if (selected == null) {
      return _eventsInMonth;
    }
    return _eventsForDay(selected);
  }

  String _formatRange(Event event) {
    final sameDay = isSameDay(event.startAt, event.endAt);
    final hasEndTime = !event.startAt.isAtSameMomentAs(event.endAt);
    final startDate =
        '${_twoDigits(event.startAt.day)}/${_twoDigits(event.startAt.month)}';
    final endDate = '${_twoDigits(event.endAt.day)}/${_twoDigits(event.endAt.month)}';
    if (event.allDay) {
      return sameDay
          ? '$startDate · Todo el dia'
          : '$startDate - $endDate · Todo el dia';
    }
    final startHour = _twoDigits(event.startAt.hour);
    final startMin = _twoDigits(event.startAt.minute);
    final endHour = _twoDigits(event.endAt.hour);
    final endMin = _twoDigits(event.endAt.minute);
    if (!hasEndTime) return '$startDate · $startHour:$startMin';
    if (sameDay) return '$startDate · $startHour:$startMin - $endHour:$endMin';
    return '$startDate $startHour:$startMin - $endDate $endHour:$endMin';
  }

  String _twoDigits(int value) => value < 10 ? '0$value' : '$value';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de eventos')),
      body: RefreshIndicator(
        onRefresh: () => _loadMonth(_focusedDay),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TableCalendar<Event>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              locale: 'es_ES',
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _eventsForDay,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              daysOfWeekHeight: 22,
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final label = DateFormat('EEE', 'es_ES').format(day);
                  final text =
                      label.isEmpty ? '' : '${label[0].toUpperCase()}${label.substring(1)}';
                  return Center(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                final targetMonth = DateTime(focusedDay.year, focusedDay.month, 1);
                setState(() {
                  _focusedDay = targetMonth;
                  _selectedDay = null;
                });
                _loadMonth(targetMonth);
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ))
            else ...[
              Text(
                _selectedDay == null
                    ? 'Eventos del mes'
                    : 'Eventos del ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_selectedDay != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedDay = null),
                    icon: const Icon(Icons.list),
                    label: const Text('Mostrar todos'),
                  ),
                ),
              const SizedBox(height: 12),
              if (_eventsToShow.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay eventos programados para este periodo.',
                    ),
                  ),
                )
              else
                ..._eventsToShow.map(
                  (event) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Text(
                        [
                          _formatRange(event),
                          if ((event.location ?? '').isNotEmpty) event.location!,
                          if ((event.description ?? '').isNotEmpty)
                            event.description!,
                        ].join('\n'),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
