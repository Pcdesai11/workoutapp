// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/mock_workout_plan.dart';
import 'router/app_router.dart';
import 'state/workout_state.dart';
import 'database/database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseAuth.instance.setLanguageCode("en");
  final database = await AppDatabase.buildDatabase();
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter(database: database);

    return ChangeNotifierProvider(
      create: (context) => WorkoutState(
        database: database,
        defaultPlan: mockWorkoutPlan,
      )..loadWorkouts()..loadPlans(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Workout Tracker',
        routerConfig: appRouter.router,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}