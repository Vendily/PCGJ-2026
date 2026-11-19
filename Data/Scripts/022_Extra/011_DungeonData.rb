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
  attr_accessor :has_map
  attr_accessor :has_compass
  
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
  :map_layout => [nil,nil,4,nil,nil,nil,nil,nil,
                  nil,nil,7,8,nil,nil,nil,nil,
                  nil,nil,5,nil,2,12,nil,nil,
                  nil,6,9,nil,2,15,12,nil,
                  nil,5,2,12,nil,7,13,nil,
                  nil,3,10,13,nil,7,9,nil,
                  nil,nil,2,11,14,9,nil,nil,
                  nil,nil,nil,nil,5,nil,nil,nil]
})