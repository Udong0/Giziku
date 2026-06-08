import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item.dart';
import 'food_repository.dart';

class FirestoreFoodRepository implements FoodRepository {
  FirestoreFoodRepository(this._firestore);

  final FirebaseFirestore _firestore;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('food_items');

  @override
  Future<void> init() async {}

  @override
  Future<List<FoodItem>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];
    final snapshot = await _col.where('userId', isEqualTo: uid).get();
    return snapshot.docs
        .map((doc) => _fromFirestore(doc.data()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<FoodItem?> getById(String id) async {
    final uid = _userId;
    if (uid == null) return null;
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['userId'] != uid) return null;
    return _fromFirestore(data);
  }

  @override
  Future<void> add(FoodItem item) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(item.id).set(_toFirestore(item, uid));
  }

  @override
  Future<void> update(FoodItem item) async {
    final uid = _userId;
    if (uid == null) return;
    await _col.doc(item.id).set(_toFirestore(item, uid));
  }

  @override
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Map<String, dynamic> _toFirestore(FoodItem item, String uid) => {
        'userId': uid,
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'calories': item.calories,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
        'servingSize': item.servingSize,
        'imagePath': item.imagePath,
        'source': item.source.name,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': Timestamp.fromDate(item.updatedAt),
      };

  FoodItem _fromFirestore(Map<String, dynamic> data) => FoodItem(
        id: data['id'] as String,
        name: data['name'] as String,
        description: data['description'] as String?,
        calories: (data['calories'] as num).toDouble(),
        protein: (data['protein'] as num).toDouble(),
        carbs: (data['carbs'] as num).toDouble(),
        fat: (data['fat'] as num).toDouble(),
        servingSize: (data['servingSize'] as num).toDouble(),
        imagePath: data['imagePath'] as String?,
        source: FoodSource.values.firstWhere(
          (s) => s.name == data['source'],
          orElse: () => FoodSource.manual,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
}