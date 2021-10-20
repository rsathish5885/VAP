import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class VapView extends StatelessWidget {
  final int scaleType;
  final int? fps;
  final int? playLoop;
  final int contentMode;
  final ValueChanged<VapViewController>? onVapViewCreated;

  const VapView({
    Key? key,
    this.scaleType = 1,
    this.fps,
    this.playLoop,
    this.contentMode = 1,
    this.onVapViewCreated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var creationParams = <String, dynamic>{
      'scaleType': scaleType,
      if (fps != null) 'fps': fps,
      if (playLoop != null) 'playLoop': playLoop,
      'contentMode': contentMode,
    };
    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: 'flutter_vap',
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final channel = MethodChannel('flutter_vap_view_${params.id}');
          onVapViewCreated?.call(VapViewController._(channel));
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'flutter_vap',
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'flutter_vap',
        onPlatformViewCreated: _onPlatformViewCreated,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return Container();
  }

  void _onPlatformViewCreated(int id) {
    if (onVapViewCreated == null) {
      return;
    }
    final channel = MethodChannel('flutter_vap_view_$id');
    onVapViewCreated?.call(VapViewController._(channel));
  }
}

class VapViewController {
  final MethodChannel _channel;
  VapViewController._(this._channel);
  Future<Map<dynamic, dynamic>> playPath(String path) async {
    return await _channel.invokeMethod('playPath', {'path': path});
  }

  Future<Map<dynamic, dynamic>> playAsset(String asset) async {
    return await _channel.invokeMethod('playAsset', {'asset': asset});
  }

  void stop() {
    _channel.invokeMethod('stop');
  }
}
