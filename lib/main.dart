// تطبيق الأستاذ - نسخة ملف واحد (بدون Firebase)
// البيانات تُحفظ داخل الهاتف. الولي يدخل بالكود من نفس هاتف الأستاذ.
// المكتبة الوحيدة المطلوبة: shared_preferences (موجودة في pubspec.yaml)

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────── التخزين ─────────────

class Store extends ChangeNotifier {
  late SharedPreferences p;
  List<Map<String, dynamic>> students = [];
  String? pin;

  Future<void> load() async {
    p = await SharedPreferences.getInstance();
    pin = p.getString('pin');
    final s = p.getString('students');
    if (s != null) {
      students = (jsonDecode(s) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
  }

  void save() {
    p.setString('students', jsonEncode(students));
    notifyListeners();
  }

  void setPin(String v) {
    pin = v;
    p.setString('pin', v);
    notifyListeners();
  }

  Map<String, dynamic>? byId(String id) {
    for (final s in students) {
      if (s['id'] == id) return s;
    }
    return null;
  }
}

final store = Store();

// ───────────── أدوات ─────────────

const months = [
  'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
  'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];

String ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
String ymd(DateTime d) => '${ym(d)}-${d.day.toString().padLeft(2, '0')}';
DateTime parseYm(String s) =>
    DateTime(int.parse(s.substring(0, 4)), int.parse(s.substring(5, 7)));
String monthLabel(String s) {
  final d = parseYm(s);
  return '${months[d.month - 1]} ${d.year}';
}

String money(num v) {
  final n = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  return '$n دج';
}

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class Totals {
  int attended = 0, absent = 0, scoreN = 0;
  double total = 0, paid = 0, scoreSum = 0;
  double get avg => scoreN == 0 ? 0 : scoreSum / scoreN;
}

List<Map<String, dynamic>> monthSessions(Map<String, dynamic> st, String m) {
  final list = (st['sessions'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .where((s) => (s['date'] as String).startsWith(m))
      .toList();
  list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  return list;
}

Totals calc(List<Map<String, dynamic>> sessions) {
  final t = Totals();
  for (final s in sessions) {
    if (s['attended'] == true) {
      t.attended++;
      final p = (s['price'] ?? 0).toDouble();
      t.total += p;
      if (s['paid'] == true) t.paid += p;
      if (s['score'] != null) {
        t.scoreN++;
        t.scoreSum += (s['score']).toDouble();
      }
    } else {
      t.absent++;
    }
  }
  return t;
}

// ───────────── التطبيق ─────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الأستاذ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.school, size: 96, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text('تطبيق الأستاذ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              FilledButton.icon(
                icon: const Icon(Icons.person),
                label: const Padding(
                    padding: EdgeInsets.all(14), child: Text('دخول الأستاذ')),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TeacherGate())),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.family_restroom),
                label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('دخول ولي التلميذ')),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ParentLogin())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── دخول الأستاذ (رمز سري) ─────────────

class TeacherGate extends StatefulWidget {
  const TeacherGate({super.key});
  @override
  State<TeacherGate> createState() => _TeacherGateState();
}

class _TeacherGateState extends State<TeacherGate> {
  final pin = TextEditingController();

  void go() {
    final v = pin.text.trim();
    if (v.length < 4) {
      snack(context, 'الرمز 4 أرقام على الأقل');
      return;
    }
    if (store.pin == null) {
      store.setPin(v);
    } else if (store.pin != v) {
      snack(context, 'الرمز غير صحيح');
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const TeacherHome()));
  }

  @override
  Widget build(BuildContext context) {
    final first = store.pin == null;
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الأستاذ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(first ? 'أنشئ رمزاً سرياً (سيطلب منك كل مرة)' : 'أدخل رمزك السري'),
          const SizedBox(height: 16),
          TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 6),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: go, child: Text(first ? 'حفظ ودخول' : 'دخول')),
        ],
      ),
    );
  }
}

// ───────────── دخول الولي ─────────────

class ParentLogin extends StatefulWidget {
  const ParentLogin({super.key});
  @override
  State<ParentLogin> createState() => _ParentLoginState();
}

class _ParentLoginState extends State<ParentLogin> {
  final code = TextEditingController();

  void enter() {
    final c = code.text.trim();
    for (final s in store.students) {
      if (s['code'] == c && c.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StudentPage(id: s['id'], teacher: false)));
        return;
      }
    }
    snack(context, 'الكود غير صحيح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول ولي التلميذ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('أدخل الكود الذي أعطاك إياه الأستاذ'),
          const SizedBox(height: 16),
          TextField(
            controller: code,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 4),
            decoration: const InputDecoration(
                labelText: 'كود التلميذ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: enter, child: const Text('دخول')),
        ],
      ),
    );
  }
}

