import 'dart:ui' as ui;
import 'package:goo2d/goo2d.dart';
export 'sprite_mesh.dart';
export 'sprite_pivot.dart';
export 'sprite_fit.dart';

/// Represents a visual region within a [GameTexture].
/// 
/// A [GameSprite] defines a specific rectangle of a texture to be 
/// rendered, along with metadata like the [pivot] point and 
/// [pixelsPerUnit] scaling. This allows for efficient use of texture 
/// atlases and consistent world-space sizing.
/// 
/// ```dart
/// final sprite = GameSprite(
///   texture: myTexture,
///   rect: Rect.fromLTWH(0, 0, 32, 32),
///   pivot: NormalizedPivot.center,
///   pixelsPerUnit: 16.0,
/// );
/// ```
class GameSprite {
  /// The source texture asset containing this sprite.
  /// 
  /// Provides the raw pixel data for rendering.
  final GameTexture texture;
  
  /// The source rectangle within the texture.
  /// 
  /// Defines the pixel boundaries of the sprite within its parent texture.
  final ui.Rect? _rect;

  /// The point within the sprite that corresponds to its [ObjectTransform.position].
  /// 
  /// Defines the origin for rotation and scaling.
  final SpritePivot pivot;

  /// The number of pixels that correspond to one unit in the game world.
  /// 
  /// For example, if PPU is 100.0, a 100x100 pixel sprite will be 
  /// exactly 1.0x1.0 units in world space.
  final double pixelsPerUnit;

  /// The mesh used to render this sprite.
  /// 
  /// Determines the geometry and UV mapping. Defaults to a standard quad.
  final SpriteMesh mesh;

  /// Creates a [GameSprite].
  /// 
  /// Initializes the sprite with a texture and optional region/pivot/ppu.
  ///
  /// * [texture]: The source image asset.
  /// * [rect]: The pixel region within the texture.
  /// * [pivot]: The anchor point for transformations.
  /// * [pixelsPerUnit]: Scaling factor for world units.
  /// * [mesh]: Geometric strategy for rendering.
  const GameSprite({
    required this.texture,
    ui.Rect? rect,
    this.pivot = NormalizedPivot.center,
    this.pixelsPerUnit = 100.0,
    this.mesh = const SimpleMesh(),
  }) : _rect = rect;

  /// The underlying [GameTexture] asset.
  /// 
  /// Direct accessor for the source texture.
  GameTexture get textureAsset => texture;

  /// The source rectangle within the texture (in pixels).
  /// 
  /// If no rect is specified, the entire texture dimensions are used.
  ui.Rect get rect =>
      _rect ??
      ui.Rect.fromLTWH(
        0,
        0,
        texture.width.toDouble(),
        texture.height.toDouble(),
      );

  /// Alias for [rect] to maintain Unity-parity.
  /// 
  /// Returns the same source region as [rect].
  ui.Rect get textureRect => rect;

  /// The logical pixel dimensions of the sprite.
  /// 
  /// Returns the size of the [rect].
  ui.Size get size => rect.size;

  /// The calculated pixel offset of the pivot point relative to the top-left.
  /// 
  /// Computed based on the [pivot] strategy and the current [size].
  ui.Offset get pivotOffset => pivot.compute(rect.size);

  /// The world-space bounds of the sprite relative to its pivot.
  /// 
  /// These bounds are used for collision detection and culling.
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

/// A component that renders a [GameSprite] in the game world.
/// 
/// [SpriteRenderer] handles the transformation from pixel space to 
/// world space and applies coloring, flipping, and blending effects. 
/// It must be attached to a [GameObject] with an [ObjectTransform].
/// 
/// ```dart
/// gameObject.addComponent(SpriteRenderer())
///   ..sprite = mySprite
///   ..color = Colors.red
///   ..flipX = true;
/// ```
class SpriteRenderer extends Behavior with Renderable {
  /// The sprite to be rendered.
  /// 
  /// Defines the source image and region for the renderer.
  GameSprite? sprite;

