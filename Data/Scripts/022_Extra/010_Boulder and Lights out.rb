class Interpreter
  def pbToggleSelfSwitch(event,swtch,mapid=-1)
    mapid = @map_id if mapid<0
    $game_self_switches[[mapid,event,swtch]] = !$game_self_switches[[mapid,event,swtch]]
    if $map_factory.hasMap?(mapid)
      $map_factory.getMap(mapid, false).need_refresh = true
    end
  end
end

def lo_switch_toggle(*event_ids)
  event_ids.each do |id|
    pbToggleSelfSwitch(id,"A")
  end
end

def lo_check_puzzle(solution,*event_ids)
  raise "mismatch in events and solution length" if solution.length != event_ids.length
  solved = true
  solution.each_char.with_index do |s,i|
    e = $game_map.events[event_ids[i]]
    case s
    when "0"
      if e.isOn?("A")
        solved = false
        break
      end
    when "1"
      if e.isOff?("A")
        solved = false
        break
      end
    end
  end
  return solved
end

def check_boulder_puzzle(event_ids, *button_pos)
  used_buttons = []
  event_ids.each do |id|
    event = $game_map.events[id]
    next if !event
    button_pos.each_with_index do |button, idx|
      next if used_buttons.include?(idx)
      next unless event.x == button[0] && event.y == button[1]
      used_buttons.push(idx)
    end
  end
  return used_buttons.length == button_pos.length
end