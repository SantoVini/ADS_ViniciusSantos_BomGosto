import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Importando a tela inicial

void main() async {
  // CRUCIAL: Garante que os canais nativos estão prontos para comunicação antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase Core com as opções geradas pela CLI
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bom Gosto Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: LoginScreen(), // Define a tela de login como a primeira tela
    );
  }
}
