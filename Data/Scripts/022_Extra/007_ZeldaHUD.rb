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
    @sprites["overlay"] = BitmapSprite.new(112, 32, @viewport)
    @sprites["overlay"].x = 240
    @sprites["overlay"].y = Settings::ZELDA_SCREEN_HEIGHT
    @sprites["overlay"].z = 1001
    @hearts = AnimatedBitmap.new("Graphics/UI/ZeldaHUD/hearts")
  end
  
  def dispose
    @hearts.dispose
    pbDisposeSpriteHash(@sprites)
    @disposed = true
  end
  
  def need_refresh?
    return true if $game_temp.game_over_time || (@game_over && $game_temp.game_over_time.nil?)
    return true if @items != $PokemonGlobal.hud_tools
    return true if @maxhp != $PokemonGlobal.smeargle_hp_max
    return true if @hp != $PokemonGlobal.smeargle_hp_current
    return true if @paint != $PokemonGlobal.current_paint_color && @items.any?(:brush)
    return false
  end
  
  def refresh
    @items = $PokemonGlobal.hud_tools.clone
    @maxhp = $PokemonGlobal.smeargle_hp_max
    @hp = $PokemonGlobal.smeargle_hp_current
    @paint = $PokemonGlobal.current_paint_color
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
  end
  
  def draw_hearts
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    max_hearts = @maxhp/4
    last_heart_progress = @hp % 4
    full_hearts = @hp/4
    14.times do |i|
      index = 0
      if i<full_hearts
        index = 5
      elsif i==full_hearts && last_heart_progress>0
        index = last_heart_progress+1
      elsif i<max_hearts
        index = 1
      end
      x = (i%7)*16
      y = (i/7)*16
      overlay.blt(x,y,@hearts.bitmap,Rect.new(index*16,0,16,16))
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