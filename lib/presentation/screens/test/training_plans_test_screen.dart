import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/training_plan.dart';
import '../data/models/training_session.dart';
import '../data/providers/training_plan_provider.dart';
import '../data/repositories/training_repository.dart';

/// A simple test widget to verify the training plans implementation
class TrainingPlansTestScreen extends StatelessWidget {
  const TrainingPlansTestScreen({Key? key}) : super(key: key);

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
        title: 'Training Plans Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TrainingPlansTestHome(),
      ),
    );
  }
}

class TrainingPlansTestHome extends StatefulWidget {
  const TrainingPlansTestHome({Key? key}) : super(key: key);

  @override
  State<TrainingPlansTestHome> createState() => _TrainingPlansTestHomeState();
}

class _TrainingPlansTestHomeState extends State<TrainingPlansTestHome> {
  @override
  void initState() {
    super.initState();
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrainingPlanProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TrainingPlanProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans Test'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('Error: ${provider.error}'))
              : _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, TrainingPlanProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Selected plan info
        if (provider.selectedPlan != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Plan: ${provider.selectedPlan!.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Progress: ${(provider.completionPercentage * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  LinearProgressIndicator(
                    value: provider.completionPercentage,
                    minHeight: 10.0,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => provider.clearSelectedPlan(),
                    child: const Text('Clear Selected Plan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'Sessions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          ...provider.selectedPlan!.sessions.map((session) => _buildSessionCard(context, session, provider)),
        ],
        
        // Available plans
        if (provider.selectedPlan == null) ...[
          Text(
            'Available Plans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          ...provider.plans.map((plan) => _buildPlanCard(context, plan, provider)),
        ],
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, TrainingPlan plan, TrainingPlanProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(plan.name),
        subtitle: Text('${plan.difficulty} - ${plan.durationWeeks} weeks'),
        trailing: ElevatedButton(
          onPressed: () => provider.selectPlan(plan),
          child: const Text('Select'),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, TrainingSession session, TrainingPlanProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text('Week ${session.week}, Day ${session.day}'),
        subtitle: Text(session.description),
        trailing: Checkbox(
          value: session.completed,
          onChanged: (value) {
            if (value != null) {
              provider.completeSession(session, completed: value);
            }
          },
        ),
        onTap: () => _showSessionDetails(context, session),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, TrainingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Week ${session.week}, Day ${session.day}'),
              const SizedBox(height: 8.0),
              Text(session.description),
              const SizedBox(height: 8.0),
              Text('Duration: ${session.formattedDuration}'),
              const SizedBox(height: 16.0),
              Text('Intervals:'),
              const SizedBox(height: 8.0),
              ...session.intervals.map((interval) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '• ${interval.type}: ${interval.duration} min ${interval.intensity != null ? '(${interval.intensity})' : ''}',
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
