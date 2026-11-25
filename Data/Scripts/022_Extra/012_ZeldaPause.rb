#===============================================================================
#
#===============================================================================
class ZeldaPause_Scene
  MAP_WANG_TILES = [4, 6,14,12,
                    5, 7,15,13,
                    1, 3,11, 9,
                    0, 2,10, 8]

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @dungeon_data = pbGetCurrentDungeon
    @paint = $PokemonGlobal.current_paint_color
    
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    if @dungeon_data
      addBackgroundPlane(@sprites, "bg", "Pause Menu/bg_map", @viewport)
    else
      addBackgroundPlane(@sprites, "bg", "Pause Menu/bg", @viewport)
    end
    @sprites["h_tool_0"] = IconSprite.new(40,0,@viewport)
    @sprites["h_tool_1"] = IconSprite.new(144,0,@viewport)
    $PokemonGlobal.inventory_tools.each_with_index do |t, i|
      x = (i % 2)*96 + 32
      y = (i/2)*48 + 48
      @sprites["i_tool_#{i}"] = IconSprite.new(x, y, @viewport)
    end
    update_tool_graphics
    
    @sprites["save"] = IconSprite.new(224,48,@viewport)
    @sprites["save"].setBitmap(_INTL("Graphics/UI/Pause Menu/icon_save"))
    
    @sprites["cursor"] = IconSprite.new(16, 48, @viewport)
    @sprites["cursor"].setBitmap(_INTL("Graphics/UI/Pause Menu/cursor"))
    @sprites["cursor"].src_rect = Rect.new(0,0,80,32)
    
    @heart_bitmap = AnimatedBitmap.new("Graphics/UI/hearts")
    @key_bitmap = AnimatedBitmap.new("Graphics/UI/ZeldaHUD/key_icon")
    @numbers_bitmap = AnimatedBitmap.new("Graphics/UI/numbers")
    @map_bitmap = AnimatedBitmap.new("Graphics/UI/Pause Menu/tiles_map")
    @chest_bitmap = AnimatedBitmap.new("Graphics/UI/Pause Menu/icon_map_chest")
    
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    draw_hearts
    draw_money_keys
    draw_map
    draw_key_items
    
    @sprites["map_cursor"] = Sprite.new(@viewport)
    @sprites["map_cursor"].visible = !@dungeon_data.nil?
    bitmaptmp = AnimatedBitmap.new("Graphics/UI/Pause Menu/icon_map_player")
    bitmap = Bitmap.new(16, 16)
    palette = Settings::SMEARGLE_PAINT_COLORS[@paint]
    rawdata = bitmaptmp.bitmap.raw_data.bytes
    bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
    @sprites["map_cursor"].bitmap = bitmap
    @sprites["map_cursor"].x = $game_player.x/(Settings::ZELDA_SCREEN_WIDTH/Game_Map::TILE_WIDTH)*16 + 240
    @sprites["map_cursor"].y = $game_player.y/(Settings::ZELDA_SCREEN_HEIGHT/Game_Map::TILE_HEIGHT)*16 + 144
    
    @cur_pos = 0
  end
  
  def update_cursor
    if @cur_pos == 10
      @sprites["cursor"].x = 208
      @sprites["cursor"].y = 48
      @sprites["cursor"].src_rect = Rect.new(0,32,96,32)
    else
      @sprites["cursor"].x = (@cur_pos % 2)*96 + 16
      @sprites["cursor"].y = (@cur_pos/2)*48 + 48
      @sprites["cursor"].src_rect = Rect.new(0,0,80,32)
    end
  end
  
  def update_tool_graphics
    $PokemonGlobal.hud_tools.each_with_index do |t,i|
      if t.nil?
        @sprites["h_tool_#{i}"].setBitmap(nil)
      else
        @sprites["h_tool_#{i}"].setBitmap(sprintf("Graphics/UI/ZeldaHUD/tool_%s",t.to_s))
        if t == :brush
          palette = Settings::SMEARGLE_PAINT_COLORS[@paint]
          rawdata = @sprites["h_tool_#{i}"].bitmap.raw_data.bytes
          @sprites["h_tool_#{i}"].bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
        end
      end
    end
    $PokemonGlobal.inventory_tools.each_with_index do |t, i|
       if t.nil?
        @sprites["i_tool_#{i}"].setBitmap(nil)
      else
        @sprites["i_tool_#{i}"].setBitmap(sprintf("Graphics/UI/ZeldaHUD/tool_%s",t.to_s))
        if t == :brush
          palette = Settings::SMEARGLE_PAINT_COLORS[@paint]
          rawdata = @sprites["i_tool_#{i}"].bitmap.raw_data.bytes
          @sprites["i_tool_#{i}"].bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
        end
      end
    end
  end
  
  def draw_hearts
    overlay = @sprites["overlay"].bitmap
    max_hearts = $PokemonGlobal.smeargle_hp_max/4
    last_heart_progress = $PokemonGlobal.smeargle_hp_current % 4
    full_hearts = $PokemonGlobal.smeargle_hp_current/4
    16.times do |i|
      index = 0
      if i<full_hearts
        index = 5
      elsif i==full_hearts && last_heart_progress>0
        index = last_heart_progress+1
      elsif i<max_hearts
        index = 1
      end
      break if index == 0
      x = (i%8)*16 + 256
      y = (i/8)*16
      overlay.blt(x,y,@heart_bitmap.bitmap,Rect.new(index*16,0,16,16))
    end
  end
  
  def draw_money_keys
    overlay = @sprites["overlay"].bitmap
    keys = @dungeon_data&.keys
    if keys
      overlay.blt(208,0,@key_bitmap.bitmap,@key_bitmap.bitmap.rect)
      pbDrawNumber(keys,overlay,240,0)
    end
  end
  
  def pbDrawNumber(number, btmp, startX, startY, align = :left)
    n = number.to_i.digits.reverse
    charWidth  = @numbers_bitmap.width / 10
    charHeight = @numbers_bitmap.height
    startX -= charWidth * n.length if align == :right
    n.each do |i|
      btmp.blt(startX, startY, @numbers_bitmap.bitmap, Rect.new(i * charWidth, 0, charWidth, charHeight))
      startX += charWidth
    end
  end
  
  def draw_map
    return unless @dungeon_data
    overlay = @sprites["overlay"].bitmap
    if @dungeon_data.map
      map_layout = GameData::Dungeon.get(@dungeon_data.id).map_layout
      map_layout.each_with_index do |t,i|
        next unless t
        dx = (i%8)*16 + 240
        dy = (i/8)*16 + 144
        src_i = MAP_WANG_TILES.index(t)
        sx = (src_i%4)*16
        sy = (src_i/4)*16
        overlay.blt(dx,dy,@map_bitmap.bitmap,Rect.new(sx,sy,16,16))
      end
    end
    if @dungeon_data.compass
      $game_map.events.each_value do |e|
        next unless e.name[/chest/i]
        key = [e.map_id, e.id, 'B']
        next if $game_self_switches[key]
        dx = e.x/(Settings::ZELDA_SCREEN_WIDTH/Game_Map::TILE_WIDTH)*16 + 240
        dy = e.y/(Settings::ZELDA_SCREEN_HEIGHT/Game_Map::TILE_HEIGHT)*16 + 144
        overlay.blt(dx,dy,@chest_bitmap.bitmap,Rect.new(0,0,16,16))
      end
    end
  end
  
  def draw_key_items
    if @dungeon_data
      overlay = @sprites["overlay"].bitmap
      img_pos = []
      if @dungeon_data.compass
        img_pos.push(["Graphics/UI/Pause Menu/icon_compass",208,96])
      end
      if @dungeon_data.map
        img_pos.push(["Graphics/UI/Pause Menu/icon_map",250,96])
      end
      if @dungeon_data.boss_key
        img_pos.push(["Graphics/UI/Pause Menu/icon_boss_key",294,96])
      end
      if @dungeon_data.keys > 0
        img_pos.push(["Graphics/UI/Pause Menu/icon_keys",336,96])
      end
      pbDrawImagePositions(overlay,img_pos)
      pbDrawNumber(@dungeon_data.keys,overlay,352,112) if @dungeon_data.keys>0
    end
  end

  def pbMidScene
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldpos = @cur_pos
      refresh_tools = false
      if Input.trigger?(Input::SPECIAL)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::UP)
        if @cur_pos != 10
          if @cur_pos/2 == 0
            @cur_pos += 8
          else
            @cur_pos -= 2
          end
        end
      elsif Input.trigger?(Input::DOWN)
        if @cur_pos != 10
          if @cur_pos/2 == 4
            @cur_pos -= 8
          else
            @cur_pos += 2
          end
        end
      elsif Input.trigger?(Input::LEFT)
        if @cur_pos == 10
          @cur_pos = 1
        elsif @cur_pos == 0
          @cur_pos = 10
        else
          @cur_pos -= 1
        end
      elsif Input.trigger?(Input::RIGHT)
        if @cur_pos == 10
          @cur_pos = 0
        elsif @cur_pos == 1
          @cur_pos = 10
        else
          @cur_pos += 1
        end
      elsif Input.trigger?(Input::BACK)
        if @cur_pos != 10
          refresh_tools = true
          temp = $PokemonGlobal.hud_tools[0]
          $PokemonGlobal.hud_tools[0] = $PokemonGlobal.inventory_tools[@cur_pos]
          $PokemonGlobal.inventory_tools[@cur_pos] = temp
        end
      elsif Input.trigger?(Input::USE)
        if @cur_pos != 10
          refresh_tools = true
          temp = $PokemonGlobal.hud_tools[1]
          $PokemonGlobal.hud_tools[1] = $PokemonGlobal.inventory_tools[@cur_pos]
          $PokemonGlobal.inventory_tools[@cur_pos] = temp
        else
          if Game.save
            pbMessage(_INTL("\\l[1]<ac>GAME SAVED</ac>"))
          end
        end
      end
      if @cur_pos != oldpos
        update_cursor
      end
      update_tool_graphics if refresh_tools
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class ZeldaPauseScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMidScene
    @scene.pbEndScene
  end
end
