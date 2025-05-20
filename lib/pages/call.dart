import 'package:callix/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRoleType? role;
  const CallPage({Key? key, this.channelName, this.role}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoString = <String>[];
  bool muted = false;
  bool viewPanel = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initialise();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    super.dispose();
  }

  Future<void> initialise() async {
    if (appid.isEmpty) {
      setState(() {
        _infoString.add("Missing APP_ID");
        _infoString.add("Agora Engine is not starting");
      });
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appid));
    await _engine.enableVideo();
    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await _engine.setClientRole(role: widget.role!);

    _addAgoraEventHandlers();

    final configuration = VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 1920, height: 1080),
      frameRate: 30,
      orientationMode: OrientationMode.orientationModeAdaptive,
      degradationPreference: DegradationPreference.maintainFramerate,
    );
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
      token: token,
      channelId: widget.channelName!,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.role ?? ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void _addAgoraEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _infoString.add('Local user ${connection.localUid} joined');
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _infoString.add('Remote user $remoteUid joined');
            _users.add(remoteUid);
          });
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          setState(() {
            _infoString.add('Remote user $remoteUid left channel');
            _users.remove(remoteUid);
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          setState(() {
            _infoString.add('Local user left channel');
            _users.clear();
          });
        },
      ),
    );
  }

  Widget _viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRoleType.clientRoleBroadcaster) {
      list.add(
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      );
    }
    for (var uid in _users) {
      AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName!),
        ),
      );
    }

    final views = list;
    return Column(
      children: List.generate(
        views.length,
        (index) => Expanded(child: views[index]),
      ),
    );
  }

  Widget _toolBar() {
    if (widget.role == ClientRoleType.clientRoleAudience) {
      return const SizedBox();
    }
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
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
    );
  }

  Widget _panel() {
    return Visibility(
      visible: viewPanel,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 50),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: ListView.builder(
              reverse: true,
              itemCount: _infoString.length,
              itemBuilder: (BuildContext context, int index) {
                if (_infoString.isEmpty) {
                  return const Text("null");
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _infoString[index],
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Callix"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                viewPanel = !viewPanel;
              });
            },
            icon: Icon(Icons.info_outline),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(children: <Widget>[_viewRows(), _panel(), _toolBar()]),
      ),
    );
  }
}
