--- TSNM & JF
-- NB: each w/ has a different address - w/[1] and w/[2]

-- TODO
-- controls:

-- crow
-- input 1: gate 1
-- input 2: gate 2
-- output 1: lfo 1
-- output 2: lfo 2
-- output 3: envelope
-- output 4: random (based on gate 1/2)

-- txi
-- param 1: synth mode off / volume
-- param 2: lfo rates
-- param 3: attack time
-- param 4: release time
-- input 1: v8 1
-- input 2: v8 2
-- input 3: volume offset
-- input 4: gate delay offset




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

function linlin(x, in_min, in_max, out_min, out_max)
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function selector(x, data, in_min, in_max, out_min, out_max)
  out_min = out_min or 1
  out_max = out_max or #data
  return data[ clamp( round( linlin( x, in_min, in_max, out_min, out_max ) ), out_min, out_max ) ]
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
          clock.sleep(0.05 + txi.input[4]/50)
          synth(txi.input[1], txi.param[1] + math.abs(txi.input[3]))
          output[3]()
          output[4].volts = rnd()
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
          clock.sleep(0.05 + txi.input[4]/50)
          synth(txi.input[2], txi.param[1] + math.abs(txi.input[3]))
          output[3]()
          output[4].volts = rnd()
        end
      )
    end
  }

  output[1].action = lfo(dyn{time = 0.25}, dyn{height = 5}, 'sine')
  output[2].action = lfo(dyn{time = 0.5}, dyn{height = 5}, 'sine')
  output[3].action = ar(dyn{attack = 0}, dyn{release = 0.5}, dyn{height = 5}, 'linear')

  for i = 1, 2 do output[i]() end
  
end
--




-- clocks
output_refresh = clock.run(
  function()
    while true do
      clock.sleep(0.1)
      output[1].dyn.time = 0.005 + linlin(txi.param[2], 0, 10, 0, 2.5)
      output[2].dyn.time = 0.005 + linlin(txi.param[2], 0, 10, 0, 5)
      output[3].dyn.attack = linlin(txi.param[3], 0, 10, 0, 1)
      output[3].dyn.release = linlin(txi.param[4], 0, 10, 0, 1)
    end
  end
)
--




--
function synth(note, level)
  note = round(note * 12)
  level = linlin(level, 0.5, 10, 0, 5)
  local enabled = selector(level, {false, true}, 0, 1)
  if enabled == false then return end
  ii.jf.play_note(note / 12, level)
end

function rnd()
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