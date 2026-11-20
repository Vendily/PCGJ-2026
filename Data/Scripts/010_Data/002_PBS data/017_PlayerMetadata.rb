module GameData
  class PlayerMetadata
    attr_reader :id
    attr_reader :trainer_type
    attr_reader :walk_charset
    attr_reader :home
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "player_metadata.dat"

    SCHEMA = {
      "SectionName"     => [:id,                "u"],
      "TrainerType"     => [:trainer_type,      "e", :TrainerType],
      "WalkCharset"     => [:walk_charset,      "s"],
      "RunCharset"      => [:run_charset,       "s"],
      "CycleCharset"    => [:cycle_charset,     "s"],
      "SurfCharset"     => [:surf_charset,      "s"],
      "DiveCharset"     => [:dive_charset,      "s"],
      "FishCharset"     => [:fish_charset,      "s"],
      "SurfFishCharset" => [:surf_fish_charset, "s"],
      "SwipeCharset"    => [:swipe_charset,     "s"],
      "ShootCharset"    => [:shoot_charset,     "s"],
      "DeadCharset"     => [:dead_charset,      "s"],
      "ShieldCharset"   => [:shield_charset,    "s"],
      "ShowCharset"     => [:show_charset,      "s"],
      "Home"            => [:home,              "vuuu"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["ID",              ReadOnlyProperty,        _INTL("ID number of this player.")],
        ["TrainerType",     TrainerTypeProperty,     _INTL("Trainer type of this player.")],
        ["WalkCharset",     CharacterProperty,       _INTL("Charset used while the player is still or walking.")],
        ["RunCharset",      CharacterProperty,       _INTL("Charset used while the player is running. Uses WalkCharset if undefined.")],
        ["CycleCharset",    CharacterProperty,       _INTL("Charset used while the player is cycling. Uses RunCharset if undefined.")],
        ["SurfCharset",     CharacterProperty,       _INTL("Charset used while the player is surfing. Uses CycleCharset if undefined.")],
        ["DiveCharset",     CharacterProperty,       _INTL("Charset used while the player is diving. Uses SurfCharset if undefined.")],
        ["FishCharset",     CharacterProperty,       _INTL("Charset used while the player is fishing. Uses WalkCharset if undefined.")],
        ["SurfFishCharset", CharacterProperty,       _INTL("Charset used while the player is fishing while surfing. Uses FishCharset if undefined.")],
        ["SwipeCharset",    CharacterProperty,       _INTL("Charset used while the player is swinging their paint brush. Uses WalkCharset if undefined.")],
        ["ShootCharset",    CharacterProperty,       _INTL("Charset used while the player is shooting. Uses WalkCharset if undefined.")],
        ["DeadCharset",     CharacterProperty,       _INTL("Charset used while the player dies. Uses WalkCharset if undefined.")],
        ["ShieldCharset",   CharacterProperty,       _INTL("Charset used while the player is shielding. Uses WalkCharset if undefined.")],
        ["ShowCharset",     CharacterProperty,       _INTL("Charset used while the player is showing a pickup. Uses WalkCharset if undefined.")],
        ["Home",            MapCoordsFacingProperty, _INTL("Map ID and X/Y coordinates of where the player goes after a loss if no Pokémon Center was visited.")]
      ]
    end

    # @param player_id [Integer]
    # @return [self, nil]
    def self.get(player_id = 1)
      validate player_id => Integer
      return self::DATA[player_id] if self::DATA.has_key?(player_id)
      return self::DATA[1]
    end

    def initialize(hash)
      @id                = hash[:id]
      @trainer_type      = hash[:trainer_type]
      @walk_charset      = hash[:walk_charset]
      @run_charset       = hash[:run_charset]
      @cycle_charset     = hash[:cycle_charset]
      @surf_charset      = hash[:surf_charset]
      @dive_charset      = hash[:dive_charset]
      @fish_charset      = hash[:fish_charset]
      @surf_fish_charset = hash[:surf_fish_charset]
      @swipe_charset     = hash[:swipe_charset]
      @shoot_charset     = hash[:shoot_charset]
      @dead_charset      = hash[:dead_charset]
      @shield_charset    = hash[:shield_charset]
      @show_charset      = hash[:show_charset]
      @home              = hash[:home]
      @pbs_file_suffix   = hash[:pbs_file_suffix] || ""
    end

    def run_charset
      return @run_charset || @walk_charset
    end

    def cycle_charset
      return @cycle_charset || run_charset
    end

    def surf_charset
      return @surf_charset || cycle_charset
    end

    def dive_charset
      return @dive_charset || surf_charset
    end

    def fish_charset
      return @fish_charset || @walk_charset
    end

    def surf_fish_charset
      return @surf_fish_charset || fish_charset
    end
    
    def swipe_charset
      return @swipe_charset || @walk_charset
    end
    
    def shoot_charset
      return @shoot_charset || @walk_charset
    end
    
    def dead_charset
      return @dead_charset || @walk_charset
    end

    def shield_charset
      return @shield_charset || @walk_charset
    end
    
    def show_charset
      return @show_charset || @walk_charset
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      return __orig__get_property_for_PBS(key)
    end
  end
end
