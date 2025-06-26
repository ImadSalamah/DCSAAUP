import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../providers/language_provider.dart';
import '../Doctor/doctor_sidebar.dart';
import '../Student/student_sidebar.dart';

class ExaminedPatientsPage extends StatefulWidget {
  final String? studentName;
  final String? studentImageUrl;
  const ExaminedPatientsPage({Key? key, this.studentName, this.studentImageUrl}) : super(key: key);

  @override
  State<ExaminedPatientsPage> createState() => _ExaminedPatientsPageState();
}

class _ExaminedPatientsPageState extends State<ExaminedPatientsPage> {
  // تعريف الألوان
  static const Color primaryColor = Color(0xFF2A7A94);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color borderColor = Color(0xFFEEEEEE);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  final DatabaseReference _examinationsRef =
      FirebaseDatabase.instance.ref('examinations');
  final DatabaseReference _doctorsRef = FirebaseDatabase.instance.ref('staff');
  final DatabaseReference _patientsRef = FirebaseDatabase.instance.ref('users');

  List<Map<String, dynamic>> _examinedPatients = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredExaminations = [];

  String? _doctorName;
  String? _doctorImageUrl;
  String? _userRole;

  final Map<String, Map<String, String>> _translations = {
    'examined_patients': {'ar': 'المرضى المفحوصين', 'en': 'Examined Patients'},
    'name': {'ar': 'الاسم', 'en': 'Name'},
    'phone': {'ar': 'الهاتف', 'en': 'Phone'},
    'age': {'ar': 'العمر', 'en': 'Age'},
    'no_patients': {'ar': 'لا يوجد مرضى مفحوصين', 'en': 'No examined patients'},
    'error_loading': {
      'ar': 'خطأ في تحميل البيانات',
      'en': 'Error loading data'
    },
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'examination_date': {'ar': 'تاريخ الفحص', 'en': 'Examination Date'},
    'examining_doctor': {'ar': 'الطبيب المختص', 'en': 'Examining Doctor'},
    'examination_details': {'ar': 'تفاصيل الفحص', 'en': 'Examination Details'},
    'back': {'ar': 'رجوع', 'en': 'Back'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'patient_information': {
      'ar': 'معلومات المريض',
      'en': 'Patient Information'
    },
    'examination_information': {
      'ar': 'معلومات الفحص',
      'en': 'Examination Information'
    },
    'extraoral_examination': {
      'ar': 'الفحص الخارجي',
      'en': 'Extraoral Examination'
    },
    'intraoral_examination': {
      'ar': 'الفحص الداخلي',
      'en': 'Intraoral Examination'
    },
    'soft_tissue_examination': {
      'ar': 'فحص الأنسجة الرخوة',
      'en': 'Soft Tissue Examination'
    },
    'periodontal_chart': {'ar': 'جدول اللثة', 'en': 'Periodontal Chart'},
    'dental_chart': {'ar': 'جدول الأسنان', 'en': 'Dental Chart'},
    'search_hint': {
      'ar': 'ابحث بالاسم أو رقم الهاتف...',
      'en': 'Search by name or phone...'
    },
    'years': {'ar': 'سنة', 'en': 'years'},
    'months': {'ar': 'شهر', 'en': 'months'},
    'days': {'ar': 'يوم', 'en': 'days'},
    'age_unknown': {'ar': 'العمر غير معروف', 'en': 'Age unknown'},
    'unknown': {'ar': 'غير معروف', 'en': 'Unknown'},
    'no_number': {'ar': 'بدون رقم', 'en': 'No number'},
    'switch_to_arabic': {'ar': 'التبديل إلى العربية', 'en': 'Switch to Arabic'},
    'switch_to_english': {
      'ar': 'التبديل إلى الإنجليزية',
      'en': 'Switch to English'
    },
    'caries': {'ar': 'نخر', 'en': 'Caries'},
    'filled': {'ar': 'حشوة', 'en': 'Filled'},
    'root_canal': {'ar': 'معالجة لب', 'en': 'Root Canal'},
    'extraction_needed': {'ar': 'يحتاج خلع', 'en': 'Extraction Needed'},
    'crown': {'ar': 'تاج', 'en': 'Crown'},
    'impacted': {'ar': 'منطبر', 'en': 'Impacted'},
    'missing': {'ar': 'مفقود', 'en': 'Missing'},
    'delete_old_exams': {
      'ar': 'حذف الفحوصات القديمة',
      'en': 'Delete old exams'
    },
    'delete_confirmation': {
      'ar': 'هل تريد حذف الفحوصات القديمة؟',
      'en': 'Delete old examinations?'
    },
    'deleting': {'ar': 'جاري الحذف...', 'en': 'Deleting...'},
    'deleted_success': {
      'ar': 'تم حذف الفحوصات القديمة بنجاح',
      'en': 'Old exams deleted successfully'
    },
    'tooth': {'ar': 'سن', 'en': 'Tooth'},
    'delete_confirmation_message': {
      'ar': 'سيتم حذف جميع الفحوصات القديمة والاحتفاظ بأحدث فحص لكل مريض فقط.',
      'en':
          'All old examinations will be deleted, keeping only the latest exam for each patient.'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadAllExaminations();
    _searchController.addListener(_filterExaminations);
    if (widget.studentName != null || widget.studentImageUrl != null) {
      setState(() {
        _doctorName = widget.studentName;
        _doctorImageUrl = widget.studentImageUrl;
        _userRole = 'dental_student';
      });
    } else {
      _loadDoctorSidebarInfo();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(BuildContext context, String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]?[languageProvider.isEnglish ? 'en' : 'ar'] ?? key;
  }

  Map<String, dynamic> _safeConvertMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        debugPrint('Error converting map: $e');
        return {};
      }
    }
    return {};
  }

