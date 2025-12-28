import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String role = 'Teacher';
  String time = 'Evening';
  String frequency = 'Once';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Safety Concern")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              "This report is anonymous.\nNo names are required.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text("Role involved"),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'Coach', child: Text('Coach')),
                DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                DropdownMenuItem(value: 'Peer', child: Text('Peer')),
              ],
              onChanged: (v) => setState(() => role = v!),
            ),

            const SizedBox(height: 16),
            const Text("Time of occurrence"),
            DropdownButton<String>(
              value: time,
              items: const [
                DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                DropdownMenuItem(value: 'Night', child: Text('Night')),
              ],
              onChanged: (v) => setState(() => time = v!),
            ),

            const SizedBox(height: 16),
            const Text("Frequency"),
            DropdownButton<String>(
              value: frequency,
              items: const [
                DropdownMenuItem(value: 'Once', child: Text('Once')),
                DropdownMenuItem(value: 'Repeated', child: Text('Repeated')),
              ],
              onChanged: (v) => setState(() => frequency = v!),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report submitted anonymously")),
                );
                Navigator.pop(context);
              },
              child: const Text("Submit Report"),
            )
          ],
        ),
      ),
    );
  }
}
