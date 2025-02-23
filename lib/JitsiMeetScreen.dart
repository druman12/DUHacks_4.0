import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiMeetScreen extends StatefulWidget {
  final String meetingUrl;

  JitsiMeetScreen({required this.meetingUrl});

  @override
  _JitsiMeetScreenState createState() => _JitsiMeetScreenState();
}

class _JitsiMeetScreenState extends State<JitsiMeetScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  Future<void> _joinMeeting() async {
    try {
      var options = JitsiMeetConferenceOptions(
        room: widget.meetingUrl,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Live Class Meeting",
          "prejoinPageEnabled": false, // Disable Prejoin Page
          "lobbyModeEnabled": false,  // Disable Lobby Mode
          "featureFlags": {
            "invite.enabled": false,
            "requireDisplayName": false,
            "meetingPasswordEnabled": false,
            "securityOptionsVisible": false,
            "conferenceTimerEnabled": false,
          },
        },
      );

      await _jitsiMeet.join(options);
    } catch (error) {
      print("Error joining meeting: $error");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Class")),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}