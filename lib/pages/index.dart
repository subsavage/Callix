import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validateError = false;
  ClientRoleType? _role = ClientRoleType.clientRoleBroadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _handleCameraAndMic(Permission permission) async {
      final status = await permission.request();
    }

    Future<void> onJoin() async {
      setState(() {
        _channelController.text.isEmpty
            ? _validateError = true
            : _validateError = false;
      });

      if (_channelController.text.isNotEmpty) {
        await _handleCameraAndMic(Permission.camera);
        await _handleCameraAndMic(Permission.microphone);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    CallPage(channelName: _channelController.text, role: _role),
          ),
        );
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(height: 40),
                Text(
                  "Callix",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Call Anyone, Anytime, Anywhere!!",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Image.network(
                  "https://cdni.iconscout.com/illustration/premium/thumb/video-call-illustration-download-in-svg-png-gif-file-formats--logo-conference-calling-chat-pack-network-communication-illustrations-3646089.png",
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _channelController,
                  decoration: InputDecoration(
                    errorText:
                        _validateError ? 'Channel name is mandatory' : null,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(width: 1),
                    ),
                    hintText: "Channel name",
                  ),
                ),
                RadioListTile(
                  value: ClientRoleType.clientRoleBroadcaster,
                  groupValue: _role,
                  onChanged: (ClientRoleType? value) {
                    setState(() {
                      _role = value;
                    });
                  },
                  title: const Text("Broadcaster"),
                ),
                RadioListTile(
                  value: ClientRoleType.clientRoleAudience,
                  groupValue: _role,
                  onChanged: (ClientRoleType? value) {
                    setState(() {
                      _role = value;
                    });
                  },
                  title: const Text("Audience"),
                ),
                ElevatedButton(
                  onPressed: onJoin,
                  child: const Text("Join"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
