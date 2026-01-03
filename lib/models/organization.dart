class Organization {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String plan;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.plan = 'free',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      plan: json['plan'] ?? 'free',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'plan': plan,
    };
  }
}

class OrganizationMember {
  final String id;
  final String organizationId;
  final String userId;
  final String? profileId;
  final String role; // 'owner', 'admin', 'member'
  final DateTime? invitedAt;
  final DateTime? joinedAt;

  OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.userId,
    this.profileId,
    required this.role,
    this.invitedAt,
    this.joinedAt,
  });

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      id: json['id'].toString(),
      organizationId: json['organization_id'].toString(),
      userId: json['user_id'].toString(),
      profileId: json['profile_id'],
      role: json['role'] ?? 'member',
      invitedAt: json['invited_at'] != null 
          ? DateTime.parse(json['invited_at']) 
          : null,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at']) 
          : null,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
}
