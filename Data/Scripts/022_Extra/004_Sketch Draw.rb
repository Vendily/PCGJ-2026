class SketchDrawTile < BitmapSprite
  attr_reader :tile

  def initialize(tile,viewport,cursor = false)
    @viewport = viewport
    if cursor
      @image = AnimatedBitmap.new("Graphics/UI/Sketch Draw/tiles_cursor")
    else
      @image = AnimatedBitmap.new("Graphics/UI/Sketch Draw/tiles")
    end
    super(@image.bitmap.width, @image.bitmap.width, @viewport)
    @tile = tile
    @need_refresh = true
    update
  end

  def tile=(value)
    @tile = value
    @need_refresh = true
  end

  def update
    if @need_refresh
      @need_refresh = false
      self.bitmap.blt(0, 0, @image.bitmap,
          Rect.new(0, @image.bitmap.width * (@tile), @image.bitmap.width, @image.bitmap.width))
    end
  end
end

class SketchDrawCursor < BitmapSprite
  attr_accessor :position
  
  def initialize(position, viewport)
    @viewport = viewport
    super(Graphics.width, Graphics.height, @viewport)
    @position = position
    @cursorbitmap = AnimatedBitmap.new("Graphics/UI/Sketch Draw/cursor")
    update
  end

  def update
    self.bitmap.clear
    x = 12 * (@position % SketchDraw_Scene::GRID_WIDTH)
    y = 12 * (@position / SketchDraw_Scene::GRID_WIDTH)
    x += 2 if (@position % SketchDraw_Scene::GRID_WIDTH) >= 8
    y += 2 if (@position / SketchDraw_Scene::GRID_WIDTH) >= 8
    self.bitmap.blt(x + 62, y + 80, @cursorbitmap.bitmap, Rect.new(0, 0, 20, 20))
  end
end

#===============================================================================
#
#===============================================================================
class SketchDraw_Scene
  GRID_WIDTH = 16
  GRID_HEIGHT = 16
  
  def initialize(sprite_data,setupProc,updateProc)
    @sprite_data = sprite_data
    @sprite_data = Array.new(256,0) unless @sprite_data
    @setupProc = setupProc
    @updateProc = updateProc
  end
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbUpdateBitmap
    self.instance_eval(&@updateProc)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["bg"]= IconSprite.new(0,0, @viewport)
    @sprites["bg"].setBitmap("Graphics/UI/Sketch Draw/bg")
    
    self.instance_eval(&@setupProc)
    pbUpdateBitmap
    
    @tile_color = 3
    
    
    # make tiles
    (GRID_WIDTH * GRID_HEIGHT).times do |i|
      @sprites["tile#{i}"] = SketchDrawTile.new(@sprite_data[i],@viewport)
      x = 12 * (i % SketchDraw_Scene::GRID_WIDTH)
      y = 12 * (i / SketchDraw_Scene::GRID_WIDTH)
      #x += 2 if (i % MimikyuDraw_Scene::GRID_WIDTH) >= 8
      #y += 2 if (i / MimikyuDraw_Scene::GRID_WIDTH) >= 8
      @sprites["tile#{i}"].x = x + 64
      @sprites["tile#{i}"].y = y + 88
    end
    
    @sprites["tile_color"] = SketchDrawTile.new(@tile_color,@viewport,true)
    @sprites["tile_color"].x = 44
    @sprites["tile_color"].y = 28
    
    @sprites["edge"] = Sprite.new(@viewport)
    @sprites["edge"].bitmap = AnimatedBitmap.new("Graphics/UI/Sketch Draw/overlay_edge").bitmap
    @sprites["edge"].x = 60
    @sprites["edge"].y = 84
    @sprites["edge"].z = 1
    
    @sprites["grid"] = Sprite.new(@viewport)
    @sprites["grid"].bitmap = AnimatedBitmap.new("Graphics/UI/Sketch Draw/overlay_grid").bitmap
    @sprites["grid"].x = 64
    @sprites["grid"].y = 88
    @sprites["grid"].z = 1
    
    @sprites["cursor"] = SketchDrawCursor.new(119,@viewport)   # central position, pick
    @sprites["cursor"].z = 3
    
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
  
  def pbHit
    i = @sprites["cursor"].position
    @sprite_data[i] = @tile_color
    @sprites["tile#{i}"].tile = @sprite_data[i]
    pbUpdateBitmap
  end

  def pbMain
    pbSEPlay("GUI trainer card open")
    old_position = @sprites["cursor"].position
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::UP) || Input.repeat?(Input::UP)
        if @sprites["cursor"].position >= GRID_WIDTH
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position -= GRID_WIDTH
        end
      elsif Input.trigger?(Input::DOWN) || Input.repeat?(Input::DOWN)
        if @sprites["cursor"].position < (GRID_WIDTH * (GRID_HEIGHT - 1))
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position += GRID_WIDTH
        end
      elsif Input.trigger?(Input::LEFT) || Input.repeat?(Input::LEFT)
        if @sprites["cursor"].position % GRID_WIDTH > 0
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position -= 1
        end
      elsif Input.trigger?(Input::RIGHT) || Input.repeat?(Input::RIGHT)
        if @sprites["cursor"].position % GRID_WIDTH < (GRID_WIDTH - 1)
          pbSEPlay("Mining cursor")
          @sprites["cursor"].position += 1
        end
      elsif Input.trigger?(Input::ACTION)
        @tile_color = (@tile_color + 1) % 4
        @sprites["tile_color"].tile = @tile_color
      elsif Input.trigger?(Input::SPECIAL) 
        @sprites["grid"].visible = !@sprites["grid"].visible
      elsif Input.trigger?(Input::BACK)   # Quit
        break if pbConfirmMessage(_INTL("All done?"))
      end
      if Input.trigger?(Input::USE) ||
        (old_position != @sprites["cursor"].position && Input.press?(Input::USE))
        pbHit
      end
      old_position = @sprites["cursor"].position
    end
    return @sprite_data
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
class SketchDrawScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    ret = @scene.pbMain
    @scene.pbEndScene
    return ret
  end
end

def pbMimikyuFaceDraw(faceIndex=0)
  pbFadeOutIn do
    setupProc = Proc.new do
      @bitmaptmp = AnimatedBitmap.new("Graphics/Faces/mimikyu")
      @bitmap = Bitmap.new(80, 80)
      @bitmap.blt(0, 0, @bitmaptmp.bitmap,
                Rect.new((faceIndex % 4) * 80, (faceIndex / 4) * 80, 80, 80))
      @sprites["mimikyu"] = Sprite.new(@viewport)
      @sprites["mimikyu"].bitmap = @bitmap
      @sprites["mimikyu"].x = 120
      @sprites["mimikyu"].y = 4
      @sprites["mimikyu"].z = 2
    end
    updateProc = Proc.new do
      pbMimikyuFace(@bitmap,@sprite_data)
      @sprites["mimikyu"].bitmap = @bitmap if @sprites["mimikyu"]
    end          
    scene = SketchDraw_Scene.new($PokemonGlobal.mimikyu_face,setupProc,updateProc)
    screen = SketchDrawScreen.new(scene)
    ret = screen.pbStartScreen
    $PokemonGlobal.mimikyu_face = ret
  end
end
