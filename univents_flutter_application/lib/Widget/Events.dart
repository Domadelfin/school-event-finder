import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_event_form.dart';
import 'update_event_form.dart'; // Add this!

final SupabaseClient supabase = Supabase.instance.client;

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  List<dynamic> events = [];
  Map<String, dynamic> organizations = {};

  @override
  void initState() {
    super.initState();
    fetchEventsAndOrgs();
  }

  Future<void> fetchEventsAndOrgs() async {
    try {
      final eventResponse = await supabase.from('events').select();
      final orgResponse = await supabase.from('organizations').select();

      final Map<String, dynamic> orgMap = {
        for (var org in orgResponse) org['uid']: org,
      };

      setState(() {
        events = eventResponse;
        organizations = orgMap;
      });
    } catch (e) {
      debugPrint('Error fetching events or organizations: $e');
    }
  }

  String formatDateRange(String? start, String? end) {
    if (start == null || end == null) return '';

    final DateTime startDate = DateTime.parse(start);
    final DateTime endDate = DateTime.parse(end);

    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${DateFormat('MMMM d, yyyy').format(startDate)} • ${DateFormat('h:mm a').format(startDate)} - ${DateFormat('h:mm a').format(endDate)}';
    } else {
      return '${DateFormat('MMMM d, yyyy h:mm a').format(startDate)} - ${DateFormat('MMMM d, yyyy h:mm a').format(endDate)}';
    }
  }

  void _openAddEventForm() async {
    final result = await showDialog(
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

    fetchEventsAndOrgs();
  }

  void _openUpdateEventForm(Map<String, dynamic> eventData) async {
    final result = await showDialog(
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

    fetchEventsAndOrgs();
  }

  void _deleteEvent(Map<String, dynamic> event) async {
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

      debugPrint('Deleted event: ${event['uid']}');
      await fetchEventsAndOrgs();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting event: $e');

      // Close the loading spinner
      Navigator.of(context).pop();

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: events.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final org = organizations[event['orguid']];

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(event['title'] ?? ''),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description: ${event['description'] ?? 'No description.'}'),
                                const SizedBox(height: 12),
                                Text('Location: ${event['location'] ?? 'TBA'}'),
                                Text('Start: ${event['datetimestart'] ?? ''}'),
                                Text('End: ${event['datetimeend'] ?? ''}'),
                                Text('Type: ${event['type'] ?? ''}'),
                                Text('Tags: ${event['tags'] ?? ''}'),
                                Text('Status: ${event['status'] ?? ''}'),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  event['eventbanner'] ?? '',
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: org?['logo'] != null
                                      ? NetworkImage(org['logo'])
                                      : null,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      event['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event['location'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formatDateRange(event['datetimestart'], event['datetimeend']),
                                      style: const TextStyle(fontSize: 11),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        event['type'] ?? '',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event['tags'] ?? '',
                                      style: const TextStyle(fontSize: 10, color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _openUpdateEventForm(event);
                              } else if (value == 'delete') {
                                bool? confirmDelete = await showModalBottomSheet<bool>(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) {
                                    return Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Delete Event?',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Are you sure you want to delete this event? This action cannot be undone.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, color: Colors.black54),
                                          ),
                                          const SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.grey.shade300,
                                                  foregroundColor: Colors.black,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (confirmDelete == true) {
                                  _deleteEvent(event);
                                }
                              } else if (value == 'attendees') {
                                //Handle view attendees action here
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              const PopupMenuItem(value: 'attendees', child: Text('View Attendees')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEventForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
