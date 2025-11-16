import 'package:flutter/material.dart';

class ConnectingToClassScreen extends StatelessWidget {
  const ConnectingToClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    }, icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '👩‍🏫 Ms. Ain - Form 5 Physics',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Video Placeholder with connecting text
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Color(0xFF1E2A38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Connecting to class...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const Spacer(),

            // Bottom control buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.mic_off, Colors.grey),
                  _controlButton(Icons.videocam_off, Colors.grey),
                  _controlButton(Icons.chat_bubble_outline, Colors.green),
                  _controlButton(Icons.screen_share, Colors.grey),
                  _controlButton(Icons.call_end, Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
