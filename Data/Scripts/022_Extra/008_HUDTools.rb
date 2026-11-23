class PokemonGlobalMetadata
  attr_reader :hud_tools
  attr_reader :inventory_tools
  attr_accessor :shooting
  attr_accessor :shielding
  
  alias _hudtools_initialize initialize
  def initialize
    _hudtools_initialize
    @hud_tools = [:brush,nil]
    @inventory_tools = Array.new(10)
    @shooting = false
    @shielding = false
  end
  
  def set_hud_tool(slot,item)
    @hud_tools[slot] = item
  end
end

def pbGivePickup(pickup)
  anim = PickupAnimation.new($game_player,sprintf("pickup_%s",pickup),Spriteset_Map.viewport)
  $scene.spriteset.addUserSprite(anim)
  $game_player.set_movement_type(:showing)
  pbMEPlay("Key item get")
  pbWait(2.0)
  anim.dispose
  case pickup
  when :key
    pbGetCurrentDungeon.keys+=1
  when :boss_key
    pbGetCurrentDungeon.boss_key = true
  when :compass
    pbGetCurrentDungeon.has_compass = true
  when :map
    pbGetCurrentDungeon.has_map = true
  end
  $game_player.set_movement_type(:walking)
end

def pbGiveTool(tool)
  tool = GameData::Tool.get(tool)
  return false if !tool
  ret = false
  index = nil
  $PokemonGlobal.hud_tools.each_with_index do |t,i|
    next if t
    index = i
    break
  end
  if index
    ret = true    
  else
    $PokemonGlobal.inventory_tools.each_with_index do |t,i|
      next if t
      index = i + 2
      break
    end
    ret = true if index
  end
  if ret
    anim = PickupAnimation.new($game_player,sprintf("pickup_%s",tool.id),Spriteset_Map.viewport)
    $scene.spriteset.addUserSprite(anim)
    $game_player.set_movement_type(:showing)
    pbMEPlay("Key item get")
    pbWait(2.0)
    anim.dispose
    if index>=2
      $PokemonGlobal.inventory_tools[index - 2] = tool.id
    else
      $PokemonGlobal.hud_tools[index] = tool.id
    end
    $game_player.set_movement_type(:walking)
  end
  return ret
end

class Game_Temp
  attr_accessor :tool_back_calling
  attr_accessor :tool_back_held
  attr_accessor :tool_use_calling
  attr_accessor :tool_use_held
  attr_accessor :paint_change_calling
end

class PickupAnimation
  def initialize(event,  filename, viewport = nil, map = nil)
    @pickup = IconSprite.new(0, 0, viewport)
    @pickup.setBitmap("Graphics/Pictures/pickups/" + filename)
    @pickup.z = 1000
    @pickup.ox = @pickup.bitmap.width / 2
    @pickup.oy = @pickup.bitmap.height / 2
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
  end

  def disposed?
    return @disposed
  end

  def dispose
    @pickup&.dispose
    @map = nil
    @pickup = nil
    @disposed = true
  end

  def update
    return if !@pickup || !@event
    @pickup.update
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @pickup.x      = ScreenPosHelper.pbScreenX(@event)
      @pickup.y      = ScreenPosHelper.pbScreenY(@event) - (Game_Map::TILE_HEIGHT)
      @pickup.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
      @pickup.zoom_y = @pickup.zoom_x
    else
      @pickup.x = @event.screen_x
      @pickup.y = @event.screen_y - (Game_Map::TILE_HEIGHT)
    end
  end
end

module GameData
  class Tool
    attr_reader :id

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @use_proc      = hash[:use_proc]
      @held_proc     = hash[:held_proc]
      @release_proc  = hash[:release_proc]
    end
    
    def call_use_proc(*args)
      return (@use_proc) ? @use_proc.call(*args) : nil
    end
    
    def call_held_proc(*args)
      return (@held_proc) ? @held_proc.call(*args) : nil
    end
    
    def call_release_proc(*args)
      return (@release_proc) ? @release_proc.call(*args) : nil
    end
  end
end
GameData::Tool.register({
  :id   => :brush,
  :use_proc => proc {
    pbPaint(0)
  },
  :held_proc => proc { |held_time|
    $game_player.animation_id = 10 if held_time > 1.0
  },
  :release_proc => proc { |held_time|
    pbPaint(1) if held_time > 1.0
  }
})

GameData::Tool.register({
  :id   => :bullet_seed,
  :use_proc => proc {
    $game_player.set_movement_type(:shooting)
  },
  :held_proc => proc { |held_time|
    $PokemonGlobal.shooting = true
    $game_player.animation_id = 10 if held_time > 0.5
  },
  :release_proc => proc { |held_time|
    seed_count = 0
    seed_count = 1 if held_time > 0.5
    seed_count += [4,((held_time - 0.5)/0.25).floor].min
    $game_player.set_movement_type(:walking_stopped)
    seed_count.times do
      pbShootBulletSeed
      pbWait(0.05)
    end
    $PokemonGlobal.shooting = false
  }
})

GameData::Tool.register({
  :id   => :protect,
  :use_proc => proc {
    $game_player.set_movement_type(:shielding)
  },
  :held_proc => proc { |held_time|
    $PokemonGlobal.shielding = true
  },
  :release_proc => proc { |held_time|
    $PokemonGlobal.shielding = false
    $game_player.set_movement_type(:walking_stopped)
  }
})