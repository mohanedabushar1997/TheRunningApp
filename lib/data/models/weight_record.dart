import 'package:equatable/equatable.dart';

class WeightRecord extends Equatable {
   final String? id; // Optional: Use if DB assigns unique ID
   final DateTime date;
   final double weightKg; // Always store in kg

   const WeightRecord({
      this.id,
      required this.date,
      required this.weightKg,
   });

   @override
   List<Object?> get props => [id, date, weightKg];

   // TODO: Add toMap/fromMap for DB persistence if needed
   Map<String, dynamic> toMap() {
      return { 'id': id, 'date': date.toIso8601String(), 'weightKg': weightKg, };
   }

   factory WeightRecord.fromMap(Map<String, dynamic> map) {
      return WeightRecord(
         id: map['id'] as String?,
         date: DateTime.parse(map['date'] as String),
         weightKg: (map['weightKg'] as num).toDouble(),
      );
   }

   WeightRecord copyWith({ String? id, DateTime? date, double? weightKg }) {
      return WeightRecord( id: id ?? this.id, date: date ?? this.date, weightKg: weightKg ?? this.weightKg, );
   }
}