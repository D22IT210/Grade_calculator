import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(GradeCalculatorApp());
}

class GradeCalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grade Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GradeCalculatorHomePage(),
    );
  }
}

class GradeCalculatorHomePage extends StatefulWidget {
  @override
  _GradeCalculatorHomePageState createState() => _GradeCalculatorHomePageState();
}

class _GradeCalculatorHomePageState extends State<GradeCalculatorHomePage> {
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  List<Map<String, dynamic>> grades = [];
  double averageGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Calculator'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Grade',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _gradeController.clear();
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: TextField(
                    controller: _creditController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Credit (optional)',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _creditController.clear();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addGrade,
              child: Text('Add Grade'),
            ),
            SizedBox(height: 16.0),
            if (grades.isNotEmpty) ...[
              Text(
                'Grades:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              _buildGradesList(),
              SizedBox(height: 16.0),
              Text(
                'Average Grade: ${averageGrade.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _resetGrades,
                child: Text('Reset Grades'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradesList() {
    grades.sort((a, b) => a['grade'].compareTo(b['grade']));
    return ListView.builder(
      shrinkWrap: true,
      itemCount: grades.length,
      itemBuilder: (context, index) {
        final grade = grades[index];
        return ListTile(
          title: Text('Grade: ${grade['grade']}%'),
          subtitle: grade['credit'] != null ? Text('Credit: ${grade['credit']}%') : null,
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                grades.removeAt(index);
                _saveGrades();
                _updateAverageGrade();
              });
            },
          ),
        );
      },
    );
  }

  void _addGrade() {
    final grade = int.tryParse(_gradeController.text);
    final credit = _creditController.text.isNotEmpty ? int.tryParse(_creditController.text) : null;

    if (grade != null && grade >= 0 && grade <= 100) {
      setState(() {
        grades.add({'grade': grade, 'credit': credit});
        _saveGrades();
        _updateAverageGrade();
      });
      _gradeController.clear();
      _creditController.clear();
    } else {
      _showErrorDialog('Invalid Grade', 'Please enter a valid grade (0 - 100).');
    }
  }

  void _resetGrades() {
    setState(() {
      grades.clear();
      averageGrade = 0.0;
    });
    _saveGrades();
  }

  void _updateAverageGrade() {
    double totalGrade = 0.0;
    double totalCredit = 0.0;
    for (final grade in grades) {
      final gradeValue = grade['grade'];
      final credit = grade['credit'] ?? 100;
      totalGrade += gradeValue * credit / 100;
      totalCredit += credit;
    }
    averageGrade = totalCredit != 0 ? totalGrade / totalCredit * 100 : 0.0;
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedGrades = prefs.getStringList('grades');
    if (savedGrades != null) {
      setState(() {
        grades = savedGrades.map((grade) => {'grade': int.parse(grade.split(',')[0]), 'credit': int.parse(grade.split(',')[1])}).toList();
        _updateAverageGrade();
      });
    }
  }

  Future<void> _saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stringGrades = grades.map((grade) => '${grade['grade']},${grade['credit'] ?? ''}').toList();
    prefs.setStringList('grades', stringGrades);
  }
}
