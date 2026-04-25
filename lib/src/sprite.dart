import 'dart:ui';

import 'package:flutter/widgets.dart' show BoxFit, Alignment, applyBoxFit, FittedSizes;
import 'package:goo2d/goo2d.dart';


class SpriteOffset {
  final double? dx;
  final double? dy;

  const SpriteOffset({this.dx, this.dy});
  SpriteOffset.fromOffset(Offset offset) : dx = offset.dx, dy = offset.dy;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SpriteOffset && other.dx == dx && other.dy == dy;
  }

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() {
    return 'SpriteOffset(dx: $dx, dy: $dy)';
  }
}

class SpriteSize {
  final double? width;
  final double? height;

  const SpriteSize({this.width, this.height});
  SpriteSize.fromSize(Size size) : width = size.width, height = size.height;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SpriteSize &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() {
    return 'SpriteSize(width: $width, height: $height)';
  }
}

class SpriteRect {
  final SpriteOffset? offset;
  final SpriteSize? size;

  const SpriteRect({this.offset, this.size});

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SpriteRect && other.offset == offset && other.size == size;
  }

  @override
  int get hashCode => Object.hash(offset, size);

  @override
  String toString() {
    return 'SpriteRect(offset: $offset, size: $size)';
  }
}

class SpriteRenderer extends Behavior with Renderable {
  GameSprite? sprite;
  SpriteRect? srcRect;
  SpriteRect? dstRect;
  BoxFit fit = BoxFit.cover;
  Alignment alignment = Alignment.center;

  @override
  void render(Canvas canvas) {
    final sprite = this.sprite;
    if (sprite == null) return;

    final Image image;
    try {
      image = sprite.image;
    } catch (_) {
      return; // Image not loaded yet
    }

    final srcRect = this.srcRect;
    final dstRect = this.dstRect;

    final srcR = Rect.fromLTWH(
      srcRect?.offset?.dx ?? 0,
      srcRect?.offset?.dy ?? 0,
      srcRect?.size?.width ?? image.width.toDouble(),
      srcRect?.size?.height ?? image.height.toDouble(),
    );

    final Size destinationSize = Size(
      dstRect?.size?.width ?? image.width.toDouble(),
      dstRect?.size?.height ?? image.height.toDouble(),
    );

    final FittedSizes sizes = applyBoxFit(fit, srcR.size, destinationSize);
    final Rect destinationRect = alignment.inscribe(
      sizes.destination,
      Rect.fromLTWH(
        dstRect?.offset?.dx ?? 0,
        dstRect?.offset?.dy ?? 0,
        destinationSize.width,
        destinationSize.height,
      ),
    );

    canvas.drawImageRect(image, srcR, destinationRect, Paint());
  }
}


