import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/diary_entry.dart';
import 'diary_repository.dart';

class FirestoreDiaryRepository implements DiaryRepository {
  FirestoreDiaryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('diary_entries');

  @override
  Future<void> init() async {}

  @override
  Future<List<DiaryEntry>> getEntriesForDate(String dateKey) async {
    final uid = _userId;
    if (uid == null) return [];
    final snapshot = await _col
        .where('userId', isEqualTo: uid)
        .where('dateKey', isEqualTo: dateKey)
        .get();
    return snapshot.docs
        .map((doc) => _fromFirestore(doc.data()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> addEntry(DiaryEntry entry) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(entry.id).set(_toFirestore(entry, uid));
  }

  @override
  Future<void> updateEntry(DiaryEntry entry) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(entry.id).set(_toFirestore(entry, uid));
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
  }

  Map<String, dynamic> _toFirestore(DiaryEntry e, String uid) => {
        'userId': uid,
        'id': e.id,
        'foodItemId': e.foodItemId,
        'foodName': e.foodName,
        'dateKey': e.dateKey,
        'mealType': e.mealType.name,
        'servings': e.servings,
        'caloriesPerServing': e.caloriesPerServing,
        'proteinPerServing': e.proteinPerServing,
        'carbsPerServing': e.carbsPerServing,
        'fatPerServing': e.fatPerServing,
        'servingSizeG': e.servingSizeG,
        'createdAt': Timestamp.fromDate(e.createdAt),
        'updatedAt': Timestamp.fromDate(e.updatedAt),
      };

  DiaryEntry _fromFirestore(Map<String, dynamic> data) {
    final parts = (data['dateKey'] as String).split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return DiaryEntry(
      id: data['id'] as String,
      foodItemId: data['foodItemId'] as String?,
      foodName: data['foodName'] as String,
      date: date,
      mealType: MealType.values.firstWhere(
        (m) => m.name == data['mealType'],
        orElse: () => MealType.lunch,
      ),
      servings: (data['servings'] as num).toDouble(),
      caloriesPerServing: (data['caloriesPerServing'] as num).toDouble(),
      proteinPerServing: (data['proteinPerServing'] as num).toDouble(),
      carbsPerServing: (data['carbsPerServing'] as num).toDouble(),
      fatPerServing: (data['fatPerServing'] as num).toDouble(),
      servingSizeG: (data['servingSizeG'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}