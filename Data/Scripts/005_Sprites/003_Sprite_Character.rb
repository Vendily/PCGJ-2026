#===============================================================================
#
#===============================================================================
class Sprite_Character < RPG::Sprite
  attr_accessor :character

  def initialize(viewport, character = nil)
    super(viewport)
    @character    = character
    @spriteoffset = false
    if !character || character == $game_player || (character.name[/reflection/i] rescue false)
      @reflection = Sprite_Reflection.new(self, viewport)
    end
    self.zoom_x = TilemapRenderer::ZOOM_X
    self.zoom_y = TilemapRenderer::ZOOM_Y
    @ow_bitmap = nil
    @old_sepia = false
    update
  end

  def groundY
    return @character.screen_y_ground
  end

  def visible=(value)
    super(value)
    @reflection.visible = value if @reflection
  end

  def dispose
    @charbitmap&.dispose
    @charbitmap = nil
    @ow_bitmap&.dispose
    @ow_bitmap = nil
    @reflection&.dispose
    @reflection = nil
    @surfbase&.dispose
    @surfbase = nil
    @character = nil
    super
  end
  
  def get_character_paint
    return $PokemonGlobal.current_paint_color if @character == $game_player
    return $PokemonGlobal.painted_events[[@character.map_id,@character.id]]
  end
  
  def refresh_graphic
    return if @tile_id == @character.tile_id &&
              @character_name == @character.character_name &&
              @character_hue == @character.character_hue &&
              @character_paint == get_character_paint &&
              @old_sepia == $game_switches[Settings::SMEARGLE_PAINT_SEPIA_SWITCH]
    @tile_id        = @character.tile_id
    @character_name = @character.character_name
    @character_hue  = @character.character_hue
    @character_paint = get_character_paint
    @old_sepia = $game_switches[Settings::SMEARGLE_PAINT_SEPIA_SWITCH]
    @charbitmap&.dispose
    @charbitmap = nil
    @ow_bitmap&.dispose
    @ow_bitmap = nil
    if @tile_id >= 384
      @charbitmap = pbGetTileBitmap(@character.map.tileset_name, @tile_id,
                                    @character_hue, @character.width, @character.height)
      @charbitmapAnimated = false
      @spriteoffset = false
      @cw = Game_Map::TILE_WIDTH * @character.width
      @ch = Game_Map::TILE_HEIGHT * @character.height
      self.src_rect.set(0, 0, @cw, @ch)
      self.ox = @cw / 2
      self.oy = @ch
    elsif @character_name != ""
      @charbitmap = AnimatedBitmap.new(
        "Graphics/Characters/" + @character_name, @character_hue
      )
      RPG::Cache.retain("Graphics/Characters/", @character_name, @character_hue) if @character == $game_player
      @charbitmapAnimated = true
      @spriteoffset = @character_name[/offset/i]
      @cw = @charbitmap.width / 4
      @ch = @charbitmap.height / 4
      self.ox = @cw / 2
    else
      self.bitmap = nil
      @cw = 0
      @ch = 0
      @reflection&.update
    end
    if @charbitmap
      b = @charbitmapAnimated ? @charbitmap.bitmap : @charbitmap
      @ow_bitmap = Bitmap.new(@charbitmap.width,@charbitmap.height)
      @ow_bitmap.blt(0, 0, b,@ow_bitmap.rect)
      apply_event_color(@ow_bitmap) if @character_paint || @old_sepia
    end
    @character.sprite_size = [@cw, @ch]
  end
  
  def apply_event_color(bitmap)
    if $game_switches[Settings::SMEARGLE_PAINT_SEPIA_SWITCH]
      palette = nil
    else
      palette = Settings::SMEARGLE_PAINT_COLORS[@character_paint]
    end
    rawdata = bitmap.raw_data.bytes
    bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
  end

  def update
    return if @character.is_a?(Game_Event) && !@character.should_update?
    super
    refresh_graphic
    return if !@charbitmap
    @charbitmap.update if @charbitmapAnimated
    if @charbitmapAnimated
      @ow_bitmap.blt(0, 0, @charbitmap.bitmap,@ow_bitmap.rect)
      apply_event_color(@ow_bitmap) if @character_paint || $game_switches[Settings::SMEARGLE_PAINT_SEPIA_SWITCH]
    end
    self.bitmap = @ow_bitmap
    if $game_temp.game_over_time
      self.visible = (@character == $game_player)
    else
      self.visible = !@character.transparent
    end
    if @tile_id == 0
      sx = @character.pattern * @cw
      sy = ((@character.direction - 2) / 2) * @ch
      self.src_rect.set(sx, sy, @cw, @ch)
      self.oy = (@spriteoffset rescue false) ? @ch - 16 : @ch
      self.oy -= @character.bob_height
    end
    if self.visible
      if @character.is_a?(Game_Event) && @character.name[/regulartone/i]
        self.tone.set(0, 0, 0, 0)
      else
        pbDayNightTint(self)
      end
    end
    this_x = @character.screen_x
    this_x = ((this_x - (Graphics.width / 2)) * TilemapRenderer::ZOOM_X) + (Graphics.width / 2) if TilemapRenderer::ZOOM_X != 1
    self.x = this_x
    this_y = @character.screen_y
    this_y = ((this_y - (Graphics.height / 2)) * TilemapRenderer::ZOOM_Y) + (Graphics.height / 2) if TilemapRenderer::ZOOM_Y != 1
    self.y = this_y
    self.z = @character.screen_z(@ch)
    self.opacity = @character.opacity
    self.blend_type = @character.blend_type
    if @character.animation_id != 0
      animation = $data_animations[@character.animation_id]
      animation(animation, true)
      @character.animation_id = 0
    end
    @reflection&.update
    @surfbase&.update
  end
end
