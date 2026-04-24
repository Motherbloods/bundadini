import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/rule_model.dart';

class RuleRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<RuleModel>> fetchActiveRules() async {
    final snap =
        await _db.collection('rules').where('aktif', isEqualTo: true).get();
    return snap.docs
        .map((d) => RuleModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }
}
