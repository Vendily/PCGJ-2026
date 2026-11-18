class ZeldaHUD
  def initialize(viewport)
    @viewport = viewport
    @sprites = {}
    @sprites["bar"]=IconSprite.new(0,Settings::ZELDA_SCREEN_HEIGHT,@viewport)
    @sprites["bar"].setBitmap("Graphics/UI/ZeldaHUD/hud")
    @sprites["bar"].z = 1001
    @sprites["item_0"] = IconSprite.new(40,Settings::ZELDA_SCREEN_HEIGHT,@viewport)
    @sprites["item_0"].z = 1001
    @sprites["item_1"] = IconSprite.new(144,Settings::ZELDA_SCREEN_HEIGHT,@viewport)
    @sprites["item_1"].z = 1001
    @sprites["overlay_hp"] = BitmapSprite.new(128, 32, @viewport)
    @sprites["overlay_hp"].x = 256
    @sprites["overlay_hp"].y = Settings::ZELDA_SCREEN_HEIGHT
    @sprites["overlay_hp"].z = 1001
    @sprites["overlay_money_keys"] = BitmapSprite.new(48, 32, @viewport)
    @sprites["overlay_money_keys"].x = 208
    @sprites["overlay_money_keys"].y = Settings::ZELDA_SCREEN_HEIGHT
    @sprites["overlay_money_keys"].z = 1001
    @heart_bitmap = AnimatedBitmap.new("Graphics/UI/hearts")
    @key_bitmap = AnimatedBitmap.new("Graphics/UI/ZeldaHUD/key_icon")
    @numbers_bitmap = AnimatedBitmap.new("Graphics/UI/numbers")
  end
  
  def dispose
    @heart_bitmap.dispose
    pbDisposeSpriteHash(@sprites)
    @disposed = true
  end
  
  def need_refresh?
    return true if $game_temp.game_over_time || (@game_over && $game_temp.game_over_time.nil?)
    return true if @items != $PokemonGlobal.hud_tools
    return true if @maxhp != $PokemonGlobal.smeargle_hp_max
    return true if @hp != $PokemonGlobal.smeargle_hp_current
    return true if @keys != pbGetCurrentDungeon&.keys
    return false
  end
  
  def refresh
    @items = $PokemonGlobal.hud_tools.clone
    @maxhp = $PokemonGlobal.smeargle_hp_max
    @hp = $PokemonGlobal.smeargle_hp_current
    @paint = $PokemonGlobal.current_paint_color
    @keys = pbGetCurrentDungeon&.keys
    if $game_temp.game_over_time
      if !@game_over
        draw_hearts
        @game_over = true
      end
      now = System.uptime
      if now - $game_temp.game_over_time <=1.0
        alpha = lerp(0, 255, 1.0, $game_temp.game_over_time, now)
        color = Color.new(255,255,255,alpha)
        @sprites.each_value{|s| s.color = color }
      end
      return
    elsif @game_over && $game_temp.game_over_time.nil?
      color = Color.new(0,0,0,0)
      @sprites.each_value{|s| s.color = color }
    end
    @game_over = false
    @items.each_with_index do |item,i|
      if item.nil?
        @sprites["item_#{i}"].setBitmap(nil)
      else
        @sprites["item_#{i}"].setBitmap(sprintf("Graphics/UI/ZeldaHUD/tool_%s",item.to_s))
        if item == :brush
          palette = Settings::SMEARGLE_PAINT_COLORS[@paint]
          rawdata = @sprites["item_#{i}"].bitmap.raw_data.bytes
          @sprites["item_#{i}"].bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
        end
      end
    end
    draw_hearts
    draw_money_keys
  end
  
  def draw_hearts
    overlay = @sprites["overlay_hp"].bitmap
    overlay.clear
    max_hearts = @maxhp/4
    last_heart_progress = @hp % 4
    full_hearts = @hp/4
    16.times do |i|
      index = 0
      if i<full_hearts
        index = 5
      elsif i==full_hearts && last_heart_progress>0
        index = last_heart_progress+1
      elsif i<max_hearts
        index = 1
      end
      x = (i%8)*16
      y = (i/8)*16
      overlay.blt(x,y,@heart_bitmap.bitmap,Rect.new(index*16,0,16,16))
    end
  end
  
  def draw_money_keys
    overlay = @sprites["overlay_money_keys"].bitmap
    overlay.clear
    if @keys
      overlay.blt(0,0,@key_bitmap.bitmap,@key_bitmap.bitmap.rect)
      pbDrawNumber(@keys,overlay,32,0)
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
  
  def update
    refresh if need_refresh?
    pbUpdateSpriteHash(@sprites)
  end
end

class Spriteset_Global
  attr_reader :hud
  alias _zhud_initialize initialize
  def initialize
    @hud = ZeldaHUD.new(Spriteset_Map.viewport)
    _zhud_initialize
  end
  
  alias _zhud_dispose dispose
  def dispose
    _zhud_dispose
    @hud.dispose
    @hud = nil
  end

  alias _zhud_update update
  def update
    _zhud_update
    @hud.update
  end
end