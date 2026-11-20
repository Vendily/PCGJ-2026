class Game_Temp
  attr_accessor :temp_invuln
  attr_accessor :boss_controller
end

class PokemonGlobalMetadata
  attr_accessor :smeargle_hp_max
  attr_accessor :smeargle_hp_current
  
  alias _oab_initialize initialize
  def initialize
    _oab_initialize
    @smeargle_hp_max = 3 * OverworldAttacks::FRACTIONS_PER_HEART
    @smeargle_hp_current = @smeargle_hp_max
  end
end

module OverworldAttacks
  INVULNERABILITY_TIME = 1.0 # seconds
  FRACTIONS_PER_HEART = 4
  module_function
  def report_player_hit(damage)
    return if $game_temp.game_over_time
    return if $PokemonGlobal.smeargle_hp_current <= 0
    return if $game_temp.temp_invuln
    return if $game_system.map_interpreter.running?
    $game_player.animation_id = 8
    $game_temp.temp_invuln = System.uptime
    $PokemonGlobal.smeargle_hp_current -= damage
    if $PokemonGlobal.smeargle_hp_current <= 0
      $PokemonGlobal.smeargle_hp_current = 0
      pbBGMFade(1.0)
      pbBGSFade(1.0)
      pbStartOver
    end
  end
  
  def report_player_attack(event,weapon)
    if $game_temp.boss_controller&.check_player_attack?(event)
      $game_temp.boss_controller.register_hit(event,weapon)
    else
      #nop
    end
  end
  def is_valid_weapon_target?(event)
    return false unless event
    return event.name[/enemy/i]||event.name[/boss/i]
  end
end
module BossController
  def self.report_defeat(boss_id,mini=false)
    dungeon_data = pbGetCurrentDungeon
    return unless dungeon_data
    if mini
      dungeon_data.defeat_miniboss = true
    else
      dungeon_data.defeat_boss = true
    end
    $game_map.need_refresh = true
  end
end

def boss_defeated?
  return pbGetCurrentDungeon&.defeat_boss
end

def miniboss_defeated?
  return pbGetCurrentDungeon&.defeat_miniboss
end

def pbGetEventAtCoordinate(x,y,include_player=false,ignoreInterpreter=false)
  return nil if $game_system.map_interpreter.running? && !ignoreInterpreter
  return nil if !$game_map.valid?(x,y)
  if include_player
    return $game_player if $game_player.x == x && $game_player.y == y
  end
  for event in $game_map.events.values
    next if !event.at_coordinate?(x,y)
    next if event.character_name == ""
    next if event.jumping?
    return event
  end
  return nil
end

class MinccinoMiniBoss
  HP = 2 * OverworldAttacks::FRACTIONS_PER_HEART
  
  JUMP_POINTS = [[28,1,2],[29,1,2],[30,1,2],[31,1,2],
                 [25,3,6],[25,4,6],[25,5,6],
                 [34,3,4],[34,4,4],[34,5,4]
                ]
  
  def initialize(minccino)
    @boss_id = :Minccino
    @event_minccino = minccino
    @event_minccino.lock_pattern = true
    @event_minccino.direction_fix = true
    @hp_minccino = HP
    
    @phase = :shooting
    @jump_target = nil
    
    @action_timer = 2.0
    @attacks = 0
  end
  
  def check_player_attack?(event)
    return event == @event_minccino
  end
  
  def register_hit(event,weapon)
    damage = case weapon
             when :bullet_seed then 1
             else 0
             end
    if damage > 0
      @hp_minccino -= damage
      @event_minccino.animation_id = 9
      if @hp_minccino<=0
        @phase = :dead
      end
    end
    if @phase == :dead
      report_defeat
    end
  end
  
  def update
    time_now = System.uptime
    @last_update_time = time_now if !@last_update_time || @last_update_time > time_now
    delta_t = time_now - @last_update_time
    if @phase == :shooting
      @action_timer -= delta_t
      if @action_timer<=0.0
        @phase = :jumping
        @jump_target = JUMP_POINTS.sample
        @action_timer = 1.0
      end
      if @attacks<5 && (!@last_attack_time || (@last_attack_time - @action_timer).abs > 1.0)  && @hp_minccino>0
        @attacks += 1
        @last_attack_time = @action_timer
        seed_data = [@event_minccino.x,@event_minccino.y,@event_minccino.direction]
        $scene.spriteset.addUserSprite(BulletSeedSprite.new(@event_minccino,seed_data,$game_map,Spriteset_Map.viewport))
      end
    elsif @phase == :jumping
      @action_timer -= delta_t
      if @action_timer<=0.0 && !@event_minccino.jumping?
        @phase = :shooting
        @action_timer = 6.0
        @last_attack_time = nil
        @made_attack = false
        @finished_attack = false
        @attacks = 0
      end
      if @jump_target
        @event_minccino.direction = @jump_target[2]
        x_diff,y_diff = $map_factory.getThisAndOtherPosRelativePos(@event_minccino,@event_minccino.map_id,@jump_target[0],@jump_target[1])
        @event_minccino.jump(x_diff,y_diff)
        @jump_target = nil
      end
    end
    @last_update_time = time_now
  end
  
  def report_defeat
    BossController.report_defeat(@boss_id,true)
  end
end

