import 'dart:ui' as ui;
import 'package:goo2d/src/asset.dart';
import 'package:goo2d/src/sprite_pivot.dart';
import 'package:goo2d/src/sprite_mesh.dart';
import 'package:goo2d/src/component.dart';
import 'package:goo2d/src/render.dart';

/// A representation of a single visual entity within a texture.
///
/// [GameSprite] defines a rectangular region of a [GameTexture] to be rendered 
/// as a standalone image. It includes information about the sprite's pivot point, 
/// its resolution (pixels per unit), and the mesh used for drawing.
///
/// ```dart
/// enum TextureAsset with AssetEnum, TextureAssetEnum {
///   player('assets/player.png');
///   const TextureAsset(this.path);
///   final String path;
///   @override
///   AssetSource get source => AssetSource.local(path);
/// }
///
/// void example() {
///   final sprite = GameSprite(
///     texture: TextureAsset.player,
///     rect: const Rect.fromLTRB(0, 0, 32, 32),
///     pivot: NormalizedPivot.center,
///   );
/// }
/// ```
///
/// See also:
/// * [SpriteRenderer] for the component that draws this sprite.
/// * [GameTexture] for the source image data.
class GameSprite {
  /// The source texture containing the sprite's image data.
  ///
  /// This texture must be loaded before the sprite can be rendered. The sprite 
  /// represents a view into this texture, either the whole thing or a sub-rect.
  final GameTexture texture;

  final ui.Rect? _rect;

  /// The point within the sprite that acts as its origin for transformations.
  ///
  /// The pivot determines how the sprite is rotated and scaled. By default, 
  /// most sprites use the center as their pivot.
  final SpritePivot pivot;

  /// The number of pixels that correspond to one world unit.
  ///
  /// This value is used to scale the sprite when rendering in world space. 
  /// For example, a 100x100 pixel sprite with 100 pixels per unit will be 
  /// 1x1 world units in size.
  final double pixelsPerUnit;

  /// The mesh used to define the geometry of the sprite.
  ///
  /// By default, a [SimpleMesh] is used, which renders a simple quad. Complex 
  /// meshes can be used for effects like vertex deformation or sprite-sheet 
  /// animations with shared geometry.
  final SpriteMesh mesh;

  /// Creates a new [GameSprite] with the specified properties.
  ///
  /// This constructor allows for fine-grained control over how the texture 
  /// region is interpreted and rendered within the game world.
  ///
  /// * [texture]: The source image for the sprite.
  /// * [rect]: The rectangular region within the texture to use. Defaults 
  /// to the entire texture.
  /// * [pivot]: The origin point for transformations.
  /// * [pixelsPerUnit]: The resolution scale for world-space rendering.
  /// * [mesh]: The geometry used to draw the sprite.
  const GameSprite({
    required this.texture,
    ui.Rect? rect,
    this.pivot = NormalizedPivot.center,
    this.pixelsPerUnit = 100.0,
    this.mesh = const SimpleMesh(),
  }) : _rect = rect;

  /// The texture asset used by this sprite.
  ///
  /// This getter provides a semantic alias for [texture], emphasizing its 
  /// role as a managed game asset.
  GameTexture get textureAsset => texture;

  /// The rectangular region of the texture assigned to this sprite.
  ///
  /// If no specific rect was provided during construction, this returns 
  /// the full dimensions of the underlying texture.
  ui.Rect get rect =>
      _rect ??
      ui.Rect.fromLTWH(
        0,
        0,
        texture.width.toDouble(),
        texture.height.toDouble(),
      );

  /// Alias for [rect], specifically referring to its position on the texture.
  ///
  /// This property is often used by rendering systems to calculate UV 
  /// coordinates for drawing the sprite's geometry.
  ui.Rect get textureRect => rect;

  /// The dimensions of the sprite in pixels.
  ///
  /// This size is derived from the [rect] property and represents the 
  /// unscaled visual area of the sprite.
  ui.Size get size => rect.size;

  /// The offset of the pivot point relative to the sprite's top-left corner.
  ///
  /// This value is calculated based on the [pivot] strategy and the 
  /// sprite's [size]. It is used to position the sprite during rendering.
  ui.Offset get pivotOffset => pivot.compute(rect.size);

