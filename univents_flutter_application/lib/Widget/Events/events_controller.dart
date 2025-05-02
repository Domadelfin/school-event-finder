// events_controller.dart
import 'package:flutter/material.dart';
import 'package:univents_flutter_application/Web/supabase_instance.dart';
import 'package:univents_flutter_application/Widget/Events/add_event_form.dart';
import 'package:univents_flutter_application/Widget/Events/update_event_form.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:html' as html;

class EventsController {
  final BuildContext context;

  EventsController({required this.context});

  Future<List<dynamic>> fetchEvents() async {
    try {
      return await supabase.from('events').select();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchOrganizations() async {
    try {
      final orgResponse = await supabase.from('organizations').select();
      return {for (var org in orgResponse) org['uid']: org};
    } catch (e) {
      debugPrint('Error fetching organizations: $e');
      return {};
    }
  }

  Future<void> openAddEventForm(Map<String, dynamic> organizations) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: AddEventForm(organizations: organizations),
          ),
        );
      },
    );
  }

  Future<void> openUpdateEventForm(Map<String, dynamic> eventData, Map<String, dynamic> organizations) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: UpdateEventForm(eventData: eventData, organizations: organizations),
          ),
        );
      },
    );
  }

  Future<void> deleteEvent(Map<String, dynamic> event) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final eventBanner = event['eventbanner'];
      if (eventBanner != null && eventBanner.isNotEmpty) {
        final parts = eventBanner.split('/');
        final imageurl = parts.isNotEmpty ? parts.last : null;

        if (imageurl != null) {
          await supabase.storage.from('event-banner').remove([imageurl]);
        }
      }

      await supabase.from('events').delete().eq('uid', event['uid']);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting event: $e');
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<dynamic>> fetchAttendees(String eventId) async {
    try {
      return await supabase
          .from('attendees')
          .select('datetimestamp, accounts (firstname, lastname, email)')
          .eq('eventid', eventId);
    } catch (e) {
      debugPrint('Error fetching attendees: $e');
      return [];
    }
  }

  Future<void> addOrLinkAttendee({
    required String eventId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final existingAccounts = await supabase
        .from('accounts')
        .select('uid')
        .eq('email', email.trim());

    String accountId;

    if (existingAccounts.isNotEmpty) {
      accountId = existingAccounts.first['uid'];
    } else {
      final newAccount = await supabase.from('accounts').insert({
        'firstname': firstName.trim(),
        'lastname': lastName.trim(),
        'email': email.trim(),
        'role': 'Student',
        'status': 'Active',
      }).select().single();

      accountId = newAccount['uid'];
    }

    final existingAttendee = await supabase
        .from('attendees')
        .select()
        .eq('eventid', eventId)
        .eq('accountid', accountId);

    if (existingAttendee.isEmpty) {
      await supabase.from('attendees').insert({
        'accountid': accountId,
        'eventid': eventId,
        'datetimestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> exportPDF(String eventId, String title, List attendees) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Attendees - $title', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...attendees.asMap().entries.map((entry) {
              final a = entry.value;
              final name = a['accounts'] != null ? '${a['accounts']['firstname']} ${a['accounts']['lastname']}' : 'Unknown';
              final email = a['accounts'] != null ? a['accounts']['email'] ?? '' : 'No email';
              return pw.Text('${entry.key + 1}. $name - $email');
            }),
          ],
        ),
      ),
    );

    Uint8List bytes = await pdf.save();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "attendees_${eventId}.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