class RosaradeBoss
  HAND_HP = 3 * OverworldAttacks::FRACTIONS_PER_HEART
  HEAD_HP = 6 * OverworldAttacks::FRACTIONS_PER_HEART
  
  VULNERABLE_TIME = 5.0
  
  TIME_BETWEEN_ATTACKS = 6.0
  
  def initialize(head,left_arm,right_arm)
    @boss_id = :Rosarade
    @event_head = head
    @event_head.lock_pattern = true
    @event_arm_left = left_arm
    @event_arm_left.lock_pattern = true
    @event_arm_left.moveto(1,2)
    @event_arm_right = right_arm
    @event_arm_right.lock_pattern = true
    @event_arm_right.moveto(7,2)

    @hp_head = HEAD_HP
    @hp_arm_left = HAND_HP
    @hp_arm_right = HAND_HP
    @vulnerable_hits = 0
    
    @phase = :hand_attack
    @action = :none
    @action_timer = 3.0
    @made_attack = false
    @made_warning = false
    @finished_attack = false
  end
  
  def check_player_attack?(event)
    return [@event_head,@event_arm_left,@event_arm_right].any?(event)
  end
  
  def register_hit(event,weapon)
    damage = case weapon
             when :brush then 4
             when :bullet_seed then 1
             else 0
             end
    if event == @event_head
      return if @phase != :vulnerable
      @hp_head -= damage
      @event_head.animation_id = 9
      if @hp_head<=0
        @phase = :dead
      end
    elsif event == @event_arm_left
      if @hp_arm_left>0
        @hp_arm_left-=damage
        @event_arm_left.animation_id = 9
        if @hp_arm_left <=0
          @event_arm_left.pattern = 1
          x_diff,y_diff = $map_factory.getThisAndOtherPosRelativePos(@event_arm_left,@event_arm_left.map_id,1,2)
          @event_arm_left.jump(x_diff,y_diff)
        end
      end
    elsif event == @event_arm_right
      if @hp_arm_right>0
        @hp_arm_right-=damage
        @event_arm_right.animation_id = 9
        if @hp_arm_right <=0
          @event_arm_right.pattern = 1
          x_diff,y_diff = $map_factory.getThisAndOtherPosRelativePos(@event_arm_right,@event_arm_right.map_id,7,2)
          @event_arm_right.jump(x_diff,y_diff)
        end
      end
    end
    if @hp_arm_left <=0 && @hp_arm_right <=0 && @phase == :hand_attack
      @phase = :vulnerable
      @event_head.pattern = 0
      @action_timer = VULNERABLE_TIME
    end
    if @phase == :dead
      report_defeat
    end
  end
  
  def update
    time_now = System.uptime
    @last_update_time = time_now if !@last_update_time || @last_update_time > time_now
    delta_t = time_now - @last_update_time
    if (!@event_arm_left.jumping? && @event_arm_left.at_coordinate?($game_player.x,$game_player.y) ) ||
       (!@event_arm_right.jumping? && @event_arm_right.at_coordinate?($game_player.x,$game_player.y))
       OverworldAttacks.report_player_hit(4)
    end
    if @phase == :hand_attack
      @action_timer -= delta_t
      if @action_timer<=0.0
        @action = (rand(2) == 0)? :attack_left : :attack_right
        @action = :attack_left if @action == :attack_right && @hp_arm_right <=0
        @action = :attack_right if @action == :attack_left && @hp_arm_left <=0
        @action_timer = TIME_BETWEEN_ATTACKS
        @made_attack = false
        @made_warning = false
        @finished_attack = false
      end
      event = nil
      if @action == :attack_left
        event = @event_arm_left
        hp = @hp_arm_left
      elsif @action == :attack_right
        event = @event_arm_right
        hp = @hp_arm_right
      end
      if !event.nil?
        if !@made_warning
          event.animation_id = 10
          @made_warning = true
        else
          if !@made_attack && @action_timer < TIME_BETWEEN_ATTACKS - 1.0 && hp>0
            x_diff,y_diff = $map_factory.getThisAndOtherEventRelativePos(event,$game_player)
            x_diff -= rand(2)
            y_diff += rand(2)
            event.jump(x_diff,y_diff)
            @made_attack = true
          elsif !@finished_attack  && !event.jumping? && event.at_coordinate?($game_player.x,$game_player.y)
            # finished jump, landed on player
            OverworldAttacks.report_player_hit(4)
            @finished_attack = true
          end
        end
      end
    elsif @phase == :vulnerable
      @action_timer -= delta_t
      if @action_timer<=0.0
        @phase = :hand_attack
        @action_timer = 0.0
        @vulnerable_hits = 0
        @hp_arm_left = HAND_HP
        @event_arm_left.pattern = 0
        @hp_arm_right = HAND_HP
        @event_arm_right.pattern = 0
        @event_head.pattern = 1
      end
    end
    @last_update_time = time_now
  end
  
  def report_defeat
    BossController.report_defeat(@boss_id)
    pbWait(2.0) do |delta|
      opacity = lerp(255,0,2.0,delta)
      @event_head.opacity = opacity
      @event_arm_left.opacity = opacity
      @event_arm_right.opacity = opacity
    end
  end
end

EventHandlers.add(:on_frame_update, :invuln_timer,
  proc {
    next if !$game_temp.temp_invuln
    if (System.uptime - $game_temp.temp_invuln)>OverworldAttacks::INVULNERABILITY_TIME
      $game_temp.temp_invuln = nil
    end
  }
)

EventHandlers.add(:on_frame_update, :boss_update,
  proc {
    $game_temp.boss_controller&.update
  }
)