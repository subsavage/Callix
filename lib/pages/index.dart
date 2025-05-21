import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({Key? key}) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final TextEditingController _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  Future<void> _handleCameraAndMic() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  void _onJoin() async {
    setState(() {
      _validateError = _channelController.text.isEmpty;
    });

    if (!_validateError) {
      await _handleCameraAndMic();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => CallPage(
                channelName: _channelController.text.trim(),
                role: _role,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              "Callix",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Call Anyone, Anytime, Anywhere!",
              style: TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
            Image.network(
              "https://cdni.iconscout.com/illustration/premium/thumb/video-call-illustration-download-in-svg-png-gif-file-formats--logo-conference-calling-chat-pack-network-communication-illustrations-3646089.png",
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                hintText: "Channel name",
                errorText: _validateError ? "Channel name is mandatory" : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<ClientRoleType>(
              title: const Text("Broadcaster"),
              value: ClientRoleType.clientRoleBroadcaster,
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            RadioListTile<ClientRoleType>(
              title: const Text("Audience"),
              value: ClientRoleType.clientRoleAudience,
              groupValue: _role,
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onJoin,

              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
}
