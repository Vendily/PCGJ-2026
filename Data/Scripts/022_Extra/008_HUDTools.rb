class PokemonGlobalMetadata
  attr_reader :hud_tools
  attr_reader :inventory_tools
  attr_accessor :shooting
  attr_accessor :shielding
  
  alias _hudtools_initialize initialize
  def initialize
    _hudtools_initialize
    @hud_tools = [:brush,:protect]
    @inventory_tools = Array.new(10)
    @shooting = false
    @shielding = false
  end
  
  def set_hud_tool(slot,item)
    @hud_tools[slot] = item
  end
end

class Game_Temp
  attr_accessor :tool_back_calling
  attr_accessor :tool_back_held
  attr_accessor :tool_use_calling
  attr_accessor :tool_use_held
  attr_accessor :paint_change_calling
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