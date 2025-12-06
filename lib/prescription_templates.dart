import 'package:flutter/material.dart';

class PrescriptionTemplates extends StatefulWidget {
  const PrescriptionTemplates({super.key});

  @override
  State<PrescriptionTemplates> createState() => _PrescriptionTemplatesState();
}

class _PrescriptionTemplatesState extends State<PrescriptionTemplates> {
  final List<Map<String, dynamic>> _templates = [
    {
      'name': 'Fever & Cold',
      'icon': '🤒',
      'medicines': ['Paracetamol 500mg', 'Cetrizine 10mg', 'Cough syrup'],
    },
    {
      'name': 'Gastric Problem',
      'icon': '🤮',
      'medicines': ['Pantoprazole 40mg', 'Antacid syrup'],
    },
    {
      'name': 'Dental Pain',
      'icon': '🦷',
      'medicines': ['Ibuprofen 400mg', 'Amoxicillin 500mg'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Templates'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                var template = _templates[index];
                return Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(template['icon'], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Text(
                              template['name'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...template['medicines'].map<Widget>((medicine) => Text('• $medicine')).toList(),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _useTemplate(template['name']),
                          child: const Text('USE TEMPLATE'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('CREATE NEW TEMPLATE'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$templateName template used')),
    );
  }
}
