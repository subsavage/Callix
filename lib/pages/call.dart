import 'package:callix/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

class CallPage extends StatefulWidget {
  final String channelName;
  final ClientRoleType role;

  const CallPage({Key? key, required this.channelName, required this.role})
    : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final List<int> _users = [];
  final List<String> _infoStrings = [];
  bool muted = false;
  bool viewPanel = false;
  late final RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (appid.isEmpty) {
      setState(() => _infoStrings.add("Please provide APP_ID"));
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appid));

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );
    await _engine.setClientRole(role: widget.role);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess:
            (_, __) => setState(() => _infoStrings.add("Joined channel")),
        onUserJoined: (_, remoteUid, __) {
          setState(() {
            _infoStrings.add("User $remoteUid joined");
            _users.add(remoteUid);
          });
        },
        onUserOffline: (_, remoteUid, __) {
          setState(() {
            _infoStrings.add("User $remoteUid left");
            _users.remove(remoteUid);
          });
        },
      ),
    );

    await _engine.setVideoEncoderConfiguration(
      VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1920, height: 1080),
        frameRate: 30,
        orientationMode: OrientationMode.orientationModeAdaptive,
      ),
    );

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.role,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: widget.role == ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack:
            widget.role == ClientRoleType.clientRoleBroadcaster,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  Widget _viewRows() {
    final views = <Widget>[];

    if (_users.isEmpty && widget.role != ClientRoleType.clientRoleBroadcaster) {
      return const Center(
        child: Text(
          "Waiting for broadcaster to join…",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      views.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }

    for (var uid in _users) {
      views.add(
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: widget.channelName),
          ),
        ),
      );
    }

    return Column(children: views.map((w) => Expanded(child: w)).toList());
  }

  Widget _toolbar() {
    if (widget.role == ClientRoleType.clientRoleAudience)
      return const SizedBox();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RawMaterialButton(
              onPressed: () {
                setState(() {
                  muted = !muted;
                });
                _engine.muteLocalAudioStream(muted);
              },
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: muted ? Colors.blueAccent : Colors.white,
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
                size: 25.0,
              ),
            ),
            RawMaterialButton(
              onPressed: () => Navigator.pop(context),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(12.0),
              child: Icon(Icons.call_end, color: Colors.white, size: 45.0),
            ),
            RawMaterialButton(
              onPressed: () {
                _engine.switchCamera();
              },
              elevation: 2.0,
              fillColor: Colors.white,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPanel() {
    return Visibility(
      visible: viewPanel,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.black54,
          height: 120,
          child: ListView(
            children:
                _infoStrings
                    .map(
                      (s) =>
                          Text(s, style: const TextStyle(color: Colors.white)),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Callix"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => setState(() => viewPanel = !viewPanel),
          ),
        ],
      ),
      body: Stack(children: [_viewRows(), _infoPanel(), _toolbar()]),
    );
  }
}