  /// The world-space boundaries of the sprite.
  ///
  /// This rectangle represents the area the sprite occupies in the game 
  /// world, taking into account the [pixelsPerUnit] and [pivotOffset].
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

/// A component that renders a [GameSprite] onto the screen.
///
/// [SpriteRenderer] is the primary way to display images in the game world. It 
/// handles positioning, scaling (via pixels per unit), flipping, and color 
/// tinting. It also supports different blend modes and filter qualities.
///
/// ```dart
/// void example(GameObject object, GameSprite sprite) {
///   final renderer = SpriteRenderer()..sprite = sprite;
///   object.addComponent(renderer);
///   renderer.color = const Color(0xFFFF0000); // Red tint
/// }
/// ```
///
/// See also:
/// * [GameSprite] for the image data to be rendered.
/// * [Renderable] for the interface that provides the render call.
class SpriteRenderer extends Behavior with Renderable {
  /// The sprite to be rendered by this component.
  ///
  /// If this is null, the renderer will not draw anything. When set, the 
  /// component uses the sprite's texture, rect, and pivot for rendering.
  GameSprite? sprite;

  /// The color tint applied to the sprite during rendering.
  ///
  /// By default, this is white (no tint). The color is combined with the 
  /// sprite's pixels using the current [blendMode] (typically [ui.BlendMode.modulate]).
  ui.Color color = const ui.Color(0xFFFFFFFF);

  /// Whether the sprite should be flipped horizontally.
  ///
  /// This transformation is applied relative to the sprite's pivot point. 
  /// It is useful for reusing the same sprite for left and right-facing characters.
  bool flipX = false;

  /// Whether the sprite should be flipped vertically.
  ///
  /// This transformation is applied relative to the sprite's pivot point. 
  /// It is useful for effects like reflections or upside-down orientations.
  bool flipY = false;

  /// The quality of filtering used when scaling the sprite.
  ///
  /// Defaults to [ui.FilterQuality.low] (bilinear). Higher quality filters 
  /// provide better scaling results but may have a performance impact.
  ui.FilterQuality filterQuality = ui.FilterQuality.low;

  /// The blend mode used when applying the [color] tint.
  ///
  /// Defaults to [ui.BlendMode.modulate], which multiplies the sprite's 
  /// pixel colors with the [color] value.
  ui.BlendMode blendMode = ui.BlendMode.modulate;

  /// A convenience setter to update the sprite's texture.
  ///
  /// Setting this creates a new [GameSprite] with default properties for the 
  /// provided [tex]. If the input is null, the [sprite] field is cleared.
  ///
  /// * [tex]: The new texture to assign to the renderer.
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

/// A coordinate pair representing a tile's position in a grid-based sprite sheet.
///
/// The first value represents the horizontal index (column), and the second 
/// value represents the vertical index (row). Both indices are zero-based.
typedef TileCoord = (int x, int y);

/// A single entry in a tagged sprite sheet.
///
/// This class maps a unique [key] (often a string or enum) to a specific 
/// [rect] within the texture. It is used to define named regions in 
/// a texture atlas.
///
/// ```dart
/// void example() {
///   const entry = SheetEntry(
///     key: 'player',
///     rect: Rect.fromLTRB(0, 0, 32, 32),
///   );
/// }
/// ```
///
/// See also:
/// * [TaggedSpriteSheet] for using these entries to create a sheet.
///
/// * [K]: The type of the tag used to identify the sprite.
class SheetEntry<K> {
  /// The unique identifier for this sprite entry.
  ///
  /// This key is used when retrieving the sprite from a [TaggedSpriteSheet]. 
  /// It can be any type, but is commonly a [String] or [Enum].
  final K key;

  /// The rectangular region within the texture assigned to this tag.
  ///
  /// This rect defines the top-left corner and dimensions of the sprite in 
  /// pixel coordinates relative to the texture's origin.
  final ui.Rect rect;

  /// Creates a new [SheetEntry] with the specified [key] and [rect].
  ///
  /// * [key]: The tag used to retrieve this sprite.
  /// * [rect]: The position and size of the sprite on the texture.
  const SheetEntry({required this.key, required this.rect});
}

/// A base class for organizing and retrieving multiple sprites from a single texture.
///
/// Sprite sheets help optimize rendering by grouping multiple images into 
/// a single texture atlas. Subclasses implement different strategies for 
/// partitioning the texture, such as uniform grids or tagged regions.
///
/// ```dart
/// enum TextureAsset with AssetEnum, TextureAssetEnum {
///   tiles('assets/tiles.png');
///   const TextureAsset(this.path);
///   final String path;
///   @override
///   AssetSource get source => AssetSource.local(path);
/// }
///
/// void example() {
///   final sheet = SpriteSheet.grid(
///     texture: TextureAsset.tiles,
///     rows: 4,
///     columns: 4,
///   );
///   final sprite = sheet[(0, 0)];
/// }
/// ```
///
/// See also:
/// * [GridSpriteSheet] for uniform grid partitioning.
/// * [TaggedSpriteSheet] for arbitrary tagged regions.
abstract class SpriteSheet<K> {
  /// The source texture containing all the sprites in the sheet.
  ///
  /// This texture is used as the base for all [GameSprite] instances generated 
  /// by this sheet. It must be loaded before any sprites from the sheet 
  /// can be rendered.
  final GameTexture texture;

