import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';

import 'connector.dart';

export 'package:flutter_apns_only/flutter_apns_only.dart';

class ApnsPushConnector extends ApnsPushConnectorOnly implements PushConnector {
  @override
  void configure({onMessage, onLaunch, onResume, onBackgroundMessage}) {
    ApnsMessageHandler? mapHandler(MessageHandler? input) {
      if (input == null) {
        return null;
      }

      return (apnsMessage) {
        try {
          final data = apnsMessage.payload;

          if (data['notification'] == null) {
            data.addAll({
              'notification': <String, dynamic>{},
            });
          }

          if (data['notification']['title'] == null) {
            data['notification'].addAll({
              'title': data['aps']['alert']['title'],
            });
          }

          if (data['notification']['body'] == null) {
            data['notification'].addAll({
              'body': data['aps']['alert']['body'],
            });
          }

          return input(RemoteMessage.fromMap(data));
        } catch (e) {
          debugPrint('$e');
          rethrow;
        }
      };
    }

    configureApns(
      onMessage: mapHandler(onMessage),
      onLaunch: mapHandler(onLaunch),
      onResume: mapHandler(onResume),
      onBackgroundMessage: mapHandler(onBackgroundMessage),
    );
  }
}
