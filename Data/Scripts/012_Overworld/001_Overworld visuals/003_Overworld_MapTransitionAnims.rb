#===============================================================================
# Entering/exiting cave animations
#===============================================================================
def pbCaveEntranceEx(exiting)
  # Create bitmap
  sprite = BitmapSprite.new(Graphics.width, Graphics.height)
  sprite.z = 100000
  # Define values used for the animation
  duration = 0.4
  totalBands = 15
  bandheight = ((Graphics.height / 2.0) - 10) / totalBands
  bandwidth  = ((Graphics.width / 2.0) - 12) / totalBands
  start_gray = (exiting) ? 0 : 255
  end_gray = (exiting) ? 255 : 0
  # Create initial array of band colors (black if exiting, white if entering)
  grays = Array.new(totalBands) { |i| start_gray }
  # Animate bands changing color
  timer_start = System.uptime
  until System.uptime - timer_start >= duration
    x = 0
    y = 0
    # Calculate color of each band
    totalBands.times do |k|
      grays[k] = lerp(start_gray, end_gray, duration, timer_start + (k * duration / totalBands), System.uptime)
    end
    # Draw gray rectangles
    rectwidth  = Graphics.width
    rectheight = Graphics.height
    totalBands.times do |i|
      currentGray = grays[i]
      sprite.bitmap.fill_rect(Rect.new(x, y, rectwidth, rectheight),
                              Color.new(currentGray, currentGray, currentGray))
      x += bandwidth
      y += bandheight
      rectwidth  -= bandwidth * 2
      rectheight -= bandheight * 2
    end
    Graphics.update
    Input.update
  end
  # Set the tone at end of band animation
  if exiting
    pbToneChangeAll(Tone.new(255, 255, 255), 0)
  else
    pbToneChangeAll(Tone.new(-255, -255, -255), 0)
  end
  # Animate fade to white (if exiting) or black (if entering)
  timer_start = System.uptime
  loop do
    sprite.color = Color.new(end_gray, end_gray, end_gray,
                             lerp(0, 255, duration, timer_start, System.uptime))
    Graphics.update
    Input.update
    break if sprite.color.alpha >= 255
  end
  # Set the tone at end of fading animation
  pbToneChangeAll(Tone.new(0, 0, 0), 8)
  # Pause briefly
  timer_start = System.uptime
  until System.uptime - timer_start >= 0.1
    Graphics.update
    Input.update
  end
  sprite.dispose
end

def pbCaveEntrance
  pbSetEscapePoint
  pbCaveEntranceEx(false)
end

def pbCaveExit
  pbEraseEscapePoint
  pbCaveEntranceEx(true)
end

#===============================================================================
# Blacking out animation
#===============================================================================
def pbStartOver(gameover = false)
  $stats.blacked_out_count += 1
  $game_temp.game_over_time = System.uptime
  $game_temp.boss_controller = nil
  $game_player.set_movement_type(:walking_stopped)
  $game_player.lock_pattern = true
  $game_player.pattern = 0
  turns = 8
  case $game_player.direction
  when 2
    turns += 4
  when 4
    turns += 3
  when 6
    turns += 1
  when 8
    turns += 2
  end
  turns.times do |pattern|
    $game_player.turn_right_90
    pbWait(0.1)
  end
  $game_player.set_movement_type(:dead)
  $game_player.pattern = 0
  $game_player.lock_pattern = false
  until System.uptime - $game_temp.game_over_time >= 2.5
    Graphics.update
    Input.update
  end
  $PokemonGlobal.smeargle_hp_current = 3 * OverworldAttacks::FRACTIONS_PER_HEART
  commands = [_INTL("CONTINUE"),_INTL("SAVE AND QUIT")]
  cmd = pbMessage(_INTL("\\l[1]<ac>GAME OVER</ac>"),commands)
  if cmd == 0
    pbRespawnPoint
  else
    Game.save
    $game_temp.game_over_time = nil
    $game_temp.title_screen_calling = true
    #$scene = nil
  end
end

def pbRespawnPoint
  pbFadeOutIn {
    $game_temp.player_new_map_id    = $data_system.start_map_id
    $game_temp.player_new_x         = $data_system.start_x
    $game_temp.player_new_y         = $data_system.start_y 
    $game_temp.player_new_direction = 2
    pbDismountBike
    $game_temp.game_over_time = nil
    $scene.transfer_player if $scene.is_a?(Scene_Map)
    $game_map.events.each_value {|e| e.tempSwitches.clear} # reset temp switches
    $game_map.refresh
  }
end
class Game_Temp
  attr_accessor :game_over_time
end