import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

// Função principal: ponto de entrada do app
void main() async {
  // Garante que os bindings do Flutter estão prontos antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase (precisa estar configurado no projeto Android/iOS)
  await Firebase.initializeApp();

  runApp(const RestauranteApp());
}

// Widget raiz do aplicativo
class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      // Tela inicial é a de login
      home: const LoginScreen(),
    );
  }
}