  Future<void> _deleteOldExaminations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final DataSnapshot examinationsSnapshot = await _examinationsRef.get();
      if (!examinationsSnapshot.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> examinations =
          _safeConvertMap(examinationsSnapshot.value);
      final Map<String, Map<String, dynamic>> latestExaminations = {};

      // تحديد أحدث فحص لكل مريض
      examinations.forEach((key, value) {
        final examData = _safeConvertMap(value);
        final String? patientId = examData['patientId']?.toString();

        if (patientId == null || patientId.isEmpty) return;

        if (!latestExaminations.containsKey(patientId) ||
            (examData['timestamp'] ?? 0) >
                (latestExaminations[patientId]!['timestamp'] ?? 0)) {
          latestExaminations[patientId] = {
            ...examData,
            'key': key,
          };
        }
      });

      // حذف الفحوصات القديمة
      int deletedCount = 0;
      await Future.forEach(examinations.entries, (entry) async {
        final examData = _safeConvertMap(entry.value);
        final String? patientId = examData['patientId']?.toString();

        if (patientId == null || patientId.isEmpty) return;

        if (latestExaminations.containsKey(patientId)) {
          if (latestExaminations[patientId]!['key'] != entry.key) {
            await _examinationsRef.child(entry.key).remove();
            deletedCount++;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_translate(context, 'deleted_success')} ($deletedCount)'),
            backgroundColor: successColor,
          ),
        );
        _loadAllExaminations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_translate(context, 'error_loading')}: $e'),
            backgroundColor: errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_translate(context, 'delete_confirmation')),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(_translate(context, 'delete_confirmation_message')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(_translate(context, 'back')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                _translate(context, 'delete_old_exams'),
                style: const TextStyle(color: errorColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOldExaminations();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAllExaminations() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _examinedPatients = [];
      });

      final DataSnapshot examinationsSnapshot = await _examinationsRef.get();
      if (!examinationsSnapshot.exists) {
        setState(() {
          _isLoading = false;
          _filteredExaminations = [];
        });
        return;
      }

      final Map<String, dynamic> examinations =
          _safeConvertMap(examinationsSnapshot.value);
      final Map<String, Map<String, dynamic>> latestExaminations = {};

      // تحديد أحدث فحص لكل مريض
      examinations.forEach((key, value) {
        final examData = _safeConvertMap(value);
        final String? patientId = examData['patientId']?.toString();

        if (patientId == null || patientId.isEmpty) return;

        if (!latestExaminations.containsKey(patientId) ||
            (examData['timestamp'] ?? 0) >
                (latestExaminations[patientId]!['examination']['timestamp'] ??
                    0)) {
          latestExaminations[patientId] = {
            'examination': examData,
            'examinationId': key,
          };
        }
      });

      // تحميل بيانات المرضى والأطباء
      final List<Map<String, dynamic>> allExaminations = [];
      await Future.forEach(latestExaminations.entries, (entry) async {
        try {
          final String patientId = entry.key;
          final examData = entry.value;

          final DataSnapshot patientSnapshot =
              await _patientsRef.child(patientId).get();
          if (!mounted) return;
          if (!patientSnapshot.exists) return;

          final Map<String, dynamic> patientData =
              _safeConvertMap(patientSnapshot.value);
          patientData['id'] = patientId;

          final String? doctorId =
              examData['examination']['doctorId']?.toString();
          Map<String, dynamic> doctorData = {
            'name': _translate(context, 'unknown')
          };

          if (doctorId != null && doctorId.isNotEmpty) {
            final DataSnapshot doctorSnapshot =
                await _doctorsRef.child(doctorId).get();
            if (!mounted) return;
            if (doctorSnapshot.exists) {
              doctorData = _safeConvertMap(doctorSnapshot.value);
              doctorData['name'] =
                  doctorData['fullName'] ?? _translate(context, 'unknown');
            }
          }

          allExaminations.add({
            'patient': patientData,
            'examination': examData['examination'],
            'doctor': doctorData,
            'examinationId': examData['examinationId'],
          });
        } catch (e) {
          debugPrint('Error processing patient ${entry.key}: $e');
        }
      });

      // ترتيب الفحوصات حسب التاريخ (الأحدث أولاً)
      allExaminations.sort((a, b) {
        final aTime = a['examination']['timestamp'] ?? 0;
        final bTime = b['examination']['timestamp'] ?? 0;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _examinedPatients = allExaminations;
        _filteredExaminations = List.from(allExaminations);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading examinations: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _filterExaminations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExaminations = _examinedPatients.where((exam) {
        final patient = exam['patient'] as Map<String, dynamic>;
        final fullName = _getFullName(patient).toLowerCase();
        final phone = patient['phone']?.toString().toLowerCase() ?? '';
        return fullName.contains(query) || phone.contains(query);
      }).toList();
    });
  }

