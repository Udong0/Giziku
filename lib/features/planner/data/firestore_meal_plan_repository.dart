import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/meal_plan.dart';
import 'meal_plan_repository.dart';

class FirestoreMealPlanRepository implements MealPlanRepository {
  FirestoreMealPlanRepository(this._firestore);

  final FirebaseFirestore _firestore;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('meal_plans');

  @override
  Future<void> init() async {}

  @override
  Future<List<MealPlan>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];
    final snapshot = await _col.where('userId', isEqualTo: uid).get();
    return snapshot.docs
        .map((doc) => _fromFirestore(doc.data()))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  @override
  Future<MealPlan?> getById(String id) async {
    final uid = _userId;
    if (uid == null) return null;
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null || data['userId'] != uid) return null;
    return _fromFirestore(data);
  }

  @override
  Future<void> add(MealPlan plan) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(plan.id).set(_toFirestore(plan, uid));
  }

  @override
  Future<void> update(MealPlan plan) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(plan.id).set(_toFirestore(plan, uid));
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Map<String, dynamic> _toFirestore(MealPlan p, String uid) => {
        'userId': uid,
        'id': p.id,
        'foodItemId': p.foodItemId,
        'customName': p.customName,
        'scheduledAt': Timestamp.fromDate(p.scheduledAt),
        'mealType': p.mealType.name,
        'reminderEnabled': p.reminderEnabled,
        'notificationId': p.notificationId,
        'createdAt': Timestamp.fromDate(p.createdAt),
        'updatedAt': Timestamp.fromDate(p.updatedAt),
      };

  MealPlan _fromFirestore(Map<String, dynamic> data) => MealPlan(
        id: data['id'] as String,
        foodItemId: data['foodItemId'] as String?,
        customName: data['customName'] as String?,
        scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
        mealType: MealType.values.firstWhere(
          (m) => m.name == data['mealType'],
          orElse: () => MealType.lunch,
        ),
        reminderEnabled: data['reminderEnabled'] as bool? ?? true,
        notificationId: data['notificationId'] as int?,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
}
