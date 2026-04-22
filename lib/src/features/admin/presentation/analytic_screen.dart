import 'package:flutter/material.dart';

class AnalyticScreen extends StatelessWidget {
  const AnalyticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Intelligence Reports", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildMetricsOverview(),
          const SizedBox(height: 32),
          const Text("Performance Distribution", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _buildChartPlaceholder(),
          const SizedBox(height: 32),
          _buildInsightCard(),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    return Row(
      children: [
        _metricItem("Growth", "+12.5%", Icons.arrow_upward_rounded, Colors.green),
        const SizedBox(width: 16),
        _metricItem("Retention", "94.2%", Icons.face_rounded, Colors.blue),
      ],
    );
  }

  Widget _metricItem(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 16),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: Colors.blue.shade400, size: 40),
            const SizedBox(height: 8),
            const Text("Rendering Live Engine...", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "System detected a 15% increase in student activity this week. Peak time is 09:00 AM.",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
            ),
          )
        ],
      ),
    );
  }
}