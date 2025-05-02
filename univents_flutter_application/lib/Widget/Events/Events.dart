import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'events_controller.dart';
import 'View_Attendees.dart';


class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  late EventsController _controller;
  List<dynamic> events = [];
  Map<String, dynamic> organizations = {};

  @override
  void initState() {
    super.initState();
    _controller = EventsController(context: context);
    _loadData();
  }

  Future<void> _loadData() async {
    final fetchedEvents = await _controller.fetchEvents();
    final fetchedOrganizations = await _controller.fetchOrganizations();

    setState(() {
      events = fetchedEvents;
      organizations = fetchedOrganizations;
    });
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
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event Banner
                              if (event['eventbanner'] != null)
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    event['eventbanner'],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Event Title
                                    Text(
                                      event['title'] ?? 'Untitled Event',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    // Event Date Range
                                    Text(
                                      formatDateRange(event['datetimestart'], event['datetimeend']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Organization Name
                                    if (org != null)
                                      Text(
                                        org['name'] ?? 'Unknown Organization',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // "..." Menu at the Top-Right Corner
                          Positioned(
                            top: 4,
                            right: 4,
                            child: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'update') {
                                  await _controller.openUpdateEventForm(event, organizations);
                                  _loadData(); 
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
                                    await _controller.deleteEvent(event); // Call the delete logic from the controller
                                    _loadData(); // Refresh the events list after deletion
                                  }
                                } else if (value == 'attendees') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Attendees(event: event),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'update',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Event'),
                                ),
                                const PopupMenuItem(
                                  value: 'attendees',
                                  child: Text('View Attendees'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _controller.openAddEventForm(organizations);
          _loadData();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
