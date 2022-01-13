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
-- input 3: volume offset
-- input 4: gate delay (slop)

-- todo
-- make gate delay (not +/-)
-- global vars at start of code
-- code order
-- code readability
-- DRY code
-- date delay that responds to tempo
-- Change the input to a random gate delay (rather than +/-)
-- Make input change functions better


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

-- helper functions
function clamp(x, min, max)
  return math.min( math.max( min, x ), max )
end

function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function map(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( map( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
end

-- init
function init()
  ii.jf.mode(1)
  ii.jf.transpose(-3)

  input[1]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = one
  }

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = two
  }

  output[1].action = lfo(dyn{time = 0.25}, dyn{height = 5}, 'sine')
  output[2].action = lfo(dyn{time = 0.5}, dyn{height = 5}, 'sine')
  output[4].action = ar(dyn{attack = 0}, dyn{release = 0.5}, dyn{height = 5}, 'linear')

  output[1]()
  output[2]()
end

-- clocks
one = function()
  clock.run(
    function()
      -- gate delay
      clock.sleep(0.05 + math.random() * round(txi.input[4]) / 10)
      -- outout random voltage centred around 0v
      output[3].volts = math.random() * 10 - 5
      -- trigger ar envelope
      output[4]()
      -- play synth
      synth(txi.input[1], txi.param[1] + math.abs(txi.input[3]))
    end
  )
end

function()
  clock.run(
    function()
      -- gate delay
      clock.sleep(0.05 + math.random() * round(txi.input[4]) / 10)
      -- outout random voltage centred around 0v
      output[3].volts = math.random() * 10 - 5
      -- trigger ar envelope
      output[4]()
      -- play synth
      synth(txi.input[2], txi.param[1] + math.abs(txi.input[3]))
    end
  )
end

refresh = clock.run(
  function()
    while true do
      clock.sleep(0.1)
      output[1].dyn.time = 0.005 + 10 - map(txi.param[2], 0, 10, 0, 10)
      output[2].dyn.time = 0.005 + 20 - map(txi.param[2], 0, 10, 0, 10)
      output[4].dyn.attack = map(txi.param[3], 0, 10, 0, 1)
      output[4].dyn.release = map(txi.param[4], 0, 10, 0, 1)
    end
  end
)

-- synth functions
function synth(note, level)
  note = round(note * 12) / 12
  level = range(level, 0.5, 10, 0, 5)

  local enabled = selector(level, {false, true}, 0, 0.1)
  if enabled == false then return end
  
  ii.jf.play_note(note, level)
end

-- input[1]{mode = 'scale',
--   notes = {0,1,2,3,4,5,6,7,8,9,10,11},
--   scale = function(s)
--     input[1].index = s.index
--     input[1].octave = s.octave
--     input[1].note = s.note
--   end
-- }