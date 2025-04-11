import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models/training_plan.dart';
import 'data/models/training_session.dart';
import 'data/providers/training_plan_provider.dart';
import 'data/repositories/training_repository.dart';
import 'presentation/screens/test/training_plans_test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TrainingRepository>(
          create: (_) => TrainingRepository(),
        ),
        ChangeNotifierProxyProvider<TrainingRepository, TrainingPlanProvider>(
          create: (context) => TrainingPlanProvider(
            repository: Provider.of<TrainingRepository>(context, listen: false),
          ),
          update: (context, repository, previous) => 
            previous ?? TrainingPlanProvider(repository: repository),
        ),
      ],
      child: MaterialApp(
        title: 'Running App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TrainingPlansTestHome(),
      ),
    );
  }
}
