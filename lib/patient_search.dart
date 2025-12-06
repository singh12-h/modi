import 'package:flutter/material.dart';

class PatientSearch extends StatefulWidget {
  const PatientSearch({super.key});

  @override
  State<PatientSearch> createState() => _PatientSearchState();
}

class _PatientSearchState extends State<PatientSearch> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String _selectedDoctor = 'All Doctors';
  String _selectedStatus = 'All Status';
  String _selectedGender = 'All';
  RangeValues _ageRange = const RangeValues(0, 100);

  final List<Map<String, String>> _searchResults = [
    {
      'name': 'John Doe',
      'mobile': '+91-98765-43210',
      'age': '35',
      'gender': 'Male',
      'lastVisit': '15 Nov 2024'
    },
    {
      'name': 'Alice Brown',
      'mobile': '+91-98765-43211',
      'age': '28',
      'gender': 'Female',
      'lastVisit': '10 Nov 2024'
    },
  ];

  void _selectFromDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _fromDate = pickedDate;
      });
    }
  }

  void _selectToDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _toDate = pickedDate;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = DateTime.now().subtract(const Duration(days: 30));
      _toDate = DateTime.now();
      _selectedDoctor = 'All Doctors';
      _selectedStatus = 'All Status';
      _selectedGender = 'All';
      _ageRange = const RangeValues(0, 100);
    });
  }

  void _applyFilters() {
    // Placeholder for filter logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters Applied')),
    );
  }

  void _viewDetails(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for $name')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Search & Filter'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 9.1 Search Bar
            TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search patients... Name, Mobile, Token',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // 9.2 Filter Options
            const Text(
              'Filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Date Range
                    Row(
                      children: [
                        Expanded(
                          child: Text('From: ${_fromDate.day}/${_fromDate.month}/${_fromDate.year}'),
                        ),
                        ElevatedButton(
                          onPressed: _selectFromDate,
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('To: ${_toDate.day}/${_toDate.month}/${_toDate.year}'),
                        ),
                        ElevatedButton(
                          onPressed: _selectToDate,
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Doctor Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDoctor,
                      decoration: const InputDecoration(labelText: 'Doctor'),
                      items: const [
                        DropdownMenuItem(value: 'All Doctors', child: Text('All Doctors')),
                        DropdownMenuItem(value: 'Dr. Sharma', child: Text('Dr. Sharma')),
                        DropdownMenuItem(value: 'Dr. Patel', child: Text('Dr. Patel')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDoctor = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'All Status', child: Text('All Status')),
                        DropdownMenuItem(value: 'Active', child: Text('Active')),
                        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Age Range
                    Text('Age Range: ${_ageRange.start.round()} - ${_ageRange.end.round()}'),
                    RangeSlider(
                      values: _ageRange,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      labels: RangeLabels(
                        _ageRange.start.round().toString(),
                        _ageRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _resetFilters,
                          child: const Text('RESET'),
                        ),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          child: const Text('APPLY FILTERS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 9.3 Search Results
            Text(
              'Found ${_searchResults.length} results',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final patient = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(patient['mobile']!),
                              Text('Age: ${patient['age']} | ${patient['gender']}'),
                              Text('Last Visit: ${patient['lastVisit']}'),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _viewDetails(patient['name']!),
                          child: const Text('VIEW DETAILS'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // 9.4 Advanced Search
            const Text(
              'Advanced Search',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search by diagnosis')),
                    );
                  },
                  child: const Text('By Diagnosis'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search by medicine')),
                    );
                  },
                  child: const Text('By Medicine'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search by date range')),
                    );
                  },
                  child: const Text('By Date Range'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search by payment status')),
                    );
                  },
                  child: const Text('By Payment Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
