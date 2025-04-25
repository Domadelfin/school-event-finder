import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabase = Supabase.instance.client;

class Organizations extends StatefulWidget {
  const Organizations({super.key});

  @override
  State<Organizations> createState() => _OrganizationState();
}

class _OrganizationState extends State<Organizations> {
  List<dynamic> organizations = [];

  @override
  void initState() {
    super.initState();
    fetchOrganizations();
  }

  Future<void> fetchOrganizations() async {
    final response = await supabase.from('organizations').select();
    setState(() {
      organizations = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: organizations.length,
      itemBuilder: (context, index) {
        final org = organizations[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(org['name']),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${org['email']}'),
                    Text('Mobile: ${org['mobile']}'),
                    Text('Facebook: ${org['facebook']}'),
                    Text('Status: ${org['status']}'),
                  ],
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (org['banner'] != null) 
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                    child: Image.network(org['banner'], height: 150, fit: BoxFit.cover),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (org['logo'] != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(org['logo']),
                          radius: 30,
                        ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(org['acronym'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(org['name'], style: const TextStyle(fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(org['category'], style: const TextStyle(fontSize: 12)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