// ───────────── واجهة الأستاذ ─────────────

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('تلاميذي'),
          actions: [
            IconButton(
              tooltip: 'التقرير الشهري',
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportPage())),
            ),
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const Home()), (r) => false),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.person_add),
          label: const Text('تلميذ جديد'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StudentForm())),
        ),
        body: store.students.isEmpty
            ? const Center(child: Text('لم تضف أي تلميذ بعد'))
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: store.students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = store.students[i];
                  return ListTile(
                    leading: CircleAvatar(
                        child: Text((s['name'] as String).characters.first)),
                    title: Text(s['name']),
                    subtitle: Text(
                        '${s['level']} • الكود: ${s['code']} • ${money(s['price'])} / حصة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                StudentPage(id: s['id'], teacher: true))),
                  );
                },
              ),
      ),
    );
  }
}

// ───────────── إضافة / تعديل تلميذ ─────────────

class StudentForm extends StatefulWidget {
  final String? id;
  const StudentForm({super.key, this.id});
  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  late final Map<String, dynamic>? old =
      widget.id == null ? null : store.byId(widget.id!);
  late final name = TextEditingController(text: old?['name']);
  late final level = TextEditingController(text: old?['level']);
  late final phone = TextEditingController(text: old?['phone']);
  late final price = TextEditingController(text: old?['price']?.toString());
  late final code = TextEditingController(text: old?['code'] ?? randomCode());

  static String randomCode() => (100000 + Random().nextInt(900000)).toString();

  void save() {
    final c = code.text.trim();
    if (name.text.trim().isEmpty || c.isEmpty) {
      snack(context, 'الاسم والكود إجباريان');
      return;
    }
    for (final s in store.students) {
      if (s['code'] == c && s['id'] != widget.id) {
        snack(context, 'هذا الكود مستعمل، اختر كوداً آخر');
        return;
      }
    }
    final data = {
      'name': name.text.trim(),
      'level': level.text.trim(),
      'phone': phone.text.trim(),
      'code': c,
      'price': double.tryParse(price.text.trim()) ?? 0,
    };
    if (old == null) {
      store.students.add({
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        ...data,
        'sessions': [],
      });
    } else {
      old!.addAll(data);
    }
    store.save();
    Navigator.pop(context);
  }

  Widget field(TextEditingController c, String label,
          {TextInputType? type, Widget? suffix}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: suffix),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(old == null ? 'تلميذ جديد' : 'تعديل التلميذ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          field(name, 'اسم التلميذ'),
          field(level, 'المستوى / القسم'),
          field(phone, 'هاتف الولي', type: TextInputType.phone),
          field(price, 'سعر الحصة الواحدة (دج)', type: TextInputType.number),
          field(code, 'كود دخول الولي',
              suffix: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => code.text = randomCode()))),
          FilledButton(onPressed: save, child: const Text('حفظ')),
        ],
      ),
    );
  }
}

// ───────────── صفحة التلميذ (أستاذ + ولي) ─────────────

class StudentPage extends StatefulWidget {
  final String id;
  final bool teacher;
  const StudentPage({super.key, required this.id, required this.teacher});
  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String month = ym(DateTime.now());

  void shift(int d) {
    final m = parseYm(month);
    setState(() => month = ym(DateTime(m.year, m.month + d)));
  }

