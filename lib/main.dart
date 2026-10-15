import 'package:flutter/material.dart';

void main() {
  runApp(const TeacherApp());
}

// --- نماذج البيانات (Models) ---
class Student {
  String id;
  String name;
  String parentPhone;
  double pricePerSession;
  List<SessionRecord> records;

  Student({
    required this.id,
    required this.name,
    required this.parentPhone,
    required this.pricePerSession,
    List<SessionRecord>? records,
  }) : records = records ?? [];

  double get totalMonthlyCost {
    return records.length * pricePerSession;
  }
}

class SessionRecord {
  String date;
  String notes;
  bool attended;

  SessionRecord({
    required this.date,
    required this.notes,
    required this.attended,
  });
}

class Database {
  static List<Student> students = [
    Student(
      id: 'STUD123',
      name: 'أحمد محمد',
      parentPhone: '0555000000',
      pricePerSession: 500.0,
      records: [
        SessionRecord(date: '2026-10-01', notes: 'مشاركة ممتازة وفهم سريع', attended: true),
        SessionRecord(date: '2026-10-08', notes: 'تأخر قليلاً لكنه انجز الواجب', attended: true),
      ],
    ),
  ];
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق متابعة التلاميذ',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نظام متابعة التلاميذ والدروس')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text(
              'أهلاً بك، الرجاء اختيار صفة الدخول:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeacherLoginScreen()),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('الدخول بصفتي أستاذ', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParentLoginScreen()),
                );
              },
              icon: const Icon(Icons.family_restroom),
              label: const Text('الدخول بصفتي ولي أمر (بواسطة ID)', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherLoginScreen extends StatelessWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('دخول الأستاذ')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور (اكتب أي شيء للتدريب مثل: 1234)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TeacherDashboard()),
                );
              },
              child: const Text('دخول لوحة التحكم'),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأستاذ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddStudentDialog(context);
            },
          )
        ],
      ),
      body: Database.students.isEmpty
          ? const Center(child: Text('لا يوجد تلاميذ مسجلين حالياً. اضغط على زر الإضافة فوق.'))
          : ListView.builder(
              itemCount: Database.students.length,
              itemBuilder: (context, index) {
                final student = Database.students[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('المعرف (ID): ${student.id} | التكلفة الشهرية: ${student.totalMonthlyCost} دج'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentDetailsScreen(student: student),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة تلميذ جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idController, decoration: const InputDecoration(labelText: 'معرف التلميذ (ID فريد)')),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم التلميذ')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'هاتف ولي الأمر')),
                TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الحصة الواحدة')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                  setState(() {
                    Database.students.add(Student(
                      id: idController.text,
                      name: nameController.text,
                      parentPhone: phoneController.text,
                      pricePerSession: double.tryParse(priceController.text) ?? 0.0,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}

class StudentDetailsScreen extends StatefulWidget {
  final Student student;
  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('متابعة: ${widget.student.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معرف التلميذ (ID): ${widget.student.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('سعر الحصة: ${widget.student.pricePerSession} دج'),
                    Text('عدد الحصص المسجلة: ${widget.student.records.length}'),
                    const Divider(),
                    Text('التكلفة الإجمالية هذا الشهر: ${widget.student.totalMonthlyCost} دج',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text('سجل المتابعة والحصص:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: widget.student.records.isEmpty
                  ? const Center(child: Text('لم يتم تسجيل حصص لهذا التلميذ بعد.'))
                  : ListView.builder(
                      itemCount: widget.student.records.length,
                      itemBuilder: (context, index) {
                        final record = widget.student.records[index];
                        return ListTile(
                          leading: Icon(
                            record.attended ? Icons.check_circle : Icons.cancel,
                            color: record.attended ? Colors.green : Colors.red,
                          ),
                          title: Text('التاريخ: ${record.date}'),
                          subtitle: Text('الملاحظة: ${record.notes}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddSessionDialog(context);
        },
        label: const Text('إضافة حصة جديدة'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final notesController = TextEditingController();
    bool attended = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('إضافة متابعة حصة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: 'التاريخ (YYYY-MM-DD)')),
                  TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات الأستاذ (المستوى، السلوك...)')),
                  CheckboxListTile(
                    title: const Text('حاضر'),
                    value: attended,
                    onChanged: (val) {
                      setStateDialog(() {
                        attended = val ?? true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      widget.student.records.add(SessionRecord(
                        date: dateController.text,
                        notes: notesController.text,
                        attended: attended,
                      ));
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController idController = TextEditingController();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول ولي الأمر')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل المعرف (ID) الخاص بتلميذك الذي زودك به الأستاذ:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'معرف التلميذ (ID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String enteredId = idController.text.trim();
                try {
                  Student foundStudent = Database.students.firstWhere((s) => s.id == enteredId);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentDashboardScreen(student: foundStudent),
                    ),
                  );
                } catch (e) {
                  setState(() {
                    errorMessage = 'المعرف غير موجود، تأكد من الأستاذ.';
                  });
                }
              },
              child: const Text('عرض المتابعة'),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentDashboardScreen extends StatelessWidget {
  final Student student;
  const ParentDashboardScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('متابعة التلميذ: ${student.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اسم التلميذ: ${student.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('التكلفة الإجمالية للشهر: ${student.totalMonthlyCost} دج',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('عدد الحصص المحضورة: ${student.records.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text('سجل الحصص والملاحظات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: student.records.isEmpty
                  ? const Center(child: Text('لم يتم تسجيل حصص بعد.'))
                  : ListView.builder(
                      itemCount: student.records.length,
                      itemBuilder: (context, index) {
                        final record = student.records[index];
                        return ListTile(
                          leading: Icon(
                            record.attended ? Icons.check_circle : Icons.cancel,
                            color: record.attended ? Colors.green : Colors.red,
                          ),
                          title: Text('التاريخ: ${record.date}'),
                          subtitle: Text('ملاحظة الأستاذ: ${record.notes}'),
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