  /// The tint color applied to the sprite. 
  /// 
  /// Defaults to opaque white. The [blendMode] determines how this color is 
  /// mixed with the texture pixels.
  ui.Color color = const ui.Color(0xFFFFFFFF);

  /// Whether to horizontally flip the sprite.
  /// 
  /// If true, the texture will be mirrored across the vertical axis.
  bool flipX = false;

  /// Whether to vertically flip the sprite.
  /// 
  /// If true, the texture will be mirrored across the horizontal axis.
  bool flipY = false;

  /// The quality of filtering when scaling the sprite.
  /// 
  /// Affects the visual smoothness of scaled textures.
  ui.FilterQuality filterQuality = ui.FilterQuality.low;

  /// The blend mode used when applying the [color] tint.
  /// 
  /// Determines the mathematical operation for combining the tint and texture.
  ui.BlendMode blendMode = ui.BlendMode.modulate;

  /// Legacy setter for [GameTexture].
  /// 
  /// Automatically wraps the texture in a [GameSprite] with default settings.
  /// 
  /// * [tex]: The texture to assign.
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

/// A coordinate type used for grid-based sprite lookups.
/// 
/// Consists of an (x, y) integer pair representing the tile position.
typedef TileCoord = (int x, int y);

/// Represents a single entry in a [TaggedSpriteSheet].
/// 
/// ```dart
/// const entry = SheetEntry(key: 'player', rect: Rect.fromLTWH(0, 0, 32, 32));
/// ```
class SheetEntry<T> {
  /// The unique identifier for this sprite.
  /// 
  /// Usually a [String] tag or an [Enum] value.
  final T key;

  /// The pixel rectangle within the sheet.
  /// 
  /// Defines the source area to be extracted for this entry.
  final ui.Rect rect;

  /// Creates a [SheetEntry].
  /// 
  /// Initializes the entry with a key and source area.
  ///
  /// * [key]: The identifier for this sprite.
  /// * [rect]: The pixel boundaries within the texture.
  const SheetEntry({required this.key, required this.rect});
}

/// A collection of sprites packed into a single texture.
/// 
/// Sprite sheets are an optimization that reduces draw calls and 
/// simplifies asset management. [SpriteSheet] provides factory 
/// methods for grid-based (uniform) and tagged (non-uniform) layouts.
/// 
/// ```dart
/// final sheet = SpriteSheet.grid(texture: tex, rows: 2, columns: 2);
/// ```
abstract class SpriteSheet<K> {
  /// The source texture for the sheet.
  /// 
  /// Contains all individual sprites packed into one image asset.
  final GameTexture texture;

  /// Internal constructor for [SpriteSheet].
  /// 
  /// Initializes the base sheet with a texture.
  ///
  /// * [texture]: The source image for all sprites.
  const SpriteSheet({required this.texture});

  /// Retrieves a [GameSprite] from the sheet.
  /// 
  /// Performs a lookup based on the key [K] and returns a configured sprite.
  /// 
  /// * [key]: The identifier for the desired sprite.
  GameSprite getTileAt(K key);

  /// Convenience operator for [getTileAt].
  /// 
  /// Allows for `sheet[key]` syntax to retrieve sprites.
  /// 
  /// * [key]: The identifier for the desired sprite.
  GameSprite operator [](K key) => getTileAt(key);

  /// Creates a sheet where sprites are identified by unique tags.
  /// 
  /// Allows for non-uniform packing of sprites.
  ///
  /// * [texture]: The source texture.
  /// * [entries]: The list of tagged rectangles.
  /// * [pivot]: The default pivot for generated sprites.
  /// * [pixelsPerUnit]: The default scaling for generated sprites.
  /// * [mesh]: The default mesh for generated sprites.
  const factory SpriteSheet.tagged({
    required GameTexture texture,
    required List<SheetEntry<K>> entries,
    SpritePivot pivot,
    double pixelsPerUnit,
    SpriteMesh mesh,
  }) = TaggedSpriteSheet<K>;