  /// Creates a new [SpriteSheet] with the specified [texture].
  ///
  /// * [texture]: The shared image asset for all sprites in the sheet.
  const SpriteSheet({required this.texture});

  /// Retrieves a sprite from the sheet using the provided [key].
  ///
  /// The interpretation of the [key] depends on the subclass implementation 
  /// (e.g., a [TileCoord] for grids or a generic tag for tagged sheets).
  ///
  /// * [key]: The identifier for the desired sprite.
  GameSprite getTileAt(K key);

  /// Convenience operator for [getTileAt].
  ///
  /// Allows retrieving sprites using the square bracket syntax: `sheet[key]`.
  ///
  /// * [key]: The identifier for the desired sprite.
  GameSprite operator [](K key) => getTileAt(key);

  /// Creates a [TaggedSpriteSheet] from a list of entries.
  ///
  /// This factory is a convenience method for defining a sheet where 
  /// sprites are identified by unique tags of type [K].
  ///
  /// * [texture]: The source image asset.
  /// * [entries]: The list of named regions within the texture.
  /// * [pivot]: The default pivot for all sprites in the sheet.
  /// * [pixelsPerUnit]: The default resolution scale.
  /// * [mesh]: The default geometry for the sprites.
  const factory SpriteSheet.tagged({
    required GameTexture texture,
    required List<SheetEntry<K>> entries,
    SpritePivot pivot,
    double pixelsPerUnit,
    SpriteMesh mesh,
  }) = TaggedSpriteSheet<K>;

  /// Creates a [GridSpriteSheet] with uniform tile sizes.
  ///
  /// This static method is a convenience for defining a sheet where 
  /// the texture is divided into a regular grid of rows and columns.
  ///
  /// * [texture]: The source image asset.
  /// * [rows]: The number of horizontal rows in the grid.
  /// * [columns]: The number of vertical columns in the grid.
  /// * [offset]: The top-left offset where the grid starts.
  /// * [spacing]: The gap between individual tiles in the grid.
  /// * [spriteSize]: The explicit size of each tile. If null, it is 
  /// calculated from the texture dimensions and grid counts.
  /// * [pivot]: The pivot for all tiles in the grid.
  /// * [ppu]: The pixels per unit scale for the grid tiles.
  /// * [mesh]: The geometry used for the grid tiles.
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

  /// Manually splits a texture into a list of [GameSprite] objects.
  ///
  /// This utility method is useful for creating simple animations or 
  /// batches of sprites that don't require the persistent state of 
  /// a [SpriteSheet] object.
  ///
  /// * [texture]: The source image asset.
  /// * [rows]: The number of horizontal rows to split.
  /// * [columns]: The number of vertical columns to split.
  /// * [offset]: The top-left starting position for the split.
  /// * [spriteSize]: The explicit size of each split region.
  /// * [pivot]: The pivot for all resulting sprites.
  /// * [ppu]: The pixels per unit scale for the sprites.
  /// * [mesh]: The geometry used for the sprites.
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

/// A sprite sheet where sprites are identified by unique tags or keys.
///
/// [TaggedSpriteSheet] is ideal for texture atlases where sprites have 
/// varying sizes or are placed irregularly. Each sprite is defined by a 
/// [SheetEntry] that maps a key to a specific rectangle.
///
/// ```dart
/// enum TextureAsset with AssetEnum, TextureAssetEnum {
///   atlas('assets/atlas.png');
///   const TextureAsset(this.path);
///   final String path;
///   @override
///   AssetSource get source => AssetSource.local(path);
/// }
///
/// void example() {
///   final sheet = TaggedSpriteSheet(
///     texture: TextureAsset.atlas,
///     entries: [
///       SheetEntry(key: 'player', rect: Rect.fromLTRB(0, 0, 32, 64)),
///       SheetEntry(key: 'enemy', rect: Rect.fromLTRB(32, 0, 32, 32)),
///     ],
///   );
///   final player = sheet['player'];
/// }
/// ```
///
/// See also:
/// * [SpriteSheet] for the base class and shared properties.
/// * [SheetEntry] for the definition of tagged regions.
class TaggedSpriteSheet<T> extends SpriteSheet<T> {
  /// The list of entries defining the tagged regions in the sheet.
  ///
  /// Each entry provides a key and a rectangle that specifies which part 
  /// of the texture to use for that specific tag.
  final List<SheetEntry<T>> entries;

