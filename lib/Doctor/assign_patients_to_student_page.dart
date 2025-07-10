import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AssignPatientsToStudentPage extends StatefulWidget {
  const AssignPatientsToStudentPage({Key? key}) : super(key: key);

  @override
  State<AssignPatientsToStudentPage> createState() => _AssignPatientsToStudentPageState();
}

class _AssignPatientsToStudentPageState extends State<AssignPatientsToStudentPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _studentPatientsRef = FirebaseDatabase.instance.ref('student_patients');

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _patients = [];
  String? _selectedStudentId;
  Set<String> _selectedPatientIds = {};
  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { _isLoading = true; });
    final usersSnapshot = await _usersRef.get();
    final users = usersSnapshot.value as Map<dynamic, dynamic>?;
    if (users == null) {
      setState(() { _isLoading = false; });
      return;
    }
    final students = <Map<String, dynamic>>[];
    final patients = <Map<String, dynamic>>[];
    users.forEach((key, value) {
      final map = Map<String, dynamic>.from(value);
      final role = map['role']?.toString() ?? map['type']?.toString();
      if (role == 'dental_student') {
        students.add({...map, 'id': key});
      } else if (role == 'patient') {
        patients.add({...map, 'id': key});
      }
    });
    setState(() {
      _students = students;
      _patients = patients;
      _isLoading = false;
    });
  }

  Future<void> _loadAssignedPatients(String studentId) async {
    setState(() { _isLoading = true; });
    final snapshot = await _studentPatientsRef.child(studentId).get();
    final data = snapshot.value as Map<dynamic, dynamic>?;
    setState(() {
      _selectedPatientIds = data != null ? data.keys.map((e) => e.toString()).toSet() : {};
      _isLoading = false;
    });
  }

  Future<void> _saveAssignments() async {
    if (_selectedStudentId == null) return;
    setState(() { _saving = true; });
    final updates = <String, dynamic>{};
    for (final patient in _patients) {
      final patientId = patient['id'].toString();
      updates['$_selectedStudentId/$patientId'] = _selectedPatientIds.contains(patientId) ? true : null;
    }
    await _studentPatientsRef.update(updates);
    setState(() { _saving = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعيينات بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعيين المرضى للطالب')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر الطالب:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedStudentId,
                    hint: const Text('اختر الطالب'),
                    isExpanded: true,
                    items: _students.map((student) {
                      final name = student['firstName'] ?? '';
                      return DropdownMenuItem<String>(
                        value: student['id'],
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() { _selectedStudentId = val; });
                      if (val != null) _loadAssignedPatients(val);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_selectedStudentId != null)
                    Expanded(
                      child: ListView(
                        children: _patients.map((patient) {
                          final patientId = patient['id'].toString();
                          final name = patient['firstName'] ?? '';
                          return CheckboxListTile(
                            value: _selectedPatientIds.contains(patientId),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedPatientIds.add(patientId);
                                } else {
                                  _selectedPatientIds.remove(patientId);
                                }
                              });
                            },
                            title: Text(name),
                          );
                        }).toList(),
                      ),
                    ),
                  if (_selectedStudentId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveAssignments,
                        child: _saving ? const CircularProgressIndicator() : const Text('حفظ التعيينات'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
