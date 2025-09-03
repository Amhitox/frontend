class User {
  final String? uid;
  final String? email;
  final String? subscriptionStatus;
  final DateTime? updatedAt;
  final String? lang;
  final String? lastName;
  final String? hashedPassword;
  final bool? premiumFeatureBGlobalAccess;
  final String? status;
  final DateTime? trialEndDate;
  final String? role;
  final String? subscriptionPeriod;
  final String? subscriptionTier;
  final bool? premiumFeatureAGlobalAccess;
  final String? freeAccessExpiryStatus;
  final String? firstName;
  final String? id;
  final String? workEmail;
  final DateTime? createdAt;

  User({
    this.uid,
    this.email,
    this.subscriptionStatus,
    this.updatedAt,
    this.lang,
    this.lastName,
    this.hashedPassword,
    this.premiumFeatureBGlobalAccess,
    this.status,
    this.trialEndDate,
    this.role,
    this.subscriptionPeriod,
    this.subscriptionTier,
    this.premiumFeatureAGlobalAccess,
    this.freeAccessExpiryStatus,
    this.firstName,
    this.id,
    this.workEmail,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String?,
      email: json['email'] as String?,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      updatedAt: _parseDateTime(json['updatedAt']),
      lang: json['lang'] as String?,
      lastName: json['lastName'] as String?,
      hashedPassword: json['hashedPassword'] as String?,
      premiumFeatureBGlobalAccess: json['premiumFeatureBGlobalAccess'] as bool?,
      status: json['status'] as String?,
      trialEndDate: _parseDateTime(json['trialEndDate']),
      role: json['role'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
      premiumFeatureAGlobalAccess: json['premiumFeatureAGlobalAccess'] as bool?,
      freeAccessExpiryStatus: json['freeAccessExpiryStatus'] as String?,
      firstName: json['firstName'] as String?,
      id: json['id'] as String?,
      workEmail: json['workEmail'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  // Helper method to parse different date formats
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      // Handle Firestore timestamp format
      if (dateValue is Map<String, dynamic> &&
          dateValue.containsKey('type') &&
          dateValue['type'] == 'firestore/timestamp/1.0') {
        final seconds = dateValue['seconds'] as int?;
        final nanoseconds = dateValue['nanoseconds'] as int?;

        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
          );
        }
      }

      // Handle string dates like "8/22/2025, 10:56:55 AM"
      if (dateValue is String) {
        // Try parsing the custom format first
        try {
          return _parseCustomDateFormat(dateValue);
        } catch (e) {
          // Fallback to ISO format parsing
          return DateTime.tryParse(dateValue);
        }
      }

      // Handle DateTime objects
      if (dateValue is DateTime) {
        return dateValue;
      }

      // Handle milliseconds since epoch
      if (dateValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      }
    } catch (e) {
      print('Error parsing date: $dateValue, Error: $e');
    }

    return null;
  }

  // Parse custom date format like "8/22/2025, 10:56:55 AM"
  static DateTime? _parseCustomDateFormat(String dateString) {
    try {
      // Remove any extra whitespace
      dateString = dateString.trim();

      // Split date and time parts
      final parts = dateString.split(', ');
      if (parts.length != 2) return null;

      final datePart = parts[0]; // "8/22/2025"
      final timePart = parts[1]; // "10:56:55 AM"

      // Parse date part
      final dateParts = datePart.split('/');
      if (dateParts.length != 3) return null;

      final month = int.parse(dateParts[0]);
      final day = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      // Parse time part
      final timeAndAmPm = timePart.split(' ');
      if (timeAndAmPm.length != 2) return null;

      final timeOnly = timeAndAmPm[0]; // "10:56:55"
      final amPm = timeAndAmPm[1]; // "AM"

      final timeParts = timeOnly.split(':');
      if (timeParts.length != 3) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      // Convert to 24-hour format
      if (amPm.toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      print('Error parsing custom date format: $dateString, Error: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid ?? '',
      'email': email ?? '',
      'subscriptionStatus': subscriptionStatus ?? '',
      'updatedAt': updatedAt?.toIso8601String(),
      'lang': lang ?? '',
      'lastName': lastName ?? '',
      'hashedPassword': hashedPassword ?? '',
      'premiumFeatureBGlobalAccess': premiumFeatureBGlobalAccess ?? '',
      'status': status ?? '',
      'trialEndDate': trialEndDate?.toIso8601String(),
      'role': role ?? '',
      'subscriptionPeriod': subscriptionPeriod ?? '',
      'subscriptionTier': subscriptionTier ?? '',
      'premiumFeatureAGlobalAccess': premiumFeatureAGlobalAccess ?? '',
      'freeAccessExpiryStatus': freeAccessExpiryStatus ?? '',
      'firstName': firstName ?? '',
      'id': id ?? '',
      'workEmail': workEmail ?? '',
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