  /// The default pivot point for all sprites retrieved from this sheet.
  ///
  /// This pivot is applied to every [GameSprite] created through the 
  /// [getTileAt] method, ensuring consistent alignment across the sheet.
  final SpritePivot pivot;

  /// The default pixels per unit scale for all sprites in this sheet.
  ///
  /// This value determines the world-space size of the retrieved sprites 
  /// relative to their pixel dimensions on the texture.
  final double pixelsPerUnit;

  /// The default mesh geometry for all sprites in this sheet.
  ///
  /// While most sprites use a [SimpleMesh], this property allows for 
  /// custom geometry to be shared by all entries in the sheet.
  final SpriteMesh mesh;

  /// Creates a new [TaggedSpriteSheet] with the specified configuration.
  ///
  /// * [texture]: The shared source image.
  /// * [entries]: The map of keys to texture regions.
  /// * [pivot]: The default pivot point for the sprites.
  /// * [pixelsPerUnit]: The default resolution scale.
  /// * [mesh]: The default geometry used for rendering.
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

/// A sprite sheet where the texture is divided into a regular grid.
///
/// [GridSpriteSheet] is used for textures containing uniformly sized tiles, 
/// such as tilesets or simple character animation frames. Sprites are 
/// retrieved using [TileCoord] indices.
///
/// ```dart
/// enum TextureAsset with AssetEnum, TextureAssetEnum {
///   terrain('assets/terrain.png');
///   const TextureAsset(this.path);
///   final String path;
///   @override
///   AssetSource get source => AssetSource.local(path);
/// }
///
/// void example() {
///   final sheet = GridSpriteSheet(
///     texture: TextureAsset.terrain,
///     rows: 8,
///     columns: 8,
///   );
/// }
/// ```
///
/// See also:
/// * [SpriteSheet] for the base class and shared properties.
/// * [TileCoord] for the coordinate system used by this sheet.
class GridSpriteSheet extends SpriteSheet<TileCoord> {
  /// The number of horizontal rows in the grid.
  ///
  /// This count is used to validate indices and calculate the default 
  /// height of each tile when [spriteSize] is not provided.
  final int rows;

  /// The number of vertical columns in the grid.
  ///
  /// This count is used to validate indices and calculate the default 
  /// width of each tile when [spriteSize] is not provided.
  final int columns;

  /// The top-left offset where the grid partitioning begins.
  ///
  /// This allows the sheet to ignore decorative borders or padding 
  /// that might be present at the start of the texture.
  final ui.Offset offset;

  /// The horizontal and vertical gaps between adjacent tiles.
  ///
  /// Spacing is taken into account when calculating tile rectangles to 
  /// ensure that "gutters" in the texture are correctly skipped.
  final ui.Offset spacing;

  /// The explicit size of each tile in the grid.
  ///
  /// If null, the size is automatically calculated based on the texture 
  /// dimensions, grid counts, offset, and spacing.
  final ui.Size? spriteSize;

  /// The default pivot point for all sprites retrieved from this sheet.
  ///
  /// This pivot is applied to every [GameSprite] created through the 
  /// [getTileAt] method, ensuring consistent alignment across the grid.
  final SpritePivot pivot;

  /// The default pixels per unit scale for all sprites in this sheet.
  ///
  /// This value determines the world-space size of the retrieved sprites 
  /// relative to their pixel dimensions on the texture.
  final double pixelsPerUnit;

  /// The default mesh geometry for all sprites in this sheet.
  ///
  /// While most sprites use a [SimpleMesh], this property allows for 
  /// custom geometry to be shared by all tiles in the grid.
  final SpriteMesh mesh;

  /// Creates a new [GridSpriteSheet] with the specified grid configuration.
  ///
  /// * [texture]: The shared source image.
  /// * [rows]: The number of rows in the grid.
  /// * [columns]: The number of columns in the grid.
  /// * [offset]: The starting position for the grid.
  /// * [spacing]: The spacing between tiles.
  /// * [spriteSize]: The explicit size for each tile.
  /// * [pivot]: The default pivot for the sprites.
  /// * [pixelsPerUnit]: The default resolution scale.
  /// * [mesh]: The default geometry for rendering.
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