  String _getFullName(Map<String, dynamic> patient) {
    return '${patient['firstName'] ?? ''} ${patient['fatherName'] ?? ''} ${patient['grandfatherName'] ?? ''} ${patient['familyName'] ?? ''}'
        .trim();
  }

  Widget _buildPatientCard(
      Map<String, dynamic> patientExam, BuildContext context) {
    final patient = _safeConvertMap(patientExam['patient']);
    final exam = _safeConvertMap(patientExam['examination']);
    final doctor = _safeConvertMap(patientExam['doctor']);

    final fullName = _getFullName(patient);
    final phone = patient['phone'] ?? _translate(context, 'no_number');
    final age = _calculateAge(context, patient['birthDate']);
    final examDate = exam['timestamp'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(exam['timestamp']))
        : _translate(context, 'unknown');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPatientDetails(context, patientExam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fullName.isNotEmpty
                          ? fullName
                          : _translate(context, 'unknown'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.person, '${_translate(context, 'age')}: $age'),
              _buildInfoRow(
                  Icons.phone, '${_translate(context, 'phone')}: $phone'),
              _buildInfoRow(Icons.calendar_today,
                  '${_translate(context, 'examination_date')}: $examDate'),
              _buildInfoRow(Icons.medical_services,
                  '${_translate(context, 'examining_doctor')}: ${doctor['name']}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(
      BuildContext context, Map<String, dynamic> patientExam) {
    final patient = _safeConvertMap(patientExam['patient']);
    final exam = _safeConvertMap(patientExam['examination']);
    final doctor = _safeConvertMap(patientExam['doctor']);
    final examData = _safeConvertMap(exam['examData']);
    final screeningData = _safeConvertMap(examData['screening']);

    final fullName = _getFullName(patient);
    final examDate = exam['timestamp'] != null
        ? DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(exam['timestamp']))
        : _translate(context, 'unknown');

    final bool isLargeScreen = MediaQuery.of(context).size.width >= 900;
    final Color primaryColor = const Color(0xFF2A7A94);
    final Color accentColor = const Color(0xFF4AB8D8);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false, // لا تظهر سهم الرجوع
            title: Text(
              _translate(context, 'examination_details'),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 2,
            centerTitle: true,
            leading: null, // تأكيد عدم وجود أيقونة
            actions: [], // تأكيد عدم وجود أيقونات يمين
          ),
          backgroundColor: backgroundColor,
          drawer: (_userRole == 'dental_student'
              ? StudentSidebar(
                  studentName: _doctorName,
                  studentImageUrl: _doctorImageUrl,
                )
              : DoctorSidebar(
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  userName: _doctorName ?? '',
                  userImageUrl: _doctorImageUrl,
                  translate: (ctx, key) => key,
                  parentContext: context,
                )),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection(
                  title: _translate(context, 'patient_information'),
                  children: [
                    _buildDetailItem(_translate(context, 'name'), fullName),
                    _buildDetailItem(_translate(context, 'age'),
                        _calculateAge(context, patient['birthDate'])),
                    _buildDetailItem(_translate(context, 'gender'),
                        patient['gender'] ?? _translate(context, 'unknown')),
                    _buildDetailItem(_translate(context, 'phone'),
                        patient['phone'] ?? _translate(context, 'no_number')),
                  ],
                ),
                _buildDetailSection(
                  title: _translate(context, 'examination_information'),
                  children: [
                    _buildDetailItem(_translate(context, 'examining_doctor'),
                        doctor['name']),
                    _buildDetailItem(
                        _translate(context, 'examination_date'), examDate),
                  ],
                ),
                if (screeningData.isNotEmpty)
                  _buildDetailSection(
                    title: 'Screening Form',
                    children: _buildScreeningDetails(screeningData),
                  ),
                if (examData.isNotEmpty) ...[
                  _buildDetailSection(
                    title: _translate(context, 'extraoral_examination'),
                    children: [
                      _buildDetailItem(
                          'TMJ', examData['tmj']?.toString() ?? 'N/A'),
                      _buildDetailItem('Lymph Node',
                          examData['lymphNode']?.toString() ?? 'N/A'),
                      _buildDetailItem('Patient Profile',
                          examData['patientProfile']?.toString() ?? 'N/A'),
                      _buildDetailItem('Lip Competency',
                          examData['lipCompetency']?.toString() ?? 'N/A'),
                    ],
                  ),
                  _buildDetailSection(
                    title: _translate(context, 'intraoral_examination'),
                    children: [
                      _buildDetailItem(
                          'Incisal Classification',
                          examData['incisalClassification']?.toString() ??
                              'N/A'),
                      _buildDetailItem(
                          'Overjet', examData['overjet']?.toString() ?? 'N/A'),
                      _buildDetailItem('Overbite',
                          examData['overbite']?.toString() ?? 'N/A'),
                    ],
                  ),
                  _buildDetailSection(
                    title: _translate(context, 'soft_tissue_examination'),
                    children: [
                      _buildDetailItem('Hard Palate',
                          examData['hardPalate']?.toString() ?? 'N/A'),
                      _buildDetailItem('Buccal Mucosa',
                          examData['buccalMucosa']?.toString() ?? 'N/A'),
                      _buildDetailItem('Floor of Mouth',
                          examData['floorOfMouth']?.toString() ?? 'N/A'),
                      _buildDetailItem('Edentulous Ridge',
                          examData['edentulousRidge']?.toString() ?? 'N/A'),
                    ],
                  ),
                  if (examData['periodontalChart'] != null &&
                      examData['periodontalChart'] is Map)
                    _buildDetailSection(
                      title: _translate(context, 'periodontal_chart'),
                      children: _buildPeriodontalDetails(
                          _safeConvertMap(examData['periodontalChart'])),
                    ),
                  if (examData['dentalChart'] != null &&
                      examData['dentalChart'] is Map)
                    _buildDetailSection(
                      title: _translate(context, 'dental_chart'),
                      children: _buildDentalChartDetails(
                          _safeConvertMap(examData['dentalChart']), context),
                    ),
                ],
                // إضافة كارد صورة الأشعة بعد كل بيانات الفحص
                _buildXrayImageCard(patientExam, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScreeningDetails(Map<String, dynamic> screening) {
    final List<Widget> widgets = [];
    void add(String label, dynamic value) {
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(_buildDetailItem(label, value.toString()));
      }
    }

    add('Chief Complaint', screening['chiefComplaint']);
    add('Medications', screening['medications']);
    add('Positive Answers Explanation',
        screening['positiveAnswersExplanation']);
    add('Preventive Advice', screening['preventiveAdvice']);
    add('Total Score', screening['totalScore']);
    // يمكن إضافة المزيد حسب الحاجة
    return widgets;
  }

  List<Widget> _buildPeriodontalDetails(Map<String, dynamic> chart) {
    return chart.entries.map((entry) {
      return _buildDetailItem(entry.key, entry.value.toString());
    }).toList();
  }

  List<Widget> _buildDentalChartDetails(
      Map<String, dynamic> chart, BuildContext context) {
    final List<Widget> widgets = [];

    if (chart['selectedTeeth'] != null && chart['selectedTeeth'] is List) {
      widgets.add(_buildDetailItem(
        'Selected Teeth',
        (chart['selectedTeeth'] as List).join(', '),
      ));
    }

    if (chart['teethConditions'] != null && chart['teethConditions'] is Map) {
      final conditions = _safeConvertMap(chart['teethConditions']);
      conditions.forEach((tooth, color) {
        if (color is String) {
          final colorMeaning = _getColorMeaning(color);
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(
                      '${_translate(context, 'tooth')} $tooth - ${_translate(context, colorMeaning.toLowerCase())}'),
                ],
              ),
            ),
          );
        }
      });
    }

    return widgets;
  }

  String _getColorMeaning(String hexColor) {
    final colorMap = {
      'ff000000': 'caries',
      'ffffa500': 'filled',
      'ff8b4513': 'root_canal',
      'fff44336': 'extraction_needed',
      'ff607d8b': 'crown',
      'ffffd700': 'impacted',
      'ffffff00': 'missing',
    };
    return colorMap[hexColor.toLowerCase()] ?? 'unknown';
  }

  Color _parseColor(String color) {
    try {
      String hexColor = color;
      if (hexColor.startsWith('ff')) {
        hexColor = '0x$hexColor';
      }
      return Color(int.tryParse(hexColor) ?? 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildDetailSection(
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAge(BuildContext context, dynamic birthDateValue) {
    if (birthDateValue == null) return _translate(context, 'age_unknown');

    final int timestamp;
    if (birthDateValue is String) {
      timestamp = int.tryParse(birthDateValue) ?? 0;
    } else if (birthDateValue is int) {
      timestamp = birthDateValue;
    } else {
      timestamp = 0;
    }

    if (timestamp <= 0) return _translate(context, 'age_unknown');

    final birthDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (birthDate.isAfter(now)) return _translate(context, 'age_unknown');

    final age = now.difference(birthDate);
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    final days = (age.inDays % 365) % 30;

    if (years > 0) {
      return '$years ${_translate(context, 'years')}';
    } else if (months > 0) {
      return '$months ${_translate(context, 'months')}';
    } else {
      return '$days ${_translate(context, 'days')}';
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: _translate(context, 'search_hint'),
          prefixIcon: const Icon(Icons.search, color: textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: errorColor),
          const SizedBox(height: 20),
          Text(
            _translate(context, 'error_loading'),
            style: const TextStyle(fontSize: 18, color: textPrimary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAllExaminations,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _translate(context, 'retry'),
              style: const TextStyle(color: cardColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDoctorSidebarInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await _patientsRef.child(user.uid).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final role = data['role']?.toString() ?? data['type']?.toString();
      final firstName = data['firstName']?.toString().trim() ?? '';
      final fatherName = data['fatherName']?.toString().trim() ?? '';
      final grandfatherName = data['grandfatherName']?.toString().trim() ?? '';
      final familyName = data['familyName']?.toString().trim() ?? '';
      final fullName = [firstName, fatherName, grandfatherName, familyName].where((e) => e.isNotEmpty).join(' ');
      if (role == 'dental_student') {
        final imageUrl = data['imageUrl']?.toString() ?? '';
        setState(() {
          _doctorName = fullName.isNotEmpty ? fullName : 'الطالب';
          _doctorImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
          _userRole = role;
        });
      } else {
        final imageData = data['image']?.toString() ?? '';
        setState(() {
          _doctorName = fullName.isNotEmpty ? fullName : null;
          _doctorImageUrl = imageData.isNotEmpty ? 'data:image/jpeg;base64,$imageData' : null;
          _userRole = role;
        });
      }
    } else {
      setState(() {
        _doctorName = null;
        _doctorImageUrl = null;
        _userRole = null;
      });
    }
  }

  // كاش مؤقت لصور الأشعة
  Map<String, String?> _xrayImageCache = {};

  // جلب صورة الأشعة من xray_images حسب patientId أو idNumber
  Future<String?> _getXrayImageForPatient(String? patientId, String? idNumber) async {
    final String cacheKey = patientId ?? idNumber ?? '';
    if (_xrayImageCache.containsKey(cacheKey)) {
      return _xrayImageCache[cacheKey];
    }
    final ref = FirebaseDatabase.instance.ref('xray_images');
    final snapshot = await ref.get();
    if (!snapshot.exists) return null;
    final data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        final map = Map<String, dynamic>.from(value);
        if ((patientId != null && map['patientId']?.toString() == patientId) ||
            (idNumber != null && map['idNumber']?.toString() == idNumber)) {
          final xrayImage = map['xrayImage']?.toString();
          _xrayImageCache[cacheKey] = xrayImage;
          return xrayImage;
        }
      }
    }
    _xrayImageCache[cacheKey] = null;
    return null;
  }

  // كارد صورة الأشعة (يبحث في xray_images)
  Widget _buildXrayImageCard(Map<String, dynamic> patientExam, BuildContext context) {
    final patient = _safeConvertMap(patientExam['patient']);
    final String? patientId = patient['id']?.toString();
    final String? idNumber = patient['idNumber']?.toString();
    final String cacheKey = patientId ?? idNumber ?? '';

    return FutureBuilder<String?>(
      future: _getXrayImageForPatient(patientId, idNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final String? xrayBase64 = snapshot.data;
        if (xrayBase64 == null || xrayBase64.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(16),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.image_not_supported, color: textSecondary),
                  SizedBox(width: 12),
                  Text(
                    'لا توجد صورة أشعة مرفوعة',
                    style: const TextStyle(color: textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        try {
          final bytes = base64Decode(xrayBase64);
          return Card(
            margin: const EdgeInsets.all(16),
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'صورة الأشعة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: InteractiveViewer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ); // تصحيح: إزالة الفاصلة المنقوطة الزائدة
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text('تعذر تحميل صورة الأشعة', style: const TextStyle(color: errorColor)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return Card(
            margin: const EdgeInsets.all(16),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('تعذر عرض صورة الأشعة', style: const TextStyle(color: errorColor)),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 900;
    final Color primaryColor = const Color(0xFF2A7A94);
    final Color accentColor = const Color(0xFF4AB8D8);
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate(context, 'examined_patients')),
        backgroundColor: primaryColor, // جعل لون الاب بار نفس اللون الاساسي
      ),
      drawer: (_userRole == 'dental_student'
          ? StudentSidebar(
              studentName: _doctorName,
              studentImageUrl: _doctorImageUrl,
            )
          : DoctorSidebar(
              primaryColor: primaryColor,
              accentColor: accentColor,
              userName: _doctorName ?? '',
              userImageUrl: _doctorImageUrl,
              translate: (ctx, key) => key,
              parentContext: context,
            )),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchField(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : _hasError
                        ? _buildErrorWidget()
                        : _filteredExaminations.isEmpty
                            ? Center(
                                child: Text(
                                  _translate(context, 'no_patients'),
                                  style: const TextStyle(color: textSecondary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredExaminations.length,
                                itemBuilder: (context, index) {
                                  return _buildPatientCard(
                                      _filteredExaminations[index], context);
                                },
                              ),
              ),
              // كارد صورة الأشعة في أسفل الصفحة
              // تم حذف كارد صورة الأشعة من قائمة المرضى ليظهر فقط في تفاصيل المريض
            ],
          ),
        ],
      ),
    );
  }
}
