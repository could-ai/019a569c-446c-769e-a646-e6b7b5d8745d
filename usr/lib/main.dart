import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location to SMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LocationReceiverPage(),
    );
  }
}

class LocationReceiverPage extends StatefulWidget {
  const LocationReceiverPage({super.key});

  @override
  State<LocationReceiverPage> createState() => _LocationReceiverPageState();
}

class _LocationReceiverPageState extends State<LocationReceiverPage> {
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedText;
  String? _extractedCoordinates;
  List<String> _receivedLinks = [];

  @override
  void initState() {
    super.initState();
    _initReceivingIntent();
  }

  void _initReceivingIntent() {
    // For sharing intent while app is closed
    ReceiveSharingIntent.instance.getInitialText().then((String? value) {
      if (value != null) {
        _processSharedContent(value);
      }
    });

    // For sharing intent while app is running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getTextStream().listen(
      (String value) {
        _processSharedContent(value);
      },
      onError: (err) {
        _showMessage('Error receiving shared content: $err');
      },
    );
  }

  void _processSharedContent(String content) {
    setState(() {
      _sharedText = content;
      _receivedLinks.insert(0, content);
      if (_receivedLinks.length > 10) {
        _receivedLinks = _receivedLinks.sublist(0, 10);
      }
    });

    // Extract coordinates from the shared content
    String? coordinates = _extractCoordinates(content);
    if (coordinates != null) {
      setState(() {
        _extractedCoordinates = coordinates;
      });
      _copyToClipboard(coordinates);
      _openSMSApp(coordinates);
    } else {
      _showMessage('No coordinates found in shared content');
    }
  }

  String? _extractCoordinates(String text) {
    // WhatsApp location sharing patterns:
    // 1. Google Maps URL: https://maps.google.com/?q=LAT,LON
    // 2. Direct format: LAT,LON
    // 3. geo: URI scheme: geo:LAT,LON

    // Pattern for Google Maps URL
    RegExp googleMapsPattern = RegExp(r'maps\.google\.com/\?q=(-?\d+\.\d+),(-?\d+\.\d+)');
    Match? match = googleMapsPattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }

    // Pattern for geo: URI
    RegExp geoPattern = RegExp(r'geo:(-?\d+\.\d+),(-?\d+\.\d+)');
    match = geoPattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }

    // Pattern for direct coordinates
    RegExp coordPattern = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    match = coordPattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)},${match.group(2)}';
    }

    return null;
  }

  Future<void> _copyToClipboard(String coordinates) async {
    try {
      await FlutterClipboard.copy(coordinates);
      _showMessage('Coordinates copied: $coordinates');
    } catch (e) {
      _showMessage('Failed to copy coordinates: $e');
    }
  }

  Future<void> _openSMSApp(String coordinates) async {
    try {
      // Create SMS URI with pre-filled message
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: '', // Leave empty to not specify a phone number
        queryParameters: {
          'body': 'Location coordinates: $coordinates\nhttps://maps.google.com/?q=$coordinates'
        },
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showMessage('Could not open SMS app');
      }
    } catch (e) {
      _showMessage('Error opening SMS app: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location to SMS'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to use:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('1', 'Open WhatsApp and find a location message'),
                    _buildInstructionStep('2', 'Tap and hold the location'),
                    _buildInstructionStep('3', 'Select "Share" or "Forward"'),
                    _buildInstructionStep('4', 'Choose this app from the share menu'),
                    _buildInstructionStep('5', 'Coordinates will be copied and SMS app will open'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_extractedCoordinates != null) ..[
              const Text(
                'Last Extracted Coordinates:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _extractedCoordinates!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(_extractedCoordinates!),
                      tooltip: 'Copy again',
                    ),
                    IconButton(
                      icon: const Icon(Icons.message),
                      onPressed: () => _openSMSApp(_extractedCoordinates!),
                      tooltip: 'Open SMS',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_receivedLinks.isNotEmpty) ..[
              const Text(
                'Recent Shared Content:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _receivedLinks.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          _receivedLinks[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
