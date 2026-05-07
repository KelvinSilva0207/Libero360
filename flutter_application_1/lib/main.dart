import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Librería de Google
import 'database_service.dart'; // Tu "cerebro" de BD
import 'models/atleta_model.dart'; // Tus moldes
import 'models/representante_model.dart';

void main() async {
  // 1. Esto es obligatorio para que Flutter no falle al arrancar
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Encendemos Firebase
  await Firebase.initializeApp();

  runApp(const Libero360());
}

class Libero360 extends StatelessWidget {
  const Libero360({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Libero 360 - San Felipe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Libero 360")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Probar Registro en la Nube"),
          onPressed: () async {
            // AQUÍ HACEMOS LA PRUEBA REAL
            DatabaseService service = DatabaseService();
            
            Representante repPrueba = Representante(
              id: "V-12345678", 
              nombres: "Pedro", 
              apellidos: "Paramo", 
              sexo: "M", 
              celular: "0412-0000000", 
              tlfHabitacion: "0254-0000000", 
              email: "pedro@test.com"
            );

            Atleta atletaPrueba = Atleta(
              id: "V-30999999",
              nombreCompleto: "Diego Jugador",
              fechaNacimiento: DateTime(2010, 10, 10),
              sexo: "M",
              numeroCamisa: 7,
              posicion: "Punta",
              idRepresentante: "V-12345678",
              idInstitucion: 1
            );

            await service.registrarAtletaConRepresentante(atletaPrueba, repPrueba);
            
            // Si todo sale bien, saldrá este mensaje en tu pantalla
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Datos mandados a Firebase!")),
            );
          },
        ),
      ),
    );
  }
}