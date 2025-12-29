import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContact {
  final String email;
  final String name;

  TrustedContact({required this.email, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
    };
  }

  factory TrustedContact.fromMap(Map<String, dynamic> map) {
    return TrustedContact(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class TrustedParentsPage extends StatefulWidget {
  const TrustedParentsPage({super.key});

  @override
  State<TrustedParentsPage> createState() => _TrustedParentsPageState();
}

class _TrustedParentsPageState extends State<TrustedParentsPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<TrustedContact> _trustedContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrustedContacts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadTrustedContacts() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            final contactsList = (data['trustedContacts'] as List<dynamic>?)
                ?.map((contact) {
                  if (contact is Map<String, dynamic>) {
                    return TrustedContact.fromMap(contact);
                  }
                  return null;
                })
                .where((contact) => contact != null)
                .cast<TrustedContact>()
                .toList() ?? [];
            setState(() {
              _trustedContacts = contactsList;
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trusted contacts: $e')),
        );
      }
    }
  }

  Future<void> _addContact() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    
    if (email.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and email address')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (_trustedContacts.any((contact) => contact.email == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This email is already in the list')),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final newContact = TrustedContact(email: email, name: name);
        final updatedContacts = [..._trustedContacts, newContact];
        
        await _firestore.collection('users').doc(user.uid).update({
          'trustedContacts': updatedContacts.map((c) => c.toMap()).toList(),
        });
        
        setState(() {
          _trustedContacts = updatedContacts;
        });
        
        _emailController.clear();
        _nameController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding contact: $e')),
      );
    }
  }

  Future<void> _removeContact(TrustedContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updatedContacts = _trustedContacts.where((c) => c.email != contact.email).toList();
        await _firestore.collection('users').doc(user.uid).update({
          'trustedContacts': updatedContacts.map((c) => c.toMap()).toList(),
        });
        setState(() {
          _trustedContacts = updatedContacts;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing contact: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Parents'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Contact Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Trusted Parent Contact',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Parent Name',
                        hintText: 'Enter parent\'s name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter parent\'s email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Trusted Emails List Section
            Text(
              'Trusted Parents List',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _trustedContacts.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No trusted parents added yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add parent contacts above to get started',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _trustedContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _trustedContacts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Text(
                                    contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'P',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(contact.name),
                                subtitle: Text(contact.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Remove Contact'),
                                        content: Text(
                                          'Are you sure you want to remove ${contact.name} (${contact.email}) from trusted parents?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _removeContact(contact);
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
