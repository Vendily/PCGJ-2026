module Settings
  SMEARGLE_PAINT_COLORS = [
    [[252,250,252],[170,170,170],[85,85,85],[4,2,4]], # the default gray
    [[252,250,252],[236,138,140],[172,38,36],[4,2,4]], # RED 
    [[252,250,252],[4,250,4],[76,138,4],[4,2,4]], # GREEN 
    [[252,250,252],[124,170,252],[4,50,252],[4,2,4]], # BLUE 
    [[252,250,252],[244,254,4],[132,66,4],[4,2,4]] # YELLOW 
  ]
  SMEARGLE_PAINT_L_TO_R = 4
  SMEARGLE_PAINT_R_TO_L = 5
  SMEARGLE_PAINT_U_TO_D = 6
  SMEARGLE_PAINT_SMALL  = 7
  
  SMEARGLE_PAINT_SEPIA_SWITCH = 100
  SMEARGLE_PAINT_HOLD_TIME = 1.5 #seconds
end

class PokemonGlobalMetadata
  attr_accessor :painted_tiles
  attr_accessor :painted_events
  attr_accessor :painted_faces
  attr_accessor :unlocked_colors
  attr_accessor :current_paint_color
  
  alias _paint_initialize initialize
  def initialize
    _paint_initialize
    @painted_tiles = {}
    @painted_events = {}
    @painted_faces = {}
    @unlocked_colors = [1,2,3,4]
    @current_paint_color = 1
  end
end

module PaintedBitmaps
  module_function
  def paint_bitmap(raw_data,palette)
    if $game_switches[Settings::SMEARGLE_PAINT_SEPIA_SWITCH]
      palette = [[252,234,228],[196,174,148],[148,122,76],[76,42,4]]
    end
    raw_data.map!.with_index do |b,i|
      c = i % 4
      if c == 3 # don't touch alpha
        next b
      end
      case b
      when 255 
        next palette[0][c]
      when 170
        next palette[1][c]
      when 85
        next palette[2][c]
      when 0
        next palette[3][c]
      else
        next b # passthrough
     end
    end
    return raw_data.pack("C*")
  end
end

def pbPaintTile(c,x,y,map = nil)
  map = $game_map.map_id unless map
  $PokemonGlobal.painted_tiles[[map,x,y]] = c
end

def pbPaintEvent(c,event,small_brush)
  if OverworldAttacks.is_valid_weapon_target?(event)
    OverworldAttacks.report_player_attack(event,:brush)
  end
  return if event.name[/nopaint/i]
  $PokemonGlobal.painted_events[[event.map_id,event.id]] = c
  if event.name[/face\((\w+)\)/i]
    face = $~[1].to_s
    $PokemonGlobal.painted_faces[face] = c
  end
  if !small_brush && event.name[/brushpush/i]
    old_x  = event.x
    old_y  = event.y
    dir = case $game_player.direction
    when 2 then 4
    when 4,6 then 2
    when 8 then 6
    end
    # Apply strict version of passable, which treats tiles that are passable
    # only from certain directions as fully impassible
    return if !event.can_move_in_direction?(dir, true)
    case $game_player.direction
    when 2 then event.move_left
    when 4,6 then event.move_up
    when 8 then event.move_right
    end
    $PokemonMap&.addMovedEvent(event.id)
    if old_x != event.x || old_y != event.y
      loop do
        Graphics.update
        Input.update
        pbUpdateSceneMap
        break if !event.moving?
      end
    end
  end
end

def pbPaintAnimation(small = false)
  $game_player.set_movement_type(:swiping)
  $game_player.lock_pattern = true
  offset = small ? 2 : 0
  4.times do |pattern|
    yield if block_given? && pattern == 2
    $game_player.pattern = [(pattern + offset),3].min
    pbWait(0.05)
  end
  $game_player.set_movement_type(:walking_stopped)
  $game_player.pattern = 0
  $game_player.lock_pattern = false
  $game_player.straighten
end

def pbPaint(mode)
  small_brush = mode == 0
  anim = case $game_player.direction
         when 2 then Settings::SMEARGLE_PAINT_R_TO_L
         when 8 then Settings::SMEARGLE_PAINT_L_TO_R
         when 4,6 then Settings::SMEARGLE_PAINT_U_TO_D
         end
  anim = Settings::SMEARGLE_PAINT_SMALL if small_brush
  c = $PokemonGlobal.current_paint_color
  tile_x,tile_y = $map_factory.getFacingCoords($game_player.x, $game_player.y, $game_player.direction)
  tiles_painted,events_painted = get_affected_paint_coords(small_brush)
  pbPaintAnimation(small_brush) do 
    $scene.spriteset.addUserAnimation(anim, tile_x, tile_y, true, 1)
    tiles_painted.each {|t| pbPaintTile(c,t[0],t[1])}
    events_painted.each {|e| pbPaintEvent(c,$game_map.events[e],small_brush)}
  end
  
end

def get_affected_paint_coords(small = false)
  tiles = []
  tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, $game_player.direction))
  if !small
    case $game_player.direction
    when 2
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 1))
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 3))
    when 4
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 7))
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 1))
    when 6
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 9))
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 3))
    when 8
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 7))
      tiles.push($map_factory.getFacingCoords($game_player.x, $game_player.y, 9))
    end
  end
  tiles.select!{|t| $game_map.valid?(t[0],t[1]) && [2,1,0].any?{|l| $game_map.data[t[0],t[1], l] != 0}}
  events = []
  $game_map.events.each_value do |event|
    next if event.jumping? #|| event.over_trigger?
    if tiles.any?{|t| event.at_coordinate?(t[0],t[1])}
      events.push(event.id)
    end
  end
  events.uniq!
  return [tiles,events]
end

def pbChangePaint
  return if $PokemonGlobal.unlocked_colors.length<=1
  $PokemonGlobal.unlocked_colors.push($PokemonGlobal.unlocked_colors.shift)
  $PokemonGlobal.current_paint_color = $PokemonGlobal.unlocked_colors[0]
end

def pbApplyFacePaint(bitmap,face)
  if face == "smeargle"
    c = $PokemonGlobal.current_paint_color
    palette = [[252,250,252],[236,154,84],[132,66,4],[4,2,4]]
    palette[1] = Settings::SMEARGLE_PAINT_COLORS[c][1]
  else
    c = $PokemonGlobal.painted_faces[face]
    return unless c
    palette = Settings::SMEARGLE_PAINT_COLORS[c]
  end
  rawdata = bitmap.raw_data.bytes
  bitmap.raw_data = PaintedBitmaps.paint_bitmap(rawdata,palette)
end