import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:goo2d/goo2d.dart';
import 'package:meta/meta.dart';

class MockAsset extends GameAsset {
  final String name;
  bool loaded = false;
  int loadCount = 0;

  MockAsset(this.name);

  @override
  String get assetName => name;

  @override
  Future<void> load() async {
    loaded = true;
    loadCount++;
  }

  @override
  void unload() {
    loaded = false;
  }

  @override
  @protected
  Future<Uint8List> loadBytes() async => Uint8List(0);
}

enum TestAssets with AssetEnum {
  assetA,
  assetB;

  @override
  GameAsset register() => MockAsset(name);
  
  MockAsset get mock => asset as MockAsset;
}

void main() {
  setUp(() {
    AssetEnum.reset();
  });

  group('AssetEnum', () {
    test('should lazily register assets', () {
      // Accessing for the first time should register
      final assetA = TestAssets.assetA.mock;
      expect(assetA.name, equals('assetA'));
      expect(assetA.loadCount, equals(0));
      
      // Accessing again should return the same instance
      final assetA2 = TestAssets.assetA.mock;
      expect(assetA2, same(assetA));
    });

    test('should reset registries', () {
      final assetA = TestAssets.assetA.mock;
      AssetEnum.reset();
      final assetA2 = TestAssets.assetA.mock;
      expect(assetA2, isNot(same(assetA)));
    });
  });

  group('GameAsset', () {
    test('loadAll should load assets and report progress', () async {
      final assets = [TestAssets.assetA, TestAssets.assetB];
      final stream = GameAsset.loadAll(assets);
      
      final results = await stream.toList();
      
      expect(results.length, equals(2));
      expect(results[0].assetLoaded, equals(1));
      expect(results[0].assetCount, equals(2));
      expect(results[1].assetLoaded, equals(2));
      
      expect(TestAssets.assetA.mock.loaded, isTrue);
      expect(TestAssets.assetB.mock.loaded, isTrue);
    });
  });
}
