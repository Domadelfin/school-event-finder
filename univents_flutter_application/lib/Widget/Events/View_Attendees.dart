import 'package:flutter/material.dart';
import 'events_controller.dart'; // Make sure to import this
import 'package:univents_flutter_application/Web/supabase_instance.dart';

class Attendees extends StatefulWidget {
  final Map<String, dynamic> event;
  const Attendees({super.key, required this.event});

  @override
  State<Attendees> createState() => _AttendeesState();
}

class _AttendeesState extends State<Attendees> {
  late EventsController _controller;
  List<dynamic> attendees = [];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = EventsController(context: context);
    _loadAttendees();
  }

  Future<void> _loadAttendees() async {
    final data = await _controller.fetchAttendees(widget.event['uid']);
    setState(() {
      attendees = data;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await _controller.addOrLinkAttendee(
        eventId: widget.event['uid'],
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        email: _emailCtrl.text,
      );

      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _loadAttendees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendees: ${widget.event['title']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: attendees.length,
                itemBuilder: (context, index) {
                  final a = attendees[index];
                  final account = a['accounts'];
                  final name = account != null
                      ? '${account['firstname']} ${account['lastname']}'
                      : 'Unknown';
                  final email = account != null ? account['email'] ?? '' : 'No email';

                  return ListTile(
                    title: Text(name),
                    subtitle: Text(email),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.exportPDF(
          widget.event['uid'],
          widget.event['title'],
          attendees,
        ),
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
