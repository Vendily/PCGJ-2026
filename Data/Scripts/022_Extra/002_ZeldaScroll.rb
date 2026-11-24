module Settings
  ZELDA_SCROLL_DURATION = 0.5
  ZELDA_SCREEN_WIDTH = Settings::SCREEN_WIDTH
  ZELDA_SCREEN_HEIGHT = Settings::SCREEN_HEIGHT - Game_Map::TILE_HEIGHT
end

class Game_Temp
  attr_accessor :scrolling_map_transition
  attr_accessor :scrolling_map_start
  attr_accessor :scrolling_map_screen_xy
end

class Game_Player
  # Set Map Display Position to Center of Screen
  def center(x, y)
    self.map.display_x = x * Game_Map::REAL_RES_X - (x * Game_Map::REAL_RES_X % (Settings::ZELDA_SCREEN_WIDTH * Game_Map::X_SUBPIXELS))
    self.map.display_y = y * Game_Map::REAL_RES_Y - (y * Game_Map::REAL_RES_Y % (Settings::ZELDA_SCREEN_HEIGHT * Game_Map::Y_SUBPIXELS))
  end
  # Track the player on-screen as they move.
  def update_screen_position(last_real_x, last_real_y)
    intended_screen_x = @x * Game_Map::REAL_RES_X - (@x * Game_Map::REAL_RES_X % (Settings::ZELDA_SCREEN_WIDTH * Game_Map::X_SUBPIXELS))
    intended_screen_y = @y * Game_Map::REAL_RES_Y - (@y * Game_Map::REAL_RES_Y % (Settings::ZELDA_SCREEN_HEIGHT * Game_Map::Y_SUBPIXELS))
    if !$game_temp.scrolling_map_transition
      last_screen_x = last_real_x - (last_real_x % (Settings::ZELDA_SCREEN_WIDTH * Game_Map::X_SUBPIXELS))
      last_screen_y = last_real_y - (last_real_y % (Settings::ZELDA_SCREEN_HEIGHT * Game_Map::Y_SUBPIXELS))
      if moving? && (last_screen_x != intended_screen_x || last_screen_y != intended_screen_y)
        $game_temp.scrolling_map_transition = true
        $game_temp.scrolling_map_start = System.uptime
        $game_temp.scrolling_map_screen_xy = [last_screen_x,last_screen_y]
        EventHandlers.trigger(:on_screen_change,last_screen_x,last_screen_y,intended_screen_x,intended_screen_y,true)
      else
        self.map.display_x = @real_x - (@real_x %  (Settings::ZELDA_SCREEN_WIDTH * Game_Map::X_SUBPIXELS))
        self.map.display_y = @real_y - (@real_y %  (Settings::ZELDA_SCREEN_HEIGHT * Game_Map::Y_SUBPIXELS))
      end
    else
      last_screen_x, last_screen_y = $game_temp.scrolling_map_screen_xy
      now = System.uptime
      self.map.display_x = lerp(last_screen_x, intended_screen_x, Settings::ZELDA_SCROLL_DURATION, $game_temp.scrolling_map_start, now)
      self.map.display_y = lerp(last_screen_y, intended_screen_y, Settings::ZELDA_SCROLL_DURATION, $game_temp.scrolling_map_start, now)
    end
  end
  
  alias _zs_update_command_new update_command_new
  def update_command_new
    if $game_temp.scrolling_map_transition
      if (System.uptime - $game_temp.scrolling_map_start) >= Settings::ZELDA_SCROLL_DURATION
        intended_screen_x = @x * Game_Map::REAL_RES_X - (@x * Game_Map::REAL_RES_X % (Settings::ZELDA_SCREEN_WIDTH * Game_Map::X_SUBPIXELS))
        intended_screen_y = @y * Game_Map::REAL_RES_Y - (@y * Game_Map::REAL_RES_Y % (Settings::ZELDA_SCREEN_HEIGHT * Game_Map::Y_SUBPIXELS))
        last_screen_x, last_screen_y = $game_temp.scrolling_map_screen_xy
        EventHandlers.trigger(:on_screen_change,last_screen_x,last_screen_y,intended_screen_x,intended_screen_y,false)
        $game_temp.scrolling_map_transition = false
        $game_temp.scrolling_map_start = nil
        $game_temp.scrolling_map_screen_xy = nil
      end
      return
    end
    _zs_update_command_new
  end
  
  alias _zs_update_event_triggering update_event_triggering
  def update_event_triggering
    return if $game_temp.scrolling_map_transition
    _zs_update_event_triggering
  end
end