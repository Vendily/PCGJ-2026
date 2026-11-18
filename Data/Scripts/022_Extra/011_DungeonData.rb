class PokemonGlobalMetadata
  attr_reader :dungeon_data
  alias _dungeon_initialize initialize
  def initialize
    _dungeon_initialize
    @dungeon_data = {}
    GameData::Dungeon.each do |d|
      @dungeon_data[d.id] = DungeonData.new(d.id)
    end
  end
end

def pbGetCurrentDungeon
  map_metadata = $game_map.metadata
  return nil unless map_metadata
  dungeon = nil
  map_metadata.flags.each do |flag|
     next unless flag[/^Dungeon_(\w+)$/i]
     dungeon = $~[1].to_sym
     break
  end
  return nil unless dungeon
  return $PokemonGlobal.dungeon_data[dungeon]
end

class DungeonData
  attr_reader :id
  attr_accessor :keys
  attr_accessor :boss_key
  attr_accessor :defeat_miniboss
  attr_accessor :defeat_boss
  
  def initialize(id)
    @id = id
    @keys = 0
    @boss_key = false
    @defeat_miniboss = false
    @defeat_boss = false
  end

end

module GameData
  class Dungeon
    attr_reader :id
    attr_reader :map_layout

    DATA = {}

    EXIT_N = 0b0001
    EXIT_E = 0b0010
    EXIT_S = 0b0100
    EXIT_W = 0b1000
    
    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:real_name] || "Unnamed"
      @map_layout    = hash[:map_layout]
    end
    
    def name
      return _INTL(@real_name)
    end
  end
end

GameData::Dungeon.register({
  :id         => :GrassDungeon,
  :name       => _INTL("Grassy Grotto"),
  :map_layout => Array.new(8*8,15)
})