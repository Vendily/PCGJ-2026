class BulletSeedSprite
  MOVE_TIME = 0.1
  SEED_IMPACT_WAIT = 0.25
  def initialize(owner,seed_data,map,viewport=nil)
    @owner = owner
    @start_x,@start_y,@direction = seed_data
    @map = map
    @real_x = @start_x * Game_Map::REAL_RES_X
    @real_y = @start_y * Game_Map::REAL_RES_Y
    
    @dx = 0
    @dy = 0
    
    case @direction
    when 2
      @dy = 1
    when 4
      @dx = -1
    when 6
      @dx = 1
    when 8
      @dy = -1
    end
    @seed = IconSprite.new(0,0,viewport)
    @seed.ox=8
    @seed.oy=24
    @seed.setBitmap("Graphics/Pictures/tool_sprites/bullet_seed")
    @seed.x = self.screen_x
    @seed.y = self.screen_y
    @seed.z = self.screen_y_ground
    @disposed=false
    
    @phase=0
    @timer=0
    @event=nil
  end

  def disposed?
    return @disposed
  end

  def dispose
    @seed.dispose
    @map=nil
    @disposed=true
  end

  def screen_x
    ret = ((@real_x - @map.display_x) / Game_Map::X_SUBPIXELS).round
    ret += 1 * Game_Map::TILE_WIDTH / 2
    return ret
  end
  
  def screen_y_ground
    ret = ((@real_y - @map.display_y) / Game_Map::Y_SUBPIXELS).round
    ret += Game_Map::TILE_HEIGHT
    return ret
  end
  
  def screen_y
    ret = self.screen_y_ground
    return ret
  end
  
  def update
    return if !@seed || @disposed
    time_now = System.uptime
    @last_update_time = time_now if !@last_update_time || @last_update_time > time_now
    @delta_t = time_now - @last_update_time
    @seed.update
    case @phase
    when 0 # flying to landing point
      @timer += @delta_t
      # Move horizontally
      end_x = (@start_x + @dx)
      end_y = (@start_y + @dy)
      if @dx != 0
        @real_x = lerp(@start_x, end_x, MOVE_TIME, @timer) * Game_Map::REAL_RES_X
      end
      # Move vertically
      if @dy != 0
        @real_y = lerp(@start_y, end_y, MOVE_TIME, @timer) * Game_Map::REAL_RES_Y
      end
      # Snap to end position if close enough
      @real_x = end_x * Game_Map::REAL_RES_X if (@real_x - (end_x * Game_Map::REAL_RES_X)).abs < Game_Map::X_SUBPIXELS / 2
      @real_y = end_y * Game_Map::REAL_RES_Y if (@real_y - (end_y * Game_Map::REAL_RES_Y)).abs < Game_Map::Y_SUBPIXELS / 2
      # End of move
      if @real_x == end_x * Game_Map::REAL_RES_X && @real_y == end_y * Game_Map::REAL_RES_Y
        @timer = 0
        @start_x = end_x
        @start_y = end_y
        passable = $game_map.passable?(end_x,end_y,0,@owner)
        passable = true if $game_map.terrain_tag(end_x,end_y).can_shoot_over
        e = pbGetEventAtCoordinate(end_x,end_y,true)
        passable = false if e == $game_player || OverworldAttacks.is_valid_weapon_target?(e)
        @phase = 1 if !passable
      end
    when 1
      @phase=2
      if @owner == $game_player
        @event = pbGetEventAtCoordinate(@start_x,@start_y)
        if OverworldAttacks.is_valid_weapon_target?(@event)
          OverworldAttacks.report_player_attack(@event,:bullet_seed)
        end
      else # enemy using seeds
        if $game_player.x == @start_x && $game_player.y == @start_y
          if $PokemonGlobal.shielding && $game_player.direction == (10-@direction)
            @phase=3
            seed_data = [$game_player.x,$game_player.y,$game_player.direction]
            $scene.spriteset.addUserSprite(BulletSeedSprite.new($game_player,seed_data,$game_map,Spriteset_Map.viewport))
          else
            OverworldAttacks.report_player_hit(1)
          end
        end
      end
    when 2
      @timer+=@delta_t
      @phase=3 if @timer>=SEED_IMPACT_WAIT
    when 3
      self.dispose
      return
    end
    @seed.x = self.screen_x
    @seed.y = self.screen_y
    @seed.zoom_x = 1.0
    @seed.zoom_y = @seed.zoom_x
    pbDayNightTint(@seed)
    @last_update_time = time_now
  end
end

def pbShootBulletSeed
  seed_data = [$game_player.x,$game_player.y,$game_player.direction]
  $scene.spriteset.addUserSprite(BulletSeedSprite.new($game_player,seed_data,$game_map,Spriteset_Map.viewport))
end