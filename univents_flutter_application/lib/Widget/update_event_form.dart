// update_event_form.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final SupabaseClient supabase = Supabase.instance.client;

class UpdateEventForm extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> organizations;

  const UpdateEventForm({super.key, required this.eventData, required this.organizations});

  @override
  State<UpdateEventForm> createState() => _UpdateEventFormState();
}

class _UpdateEventFormState extends State<UpdateEventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _typeController;
  late TextEditingController _tagsController;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _uploadedImageUrl;
  String? _oldImagePath;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _eventStatus;

  bool _dateError = false;

  final List<String> _statusOptions = ['Upcoming', 'Ongoing', 'Done', 'Postponed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['title']);
    _descriptionController = TextEditingController(text: widget.eventData['description']);
    _locationController = TextEditingController(text: widget.eventData['location']);
    _typeController = TextEditingController(text: widget.eventData['type']);
    _tagsController = TextEditingController(text: widget.eventData['tags']);

    _uploadedImageUrl = widget.eventData['eventbanner'];
    _startDate = DateTime.tryParse(widget.eventData['datetimestart'] ?? '');
    _endDate = DateTime.tryParse(widget.eventData['datetimeend'] ?? '');
    _eventStatus = widget.eventData['status'];

    // Save old path for deletion if image is replaced
    if (_uploadedImageUrl != null) {
      final parts = _uploadedImageUrl!.split('/'); 
      _oldImagePath = parts.isNotEmpty ? parts.last : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      final reader = html.FileReader();

      if (file != null) {
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _pickedImageBytes = reader.result as Uint8List;
            _pickedImageName = file.name;
          });
        });
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_pickedImageBytes == null) return;

    try {
      // Delete old image first if a new one is picked
      if (_oldImagePath != null) {
        await deleteOldBanner(_oldImagePath!);
      }

      final uuid = const Uuid().v4();
      final fileExt = _pickedImageName?.split('.').last ?? 'jpg';
      final filePath = '$uuid.$fileExt';

      final response = await supabase.storage
          .from('event-banner')
          .uploadBinary(
            filePath,
            _pickedImageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response.isNotEmpty) {
        final publicURL = supabase.storage.from('event-banner').getPublicUrl(filePath);
        setState(() {
          _uploadedImageUrl = publicURL;
          _oldImagePath = filePath; // Update old path to new image path
        });
      }
    } catch (e) {
      debugPrint('Image upload failed: $e');
    }
  }

  Future<void> deleteOldBanner(String path) async {
    try {
      await supabase.storage.from('event-banner').remove([path]);
      print('Old banner deleted successfully.');
    } catch (e) {
      print('Error deleting old banner: $e');
    }
  }

  Future<void> _submitUpdate() async {
  if (_formKey.currentState!.validate()) {
    try {
      if (_pickedImageBytes != null) {
        await _uploadImage(); // this uploads and updates _uploadedImageUrl
      }

      if (_uploadedImageUrl == null) {
        throw Exception('Image upload failed. No image URL available.');
      }

      setState(() {
        _dateError = _startDate == null || _endDate == null || (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!));
      });

      if (_dateError){
        return;
      }

      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _typeController.text.trim(),
        'tags': _tagsController.text.trim(),
        'datetimestart': _startDate?.toIso8601String(),
        'datetimeend': _endDate?.toIso8601String(),
        'status': _eventStatus,
        'eventbanner': _uploadedImageUrl,
      };


      await supabase.from('events').update(updates).eq('uid', widget.eventData['uid']);
      Navigator.pop(context); // success
    } catch (e) {
      debugPrint('Error during update: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update event.')));
    }
  }
}


  Future<DateTime?> showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Update Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: _pickedImageBytes != null
            ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _pickedImageBytes!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
              )
            : _uploadedImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
              _uploadedImageUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
                ),
              )
            : Container(
                height: 150,
                decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Tap to select event banner')),
              ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _typeController,
            decoration: const InputDecoration(labelText: 'Type'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: 'Tags'),
            validator: (value) => value!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
            final picked = await showDateTimePicker();
            if (picked != null) setState(() => _startDate = picked);
              },
              child: Text(_startDate == null
              ? 'Pick Start Date'
              : 'Start: ${_startDate.toString().substring(0, 16)}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
            final picked = await showDateTimePicker();
            if (picked != null) setState(() => _endDate = picked);
              },
              child: Text(_endDate == null
              ? 'Pick End Date'
              : 'End: ${_endDate.toString().substring(0, 16)}'),
            ),
          ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _eventStatus,
            decoration: const InputDecoration(labelText: 'Event Status'),
            items: _statusOptions.map((status) {
          return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) {
          setState(() {
            _eventStatus = value;
          });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
          if (_formKey.currentState!.validate()) {
            _submitUpdate();
          }
            },
            style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('Update Event', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
          ),
        ),
      ),
      );
  }
}
