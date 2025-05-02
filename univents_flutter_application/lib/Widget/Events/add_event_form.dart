// ignore_for_file: use_build_context_synchronously

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:univents_flutter_application/Web/supabase_instance.dart';

class AddEventForm extends StatefulWidget {
  final Map<String, dynamic> organizations;

  const AddEventForm({super.key, required this.organizations});

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _eventStatus;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String? _uploadedImageUrl;
  String? _selectedOrgId;

  bool _imageError = false;
  bool _dateError = false;

  final List<String> _statusOptions = ['Upcoming', 'Ongoing', 'Done', 'Postponed', 'Cancelled'];

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
        });
      }
    } catch (e) {
      debugPrint('Image upload failed: $e');
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

  Future<void> _submitForm() async {
    setState(() {
      _imageError = _pickedImageBytes == null;
      _dateError = _startDate == null || _endDate == null || (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!));
    });

    if (!_formKey.currentState!.validate() || _imageError || _dateError) {
      return;
    }

    await _uploadImage();
    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image.')),
      );
      return;
    }

    final eventData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'type': _typeController.text,
      'tags': _tagsController.text,
      'datetimestart': _startDate?.toIso8601String(),
      'datetimeend': _endDate?.toIso8601String(),
      'eventbanner': _uploadedImageUrl,
      'orguid': _selectedOrgId,
      'status': _eventStatus ?? 'Upcoming',
    };

    await supabase.from('events').insert(eventData);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
                    : Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Tap to select event banner')),
                      ),
              ),
              if (_imageError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Event banner is required.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
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
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>( 
                value: _selectedOrgId,
                hint: const Text('Select Organization'),
                items: widget.organizations.entries.map((org) {
                  return DropdownMenuItem<String>(
                    value: org.key,
                    child: Text(org.value['name'] ?? 'Unknown Organization'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOrgId = value;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventStatus,
                hint: const Text('Select Status'),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _eventStatus = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (value) => value == null ? 'Please select a status' : null,
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
              if (_dateError)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Start and End dates are required. Start date must be before End date.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