  Future<void> deleteStudent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التلميذ؟'),
        content: const Text('سيتم حذف التلميذ وكل حصصه.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      store.students.removeWhere((s) => s['id'] == widget.id);
      store.save();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> sessionDialog(Map<String, dynamic> st) async {
    DateTime date = DateTime.now();
    bool attended = true, homework = true;
    String behavior = 'جيد';
    final score = TextEditingController();
    final note = TextEditingController();
    final price = TextEditingController(text: '${st['price']}');

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('تسجيل حصة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(ymd(date)),
                  onPressed: () async {
                    final p = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (p != null) setS(() => date = p);
                  },
                ),
                SwitchListTile(
                    title: const Text('حضر الحصة'),
                    value: attended,
                    onChanged: (v) => setS(() => attended = v)),
                if (attended) ...[
                  DropdownButtonFormField<String>(
                    value: behavior,
                    decoration: const InputDecoration(labelText: 'السلوك'),
                    items: ['ممتاز', 'جيد', 'متوسط', 'ضعيف']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setS(() => behavior = v!),
                  ),
                  TextField(
                      controller: score,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'النقطة /20 (اختياري)')),
                  SwitchListTile(
                      title: const Text('أنجز الواجب'),
                      value: homework,
                      onChanged: (v) => setS(() => homework = v)),
                  TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'سعر هذه الحصة')),
                ],
                TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'ملاحظات')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                (st['sessions'] as List).add({
                  'date': ymd(date),
                  'attended': attended,
                  'behavior': attended ? behavior : null,
                  'score': attended ? double.tryParse(score.text.trim()) : null,
                  'homework': attended ? homework : null,
                  'note': note.text.trim(),
                  'price':
                      attended ? (double.tryParse(price.text.trim()) ?? 0) : 0,
                  'paid': false,
                });
                store.save();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget sessionTile(Map<String, dynamic> st, Map<String, dynamic> x) {
    final att = x['attended'] == true;
    final lines = <String>[
      if (att) 'السلوك: ${x['behavior'] ?? '-'}',
      if (att && x['score'] != null) 'النقطة: ${x['score']} / 20',
      if (att) 'الواجب: ${x['homework'] == true ? 'أنجزه' : 'لم ينجزه'}',
      if ((x['note'] ?? '').toString().isNotEmpty) 'ملاحظة: ${x['note']}',
      if (att)
        'السعر: ${money(x['price'] ?? 0)} • ${x['paid'] == true ? 'مدفوع' : 'غير مدفوع'}',
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(att ? Icons.check_circle : Icons.cancel,
            color: att ? Colors.green : Colors.red),
        title: Text(att ? x['date'] : '${x['date']} (غائب)'),
        subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
        trailing: widget.teacher
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  final list = st['sessions'] as List;
                  final i = list.indexWhere((e) =>
                      e['date'] == x['date'] &&
                      e['note'] == x['note'] &&
                      e['price'] == x['price'] &&
                      e['paid'] == x['paid']);
                  if (i < 0) return;
                  if (v == 'paid') {
                    list[i]['paid'] = !(list[i]['paid'] == true);
                  } else {
                    list.removeAt(i);
                  }
                  store.save();
                },
                itemBuilder: (_) => [
                  if (att)
                    PopupMenuItem(
                        value: 'paid',
                        child: Text(x['paid'] == true
                            ? 'إلغاء الدفع'
                            : 'تسجيل كمدفوع')),
                  const PopupMenuItem(value: 'del', child: Text('حذف الحصة')),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final st = store.byId(widget.id);
        if (st == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('غير موجود')));
        }
        final sessions = monthSessions(st, month);
        final t = calc(sessions);
        return Scaffold(
          appBar: AppBar(
            title: Text(st['name']),
            actions: [
              if (widget.teacher) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => StudentForm(id: widget.id))),
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: deleteStudent),
              ],
            ],
          ),
          floatingActionButton: widget.teacher
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('حصة جديدة'),
                  onPressed: () => sessionDialog(st),
                )
              : null,
          body: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text('${st['level']}'),
                  subtitle: Text(
                      'هاتف الولي: ${st['phone']}\nسعر الحصة: ${money(st['price'])}'
                      '${widget.teacher ? '\nكود الولي: ${st['code']}' : ''}'),
                  isThreeLine: true,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => shift(-1)),
                  Text(monthLabel(month),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => shift(1)),
                ],
              ),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الحصص الحاضرة: ${t.attended}   |   الغياب: ${t.absent}'),
                      Text('التكلفة الشهرية: ${money(t.total)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('المدفوع: ${money(t.paid)}   |   المتبقي: ${money(t.total - t.paid)}'),
                      if (t.scoreN > 0)
                        Text('معدل النقاط: ${t.avg.toStringAsFixed(1)} / 20'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('لا توجد حصص هذا الشهر'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: sessions.length,
                        itemBuilder: (_, i) => sessionTile(st, sessions[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────── التقرير الشهري ─────────────

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String month = ym(DateTime.now());

  void shift(int d) {
    final m = parseYm(month);
    setState(() => month = ym(DateTime(m.year, m.month + d)));
  }

  @override
  Widget build(BuildContext context) {
    double total = 0, paid = 0;
    final rows = <Widget>[];
    for (final st in store.students) {
      final t = calc(monthSessions(st, month));
      if (t.attended == 0) continue;
      total += t.total;
      paid += t.paid;
      rows.add(ListTile(
        title: Text(st['name']),
        subtitle: Text('${t.attended} حصة • مدفوع ${money(t.paid)}'),
        trailing: Text(money(t.total),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('التقرير الشهري')),
      body: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => shift(-1)),
              Text(monthLabel(month),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => shift(1)),
            ],
          ),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text('المجموع: ${money(total)}'),
              subtitle: Text(
                  'المقبوض: ${money(paid)}   |   المتبقي: ${money(total - paid)}'),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('لا توجد حصص هذا الشهر')))
          else
            ...rows,
        ],
      ),
    );
  }
}