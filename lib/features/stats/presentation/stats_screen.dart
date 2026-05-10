import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/ant_empty_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: const AntEmptyState(
        icon: PhosphorIconsBold.chartBar,
        title: 'No Study Data Yet',
        message:
            'Start studying to see your progress charts, mastery trends, and streak data here.',
      ),
    );
  }
}
