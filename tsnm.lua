--- TSNM & JF

-- crow
-- input 1: gate 1
-- input 2: gate 2
-- output 1: lfo 1 (fast)
-- output 2: lfo 2 (slow)
-- output 3: random cv (based on gate 1 and 2)
-- output 4: ar envelope

-- txi
-- param 1: off / volume
-- param 2: lfo rate
-- param 3: ar envelope attack time
-- param 4: ar envelope release time
-- input 1: v8 1
-- input 2: v8 2
-- input 3: volume offset *lfo skew
-- input 4: gate delay (slop)




-- txi getter, saves txi param and input values as a table
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

txi.get = function()
  for i = 1, 4 do
    ii.txi.get('param', i)
    ii.txi.get('in', i)
  end
end

ii.txi.event = function(e, val)
  txi[e.name == 'in' and 'input' or e.name][e.arg] = val
end

txi.refresh = clock.run(
  function()
    while true do
      txi.get()
      clock.sleep(0.015)
    end
  end
)
--




-- helper functions
function clamp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function range(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( range( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end
--




--
function init()
  ii.jf.mode(1)
  ii.jf.transpose(-3)

  input[1]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function()
      clock.run(
        function()
          local r = ((0.5 - math.random()) * round(txi.input[4])) / 10
          clock.sleep(0.05 + r)
          synth(txi.input[1], txi.param[1] + math.abs(txi.input[3]))
          output[3].volts = random_voltage()
          output[4]()
        end
      )
    end
  }

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function()
      clock.run(
        function()
          local r = ((0.5 - math.random()) * round(txi.input[4])) / 10
          print(txi.input[4], r)
          clock.sleep(0.05 + r)
          synth(txi.input[2], txi.param[1] + math.abs(txi.input[3]))
          output[3].volts = random_voltage()
          output[4]()
        end
      )
    end
  }

  output[1].action = lfo(dyn{time = 0.25}, dyn{height = 5}, 'sine')
  output[2].action = lfo(dyn{time = 0.5}, dyn{height = 5}, 'sine')
  output[4].action = ar(dyn{attack = 0}, dyn{release = 0.5}, dyn{height = 5}, 'linear')

  output[1]()
  output[2]()
end
--




-- clocks
crow.refresh = clock.run(
  function()
    while true do
      clock.sleep(0.1)
      output[1].dyn.time = 0.005 + 10 - range(txi.param[2], 0, 10, 0, 10)
      output[2].dyn.time = 0.005 + 20 - range(txi.param[2], 0, 10, 0, 10)
      output[4].dyn.attack = range(txi.param[3], 0, 10, 0, 1)
      output[4].dyn.release = range(txi.param[4], 0, 10, 0, 1)
    end
  end
)
--





-- synth functions
function synth(note, level)
  note = round(note * 12) / 12
  level = range(level, 0.5, 10, 0, 5)

  local enabled = selector(level, {false, true}, 0, 0.1)
  if enabled == false then return end
  
  ii.jf.play_note(note, level)
end

function random_voltage()
  return math.random() * 10 - 5
end
--




-- input[1]{mode = 'scale',
--   notes = {0,1,2,3,4,5,6,7,8,9,10,11},
--   scale = function(s)
--     input[1].index = s.index
--     input[1].octave = s.octave
--     input[1].note = s.note
--   end
-- }