  /// Creates a sheet where sprites are arranged in a uniform grid.
  /// 
  /// Automates the slicing of a texture into equal-sized tiles.
  ///
  /// * [texture]: The source texture.
  /// * [rows]: Number of horizontal rows.
  /// * [columns]: Number of vertical columns.
  /// * [offset]: Initial pixel offset from the top-left.
  /// * [spacing]: Pixel gaps between tiles.
  /// * [spriteSize]: Explicit size of each sprite (optional).
  /// * [pivot]: The default pivot for generated sprites.
  /// * [ppu]: The default scaling for generated sprites.
  /// * [mesh]: The default mesh for generated sprites.
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

  /// Utility method to slice a texture into a flat list of sprites.
  /// 
  /// Returns all generated sprites as a simple [List].
  ///
  /// * [texture]: The source texture.
  /// * [rows]: Number of horizontal rows.
  /// * [columns]: Number of vertical columns.
  /// * [offset]: Initial pixel offset from the top-left.
  /// * [spriteSize]: Explicit size of each sprite (optional).
  /// * [pivot]: The default pivot for generated sprites.
  /// * [ppu]: The default scaling for generated sprites.
  /// * [mesh]: The default mesh for generated sprites.
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

/// A [SpriteSheet] implementation that uses explicit keys for lookups.
/// 
/// ```dart
/// final sheet = TaggedSpriteSheet(texture: tex, entries: [entry]);
/// ```
class TaggedSpriteSheet<T> extends SpriteSheet<T> {
  /// The metadata for all sprites in this sheet.
  /// 
  /// A list of entries mapping keys to rectangles.
  final List<SheetEntry<T>> entries;

  /// The default pivot for all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this sheet.
  final SpritePivot pivot;

  /// The default scaling factor for all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this sheet.
  final double pixelsPerUnit;

  /// The mesh used by all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this sheet.
  final SpriteMesh mesh;

  /// Creates a [TaggedSpriteSheet].
  /// 
  /// Initializes the sheet with a set of tagged entries.
  ///
  /// * [texture]: The source texture.
  /// * [entries]: The list of tagged rectangles.
  /// * [pivot]: The default pivot for all generated sprites.
  /// * [pixelsPerUnit]: The default scaling for all generated sprites.
  /// * [mesh]: The default mesh for all generated sprites.
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

/// A [SpriteSheet] implementation that uses grid coordinates for lookups.
/// 
/// ```dart
/// final sheet = GridSpriteSheet(texture: tex, rows: 2, columns: 2);
/// ```
class GridSpriteSheet extends SpriteSheet<TileCoord> {
  /// The number of rows in the grid.
  /// 
  /// Determines the vertical segmentation of the texture.
  final int rows;

  /// The number of columns in the grid.
  /// 
  /// Determines the horizontal segmentation of the texture.
  final int columns;

  /// The initial padding from the top-left.
  /// 
  /// Defines where the grid starts within the source texture.
  final ui.Offset offset;

  /// The gaps between individual cells.
  /// 
  /// Pixel spacing added between each tile in the grid.
  final ui.Offset spacing;

  /// The explicit pixel size of each cell.
  /// 
  /// If provided, this overrides calculations based on texture dimensions.
  final ui.Size? spriteSize;

  /// The default pivot for all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this grid.
  final SpritePivot pivot;

  /// The default scaling factor for all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this grid.
  final double pixelsPerUnit;

  /// The mesh used by all generated sprites.
  /// 
  /// Applied to every sprite retrieved from this grid.
  final SpriteMesh mesh;

  /// Creates a [GridSpriteSheet].
  /// 
  /// Initializes the sheet with grid dimensions and padding.
  ///
  /// * [texture]: The source texture.
  /// * [rows]: The vertical cell count.
  /// * [columns]: The horizontal cell count.
  /// * [offset]: Padding from the top-left edge.
  /// * [spacing]: Gaps between cells.
  /// * [spriteSize]: Override for cell size.
  /// * [pivot]: Default pivot for generated sprites.
  /// * [pixelsPerUnit]: Default scaling for generated sprites.
  /// * [mesh]: Default mesh for generated sprites.
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
