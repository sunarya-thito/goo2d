import 'dart:ui' as ui;
import 'package:goo2d/goo2d.dart';
export 'sprite_mesh.dart';
export 'sprite_pivot.dart';
export 'sprite_fit.dart';

class GameSprite {
  final GameTexture texture;
  final ui.Rect? _rect;
  final SpritePivot pivot;
  final double pixelsPerUnit;
  final SpriteMesh mesh;

  const GameSprite({
    required this.texture,
    ui.Rect? rect,
    this.pivot = NormalizedPivot.center,
    this.pixelsPerUnit = 100.0,
    this.mesh = const SimpleMesh(),
  }) : _rect = rect;

  // Unity-parity properties
  GameTexture get textureAsset => texture;
  ui.Rect get rect =>
      _rect ??
      ui.Rect.fromLTWH(
        0,
        0,
        texture.width.toDouble(),
        texture.height.toDouble(),
      );
  ui.Rect get textureRect => rect;
  ui.Size get size => rect.size;
  ui.Offset get pivotOffset => pivot.compute(rect.size);

  /// Returns the bounds in world space units.
  ui.Rect get bounds {
    final p = pivotOffset;
    final r = rect;
    return ui.Rect.fromLTWH(
      -p.dx / pixelsPerUnit,
      -p.dy / pixelsPerUnit,
      r.width / pixelsPerUnit,
      r.height / pixelsPerUnit,
    );
  }
}

class SpriteRenderer extends Behavior with Renderable {
  GameSprite? sprite;
  ui.Color color = const ui.Color(0xFFFFFFFF);
  bool flipX = false;
  bool flipY = false;
  ui.FilterQuality filterQuality = ui.FilterQuality.low;

  ui.BlendMode blendMode = ui.BlendMode.modulate;

  /// Temporary back-compat field. Should be removed once users migrate.
  set texture(GameTexture? tex) {
    if (tex != null) {
      sprite = GameSprite(texture: tex);
    } else {
      sprite = null;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final sprite = this.sprite;
    if (sprite == null) return;

    if (!sprite.texture.isLoaded) return;

    final paint = ui.Paint()
      ..colorFilter = ui.ColorFilter.mode(color, blendMode)
      ..filterQuality = filterQuality;

    final p = sprite.pivotOffset;
    final r = sprite.rect;

    canvas.save();

    // Scale from pixels to world units.
    // We don't flip Y here because the Camera already handles the world-to-screen flip.
    final scale = 1.0 / sprite.pixelsPerUnit;
    canvas.scale(scale, scale);

    // Position such that the pivot is at (0,0) in world space
    canvas.translate(-p.dx, -p.dy);



    if (flipX || flipY) {
      canvas.scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
    }

    sprite.mesh.render(canvas, sprite, r.size, paint);

    canvas.restore();
  }
}

typedef TileCoord = (int x, int y);

class SheetEntry<T> {
  final T key;
  final ui.Rect rect;

  const SheetEntry({required this.key, required this.rect});
}

abstract class SpriteSheet<K> {
  final GameTexture texture;

  const SpriteSheet({required this.texture});

  GameSprite getTileAt(K key);

  GameSprite operator [](K key) => getTileAt(key);

  const factory SpriteSheet.tagged({
    required GameTexture texture,
    required List<SheetEntry<K>> entries,
    SpritePivot pivot,
    double pixelsPerUnit,
    SpriteMesh mesh,
  }) = TaggedSpriteSheet<K>;

  static GridSpriteSheet grid({
    required GameTexture texture,
    required int rows,
    required int columns,
    ui.Offset offset = ui.Offset.zero,
    ui.Offset spacing = ui.Offset.zero,
    ui.Size? spriteSize,
    SpritePivot pivot = NormalizedPivot.center,
    double ppu = 100.0,
    SpriteMesh mesh = const SimpleMesh(),
  }) {
    return GridSpriteSheet(
      texture: texture,
      rows: rows,
      columns: columns,
      offset: offset,
      spacing: spacing,
      spriteSize: spriteSize,
      pivot: pivot,
      pixelsPerUnit: ppu,
      mesh: mesh,
    );
  }

  /// Splits a texture into a list of sprites.
  static List<GameSprite> split(
    GameTexture texture, {
    required int rows,
    required int columns,
    ui.Offset offset = ui.Offset.zero,
    ui.Size? spriteSize,
    SpritePivot pivot = NormalizedPivot.center,
    double ppu = 100.0,
    SpriteMesh mesh = const SimpleMesh(),
  }) {
    final List<GameSprite> sprites = [];
    final double width =
        spriteSize?.width ?? (texture.width - offset.dx) / columns;
    final double height =
        spriteSize?.height ?? (texture.height - offset.dy) / rows;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        sprites.add(
          GameSprite(
            texture: texture,
            rect: ui.Rect.fromLTWH(
              offset.dx + x * width,
              offset.dy + y * height,
              width,
              height,
            ),
            pivot: pivot,
            pixelsPerUnit: ppu,
            mesh: mesh,
          ),
        );
      }
    }
    return sprites;
  }
}

class TaggedSpriteSheet<T> extends SpriteSheet<T> {
  final List<SheetEntry<T>> entries;
  final SpritePivot pivot;
  final double pixelsPerUnit;
  final SpriteMesh mesh;

  const TaggedSpriteSheet({
    required super.texture,
    required this.entries,
    this.pivot = NormalizedPivot.center,
    this.pixelsPerUnit = 100.0,
    this.mesh = const SimpleMesh(),
  });

  @override
  GameSprite getTileAt(T key) {
    for (var entry in entries) {
      if (entry.key == key) {
        return GameSprite(
          texture: texture,
          rect: entry.rect,
          pivot: pivot,
          pixelsPerUnit: pixelsPerUnit,
          mesh: mesh,
        );
      }
    }
    throw ArgumentError('Sprite with tag "$key" not found in sheet');
  }
}

class GridSpriteSheet extends SpriteSheet<TileCoord> {
  final int rows;
  final int columns;
  final ui.Offset offset;
  final ui.Offset spacing;
  final ui.Size? spriteSize;
  final SpritePivot pivot;
  final double pixelsPerUnit;
  final SpriteMesh mesh;

  const GridSpriteSheet({
    required super.texture,
    required this.rows,
    required this.columns,
    this.offset = ui.Offset.zero,
    this.spacing = ui.Offset.zero,
    this.spriteSize,
    this.pivot = NormalizedPivot.center,
    this.pixelsPerUnit = 100.0,
    this.mesh = const SimpleMesh(),
  });

  @override
  GameSprite getTileAt(TileCoord key) {
    final (int keyX, int keyY) = key;
    if (keyX < 0 || keyX >= columns || keyY < 0 || keyY >= rows) {
      throw ArgumentError(
        'Coordinate $keyX, $keyY is out of bounds for sheet $columns x $rows',
      );
    }

    final double width =
        spriteSize?.width ??
        (texture.width - offset.dx - (columns - 1) * spacing.dx) / columns;
    final double height =
        spriteSize?.height ??
        (texture.height - offset.dy - (rows - 1) * spacing.dy) / rows;

    return GameSprite(
      texture: texture,
      rect: ui.Rect.fromLTWH(
        offset.dx + keyX * (width + spacing.dx),
        offset.dy + keyY * (height + spacing.dy),
        width,
        height,
      ),
      pivot: pivot,
      pixelsPerUnit: pixelsPerUnit,
      mesh: mesh,
    );
  }
}
