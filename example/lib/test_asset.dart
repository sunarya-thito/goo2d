import 'dart:typed_data';

import 'package:goo2d/goo2d.dart';

enum MyAssets with AssetEnum, LocalGameSpriteEnum {
  player,
  coin
  ;

  @override
  String get path => 'asset/sprite/$name.png';
}
