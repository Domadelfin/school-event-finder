import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_event_form.dart';
import 'update_event_form.dart';

class EventsController {
  final BuildContext context;
  final SupabaseClient supabase;

  EventsController({required this.context, required this.supabase});

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
}