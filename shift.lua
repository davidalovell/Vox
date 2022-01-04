-- TSNM script

-- aliases
s = sequins

-- init values
octave = -2
refresh_rate = 1/64

enabled = true
enabled_settting = false
--




-- ii getters and event handlers
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

function get_txi()
  for i = 1, 4 do
    ii.txi.get('param', i)
    ii.txi.get('in', i)
  end
end

ii.txi.event = function(e, val)
  txi[e.name == 'in' and 'input' or e.name][e.arg] = val
end
--




-- helper functions
function clamp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function linlin(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( linlin( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end
--




-- shift register
shift_register = {0,0,0,0,0,0,0,0}

function add_to_shift(shift_register, val)
  val = round(val * 12)
  table.insert(shift_register, 1, val)
  table.remove(shift_register, #shift_register)
end
--




-- scale functions
scale = {0}

function add_to_scale(scale, val)
  val = round(val * 12) % 12
  local val_is_duplicate
  for k, v in ipairs(scale) do
    if val == v then val_is_duplicate = true end
  end
  if not val_is_duplicate then
    table.insert(scale, val)
  end
  table.sort(scale)
end

function reset_scale(scale)
  scale = {0}
end
--







function init()
  get_txi()

  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  output[1]:clock(1)
  
  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = lead
  }
end




lead = function()
  clock.run(
    function()
      clock.sync(refresh_rate)

      local val = input[1].volts
      add_to_shift(shift_register, val)
      add_to_scale(scale, val)

      -- ii.wsyn.play_note(scale[(shift_register[1] + (seq() - 1)) % #scale + 1] / 12 + 1, 1)
      ii.jf.play_note(shift_register[1]/12 + octave, 2)
      clock.sync(1/(math.random(1,2)*12))
      ii.jf.play_note(shift_register[2]/12 + octave, 2)
    end
  )
end



main = {
  enabled_settting = false,
  reset_setting = false
}

main.clock = clock.run(
  function()
    while true do
      clock.sync(refresh_rate)

      get_txi()

      -- txi.input[1]
      -- 
      main.enabled = selector(txi.input[1], {false, true, true}, 0, 5)
      if main.enabled == true and main.enabled_settting == false then
        output[1]:clock(1)
        main.enabled_settting = true
      elseif main.enabled == false and main.enabled_settting == true then
        output[1]:clock('none')
        main.enabled_settting = false
      end

      main.reset = selector(txi.input[1], {false, false, true}, 0, 5)
      if main.reset == true then
        scale = {0}
      end




      -- 2
      clock.tempo = linlin(txi.input[2], 0, 5, 30, 300)
    end
  end
)



-- clock.start( [beat] )     -- start clock (optional: start counting from 'beat')
-- clock.stop()              -- stop clock

-- clock.transport.start = start_handler -- assign a function to be called when the clock starts
-- clock.transport.stop = stop_handler   -- assign a function to be called when the clock stops


harmony = {
  s = s{1,2,3,4,6},
  sync = 1
}

harmony.clock = clock.run(
  function()
    while true do
      clock.sync(harmony.sync)
      ii.wsyn.play_note(scale[(shift_register[1] + (harmony.s() - 1)) % #scale + 1] / 12 + 1, 1)
      -- clock.sync(selctor(txi.input[4], {1/8, 1/4, 1/2, 1, 2, 3, 4, 8}, 0, 5))
    end
  end
)










