import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Usuário logado no momento (null se não estiver logado)
  User? get currentUser => _auth.currentUser;

  // Stream que escuta mudanças de autenticação em tempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── LOGIN ─────────────────────────────────────────────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── CADASTRO ──────────────────────────────────────────────
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // 1. Cria o usuário no Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // 2. Atualiza o displayName no Auth
    await credential.user!.updateDisplayName(name);

    // 3. Salva dados extras no Firestore (telefone, data de cadastro etc.)
    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email.trim(),
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(credential.user!.uid).set(user.toMap());

    return user;
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── BUSCAR PERFIL DO FIRESTORE ────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
