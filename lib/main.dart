import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(ClockApp());

class ClockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock App',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/* ---------------- Main with Bottom Navigation ---------------- */
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final pages = [
    HomePage(),
    AnalogClockPage(),
    DigitalClockPage(),
    StopwatchPage(),
    TimerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Analog'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Digital'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Stopwatch'),
          BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom), label: 'Timer'),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/* ---------------- 1) Home Page (menampilkan World Clock + Alarm shortcut) ---------------- */
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Simple in-memory alarms (no persistence)
  List<AlarmItem> alarms = [];
  Timer? _alarmChecker;

  @override
  void initState() {
    super.initState();
    _alarmChecker = Timer.periodic(Duration(seconds: 1), (_) => _checkAlarms());
  }

  @override
  void dispose() {
    _alarmChecker?.cancel();
    super.dispose();
  }

  void _checkAlarms() {
    final now = DateTime.now();
    for (var a in alarms.where((x) => !x.fired)) {
      if (a.matches(now)) {
        a.fired = true;
        _showAlarmDialog(a);
      }
    }
  }

  void _showAlarmDialog(AlarmItem alarm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Alarm: ${alarm.label}'),
        content: Text('Waktu alarm tercapai: ${alarm.time.format(context)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  void _addAlarm() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    final labelController = TextEditingController();
    final res = await showDialog<AlarmItem>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Label Alarm'),
        content: TextField(controller: labelController, decoration: InputDecoration(hintText: 'Contoh: Bangun')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, AlarmItem(time: t, label: labelController.text.trim().isEmpty ? 'Alarm' : labelController.text.trim()));
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
    if (res != null) setState(() => alarms.add(res));
  }

  void _removeAlarm(int idx) => setState(() => alarms.removeAt(idx));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clock App', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('World Clock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            WorldClockCard(),
            SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Alarms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ElevatedButton.icon(onPressed: _addAlarm, icon: Icon(Icons.add_alarm), label: Text('Tambah')),
            ]),
            SizedBox(height: 8),
            Expanded(
              child: alarms.isEmpty
                  ? Center(child: Text('Belum ada alarm. Tambah alarm untuk mencoba.'))
                  : ListView.builder(
                      itemCount: alarms.length,
                      itemBuilder: (_, i) {
                        final a = alarms[i];
                        return ListTile(
                          leading: Icon(Icons.alarm),
                          title: Text(a.label),
                          subtitle: Text(a.time.format(context) + (a.fired ? ' • Fired' : '')),
                          trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => _removeAlarm(i)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- World Clock Widget ---------------- */
class WorldClockCard extends StatefulWidget {
  @override
  _WorldClockCardState createState() => _WorldClockCardState();
}

class _WorldClockCardState extends State<WorldClockCard> {
  Timer? _t;
  DateTime _now = DateTime.now();

  final List<CityTZ> cities = [
    CityTZ('Jakarta', 7),
    CityTZ('London', 0),
    CityTZ('New York', -5),
    CityTZ('Tokyo', 9),
    CityTZ('Sydney', 10),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(Duration(seconds: 1), (_) => setState(() => _now = DateTime.now().toUtc()));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _timeForOffset(int offsetHours) {
    final dt = _now.add(Duration(hours: offsetHours));
    return "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: cities.map((c) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.name, style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(_timeForOffset(c.offset), style: TextStyle(fontSize: 16)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/* ---------------- Alarm model ---------------- */
class AlarmItem {
  TimeOfDay time;
  String label;
  bool fired;
  AlarmItem({required this.time, this.label = 'Alarm', this.fired = false});
  bool matches(DateTime now) {
    return now.hour == time.hour && now.minute == time.minute && now.second == 0;
  }
}

class CityTZ {
  final String name;
  final int offset; // hours from UTC
  CityTZ(this.name, this.offset);
}

/* ---------------- 2) Analog Clock Page ---------------- */
class AnalogClockPage extends StatefulWidget {
  @override
  _AnalogClockPageState createState() => _AnalogClockPageState();
}

class _AnalogClockPageState extends State<AnalogClockPage> {
  DateTime _now = DateTime.now();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jam Analog')),
      body: Center(
        child: CustomPaint(
          size: Size(320, 320),
          painter: AnalogPainter(_now),
        ),
      ),
    );
  }
}

class AnalogPainter extends CustomPainter {
  final DateTime now;
  AnalogPainter(this.now);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = min(size.width, size.height)/2;
    final paintCircle = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paintCircle);
    final border = Paint()..color = Colors.indigo..style = PaintingStyle.stroke..strokeWidth = 6;
    canvas.drawCircle(center, radius, border);

    // ticks
    final tickPaint = Paint()..color = Colors.black54..strokeWidth = 2;
    for (int i = 0; i < 60; i++) {
      final angle = i * 2 * pi / 60;
      final inner = Offset(center.dx + (radius - (i % 5 == 0 ? 14 : 8)) * sin(angle), center.dy - (radius - (i % 5 == 0 ? 14 : 8)) * cos(angle));
      final outer = Offset(center.dx + radius * sin(angle), center.dy - radius * cos(angle));
      canvas.drawLine(inner, outer, tickPaint);
    }

    // hands
    final secAngle = (now.second / 60) * 2 * pi;
    final minAngle = (now.minute / 60 + now.second/3600) * 2 * pi;
    final hourAngle = ((now.hour % 12) / 12 + now.minute/720) * 2 * pi;

    void drawHand(double angle, double length, Paint p) {
      final end = Offset(center.dx + length * sin(angle), center.dy - length * cos(angle));
      canvas.drawLine(center, end, p);
    }

    drawHand(hourAngle, radius*0.5, Paint()..color=Colors.black..strokeWidth=6..strokeCap=StrokeCap.round);
    drawHand(minAngle, radius*0.7, Paint()..color=Colors.black87..strokeWidth=4..strokeCap=StrokeCap.round);
    drawHand(secAngle, radius*0.9, Paint()..color=Colors.red..strokeWidth=2..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* ---------------- 3) Digital Clock Page ---------------- */
class DigitalClockPage extends StatefulWidget {
  @override _DigitalClockPageState createState() => _DigitalClockPageState();
}
class _DigitalClockPageState extends State<DigitalClockPage> {
  late Timer _t; DateTime _now = DateTime.now();
  @override void initState() {
    super.initState();
    _t = Timer.periodic(Duration(seconds:1), (_) => setState(()=>_now = DateTime.now()));
  }
  @override void dispose(){ _t.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    final time = "${_now.hour.toString().padLeft(2,'0')}:${_now.minute.toString().padLeft(2,'0')}:${_now.second.toString().padLeft(2,'0')}";
    final date = "${_now.day}/${_now.month}/${_now.year}";
    return Scaffold(
      appBar: AppBar(title: Text('Jam Digital')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(date, style: TextStyle(fontSize: 20, color: Colors.grey[700])),
        ]),
      ),
    );
  }
}

/* ---------------- 4) Stopwatch Page (dengan Lap) ---------------- */
class StopwatchPage extends StatefulWidget {
  @override _StopwatchPageState createState() => _StopwatchPageState();
}
class _StopwatchPageState extends State<StopwatchPage> {
  Stopwatch _sw = Stopwatch();
  Timer? _t;
  List<String> laps = [];

  @override void dispose(){ _t?.cancel(); super.dispose(); }

  void _start(){
    _sw.start();
    _t = Timer.periodic(Duration(milliseconds:30), (_) => setState((){}));
  }
  void _stop(){ _sw.stop(); _t?.cancel(); setState((){}); }
  void _reset(){ _sw.reset(); laps.clear(); setState((){}); }
  void _lap(){
    final ms = _sw.elapsedMilliseconds;
    laps.insert(0, _format(ms));
    setState((){});
  }

  String _format(int ms){
    final s = (ms/1000).floor();
    final min = (s/60).floor();
    final sec = s%60;
    final cent = ((ms%1000)/10).floor();
    return "${min.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}.${cent.toString().padLeft(2,'0')}";
  }

  @override Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Stopwatch')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(height: 8),
          Text(_format(_sw.elapsedMilliseconds), style: TextStyle(fontSize:48, fontWeight: FontWeight.bold)),
          SizedBox(height:12),
          Row(mainAxisSize: MainAxisSize.min, children: [
            ElevatedButton(onPressed: _sw.isRunning? _stop : _start, child: Text(_sw.isRunning? 'Stop' : 'Start')),
            SizedBox(width:12),
            OutlinedButton(onPressed: _reset, child: Text('Reset')),
            SizedBox(width:12),
            ElevatedButton(onPressed: _sw.isRunning? _lap : null, child: Text('Lap')),
          ]),
          SizedBox(height:16),
          Expanded(
            child: laps.isEmpty
                ? Center(child: Text('Belum ada lap'))
                : ListView.builder(
                    itemCount: laps.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: Text('#${laps.length - i}'),
                      title: Text(laps[i], style: TextStyle(fontFamily: 'monospace')),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

/* ---------------- 5) Timer Page ---------------- */
class TimerPage extends StatefulWidget {
  @override _TimerPageState createState() => _TimerPageState();
}
class _TimerPageState extends State<TimerPage> {
  Duration _duration = Duration(seconds: 60);
  Timer? _t;
  int _secondsLeft = 60;
  bool _running = false;

  void _start(){
    if(_running) return;
    setState(()=> _secondsLeft = _duration.inSeconds);
    _running = true;
    _t = Timer.periodic(Duration(seconds:1), (timer){
      setState(() {
        if(_secondsLeft>0) _secondsLeft--;
        else { _t?.cancel(); _running=false; _onTimerComplete(); }
      });
    });
  }
  void _stop(){ _t?.cancel(); _running=false; setState((){}); }
  void _reset(){ _t?.cancel(); _running=false; setState(()=> _secondsLeft = _duration.inSeconds); }

  void _onTimerComplete() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Timer selesai'),
      content: Text('Waktu hitung mundur telah selesai.'),
      actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: Text('OK'))],
    ));
  }

  @override void dispose(){ _t?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context){
    final mm = (_secondsLeft~/60).toString().padLeft(2,'0');
    final ss = (_secondsLeft%60).toString().padLeft(2,'0');
    return Scaffold(
      appBar: AppBar(title: Text('Timer')),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(children: [
          SizedBox(height:20),
          Text('$mm:$ss', style: TextStyle(fontSize:64, fontWeight: FontWeight.bold)),
          SizedBox(height:20),
          Slider(
            min: 10, max: 3600, divisions: 359,
            value: _duration.inSeconds.toDouble(),
            onChanged: _running ? null : (v) => setState(()=> _duration = Duration(seconds: v.toInt())),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: _running? null : _start, child: Text('Start')),
            SizedBox(width:12),
            ElevatedButton(onPressed: _running? _stop : null, child: Text('Stop')),
            SizedBox(width:12),
            OutlinedButton(onPressed: _reset, child: Text('Reset')),
          ])
        ]),
      ),
    );
  }
}
