import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _currentOrgId;
  String? _currentUserRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUserId = _authService.getCurrentUserId();
      _currentOrgId = await _authService.getCurrentOrganizationId();
      
      debugPrint('Loading people - userId: $_currentUserId, orgId: $_currentOrgId');
      
      if (_currentOrgId != null && _currentUserId != null) {
        // Get current user's role
        final membership = await _supabase
            .from('organization_members')
            .select('role')
            .eq('organization_id', _currentOrgId!)
            .eq('user_id', _currentUserId!)
            .maybeSingle();
        
        _currentUserRole = membership?['role'];
        debugPrint('Current user role: $_currentUserRole');
        
        // Get all members - profiles is linked via profile_id FK
        final members = await _supabase
            .from('organization_members')
            .select('*, profiles!organization_members_profile_id_fkey(profile_id, email)')
            .eq('organization_id', _currentOrgId!)
            .order('role', ascending: true);
        
        debugPrint('Members raw: $members');
        
        // Fetch business_info for each member's profile_id
        final membersList = List<Map<String, dynamic>>.from(members);
        for (var member in membersList) {
          final profileId = member['profile_id'];
          if (profileId != null) {
            try {
              final businessInfo = await _supabase
                  .from('business_info')
                  .select('business_name')
                  .eq('profile_id', profileId)
                  .maybeSingle();
              member['business_info'] = businessInfo;
            } catch (e) {
              debugPrint('Error fetching business_info: $e');
            }
          }
        }
        
        _members = membersList;
        debugPrint('Members loaded: ${_members.length}');
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
    
    setState(() => _isLoading = false);
  }

  bool get _canManagePeople => _currentUserRole == 'owner' || _currentUserRole == 'admin';

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'warden':
        return 'Warden';
      case 'staff':
        return 'Staff';
      default:
        return 'Member';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'manager':
        return Colors.green;
      case 'warden':
        return Colors.orange;
      case 'staff':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.star;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'warden':
        return Icons.security;
      case 'staff':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'staff';
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    if (_currentUserRole == 'owner')
                      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    const DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    const DropdownMenuItem(value: 'warden', child: Text('Warden')),
                    const DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getRoleDescription(selectedRole),
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final result = await _addMemberToOrganization(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          name: nameController.text.trim(),
                          role: selectedRole,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          
                          if (result['success'] == true) {
                            _showCredentialsDialog(
                              emailController.text.trim(),
                              passwordController.text,
                              nameController.text.trim(),
                            );
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to add member'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'admin':
        return 'Admin can manage members and all settings';
      case 'manager':
        return 'Manager can manage tenants, rooms, and view reports';
      case 'warden':
        return 'Warden can view and manage daily operations';
      case 'staff':
        return 'Staff can view basic information only';
      default:
        return 'Basic access to the app';
    }
  }

  Future<Map<String, dynamic>> _addMemberToOrganization({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      if (_currentOrgId == null) {
        return {'success': false, 'message': 'No organization found'};
      }

      // Get organization details
      final org = await _supabase
          .from('organizations')
          .select('name, phone, address')
          .eq('id', _currentOrgId!)
          .single();

      // Call the database function to add user
      final result = await _supabase.rpc('add_user_to_organization', params: {
        'p_organization_id': _currentOrgId,
        'p_email': email.toLowerCase().trim(),
        'p_password': password,
        'p_full_name': name,
        'p_role': role,
        'p_hostel_name': org['name'],
        'p_phone': org['phone'],
        'p_address': org['address'],
      });

      if (result != null && result['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to add member',
        };
      }
    } catch (e) {
      debugPrint('Error adding member: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  void _showCredentialsDialog(String email, String password, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Member Added!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name has been added successfully.'),
            const SizedBox(height: 16),
            const Text(
              'Login Credentials:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Email: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(child: Text(email)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied')),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Password: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(child: Text(password)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share these credentials with the member so they can log in.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    final memberRole = member['role'] ?? 'member';
    final memberUserId = member['user_id'];
    final isCurrentUser = memberUserId == _currentUserId;
    
    // Owner cannot be edited/removed
    if (memberRole == 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify owner account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cannot modify yourself
    if (isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot modify your own account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Role'),
              onTap: () {
                Navigator.pop(context);
                _showChangeRoleDialog(member);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Member', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> member) {
    String currentRole = member['role'] ?? 'member';
    String selectedRole = currentRole;
    final businessInfo = member['business_info'] ?? {};
    final profile = member['profiles'] ?? {};
    final memberName = businessInfo['business_name'] ?? profile['email'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Change Role for $memberName'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            items: [
              if (_currentUserRole == 'owner')
                const DropdownMenuItem(value: 'admin', child: Text('Admin')),
              const DropdownMenuItem(value: 'manager', child: Text('Manager')),
              const DropdownMenuItem(value: 'warden', child: Text('Warden')),
              const DropdownMenuItem(value: 'staff', child: Text('Staff')),
            ],
            onChanged: (value) {
              setDialogState(() {
                selectedRole = value!;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _supabase
                      .from('organization_members')
                      .update({'role': selectedRole})
                      .eq('id', member['id']);

                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$memberName role updated to ${_getRoleDisplayName(selectedRole)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(Map<String, dynamic> member) {
    final businessInfo = member['business_info'] ?? {};
    final profile = member['profiles'] ?? {};
    final memberName = businessInfo['business_name'] ?? profile['email'] ?? 'Unknown';
    final memberEmail = profile['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName ($memberEmail) from this organization?\n\nThey will no longer be able to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete the membership
                await _supabase
                    .from('organization_members')
                    .delete()
                    .eq('id', member['id']);

                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$memberName has been removed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 245),
      appBar: AppBar(
        title: const Text('People'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (_canManagePeople)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showAddMemberDialog,
              tooltip: 'Add Member',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _members.isEmpty
                  ? const Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final role = member['role'] ?? 'member';
                        final profile = member['profiles'] ?? {};
                        final businessInfo = member['business_info'] ?? {};
                        final name = businessInfo['business_name'] ?? profile['email'] ?? 'Unknown';
                        final email = profile['email'] ?? '';
                        final isCurrentUser = member['user_id'] == _currentUserId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRoleColor(role).withOpacity(0.2),
                              child: Icon(
                                _getRoleIcon(role),
                                color: _getRoleColor(role),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isCurrentUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(fontSize: 10, color: Colors.blue),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleDisplayName(role),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getRoleColor(role),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: _canManagePeople && role != 'owner' && !isCurrentUser
                                ? IconButton(
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showMemberOptions(member),
                                  )
                                : null,
                            onTap: _canManagePeople && role != 'owner' && !isCurrentUser
                                ? () => _showMemberOptions(member)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: _canManagePeople
          ? FloatingActionButton.extended(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
