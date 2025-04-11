import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id; // Represents Device ID now
  final String? name;
  // final String? email; // REMOVED (or make optional if user can set it locally)
  final double? weight; // Kilograms
  final double? height; // Centimeters
  final DateTime? birthDate;
  final bool useImperialUnits;

  const UserProfile({
    required this.id, // This is the device ID
    this.name,
    // this.email,
    this.weight,
    this.height,
    this.birthDate,
    this.useImperialUnits = false,
  });

  // Calculate age (example)
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age > 0 ? age : null; // Return null if age calculation is weird
  }

  @override
  List<Object?> get props => [
        id,
        name,
        // email,
        weight,
        height,
        birthDate,
        useImperialUnits,
      ];

  UserProfile copyWith({
    String? id,
    String? name,
    // String? email, // Removed
    double? weight,
    double? height,
    DateTime? birthDate,
    bool? useImperialUnits,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      // email: email ?? this.email, // Removed
      weight: weight ?? this.weight,
      height: height ?? this.height,
      birthDate: birthDate ?? this.birthDate,
      useImperialUnits: useImperialUnits ?? this.useImperialUnits,
    );
  }

  // fromMap is handled in DatabaseHelper to match column names there
}