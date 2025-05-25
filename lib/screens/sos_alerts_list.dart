import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cards/sos_alert_card.dart';
import '../services/sos_history_scheduler.dart';

class SOSAlertScreen extends StatefulWidget {
  @override
  _SOSAlertScreenState createState() => _SOSAlertScreenState();
}

class _SOSAlertScreenState extends State<SOSAlertScreen> {
  List<Map<String, dynamic>> sosAlerts = [];
  final SOSHistoryScheduler _sosScheduler = SOSHistoryScheduler();
  String lastUpdatedTime = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchCachedSOSHistory();
    _fetchLastUpdatedTime();
  }

  Future<void> _fetchLastUpdatedTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? timestamp = prefs.getString('lastSOSUpdateTime');

    if (timestamp != null) {
      DateTime lastUpdated = DateTime.parse(timestamp);
      String formattedDate =
          DateFormat('yyyy-MM-dd at h:mm a').format(lastUpdated);

      setState(() {
        lastUpdatedTime = 'Last updated on $formattedDate';
      });
    } else {
      setState(() {
        lastUpdatedTime = 'No data available';
      });
    }
  }

  Future<void> _fetchCachedSOSHistory() async {
    List<Map<String, dynamic>> cachedAlerts =
        await _sosScheduler.getCachedSOSHistory();
    setState(() {
      sosAlerts = cachedAlerts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151d67),
      appBar: AppBar(
        title: const Text('SOS Alerts'),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        backgroundColor: const Color(0xFF151d67),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _sosScheduler.fetchAndCacheSOSHistoryPublic();
                await _fetchCachedSOSHistory();
                await _fetchLastUpdatedTime();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 130),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151d67),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lastUpdatedTime,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: sosAlerts.isEmpty
                  ? const Center(
                      child: Text(
                        "No SOS alerts available.",
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sosAlerts.length,
                      itemBuilder: (context, index) {
                        var alert = sosAlerts[index];
                        return SOSAlertCard(alert: alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
