--- TSNM & JF
-- NB: each w/ has a different address - w/[1] and w/[2]

-- controls
-- volume

-- crow
-- input 1: gate 1
-- input 2: gate 2
-- output1: lfo
-- output2: lfo
-- output3: lfo
-- output4: lfo

-- txi
-- input 1: v8 1
-- input 2: v8 2
-- input 3: 
-- input 4: 
-- param 1: 
-- param 2: 
-- param 3: 
-- param 4: 


-- txi getter, saves txi param and input values as a table
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

function txi.get()
  for i = 1, 4 do
    ii.txi.get('param', i)
    ii.txi.get('in', i)
  end
end

txi.refresh = clock.run(
  function()
    while true do
      txi.get()
      clock.sleep(0.1)
    end
  end
)

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
  table.insert(shift_register, 1, val)
  table.remove(shift_register, #shift_register)
end
--



function init()
  ii.jf.mode(1)
  ii.jf.transpose(-3)
  
  input[1]{mode = 'scale',
    notes = {0,1,2,3,4,5,6,7,8,9,10,11},
    scale = function(s)
      input[1].index = s.index
      input[1].octave = s.octave
      input[1].note = s.note
    end
  }
  
  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = shift
  }

  for i = 1, 4 do
    output[i].action = lfo(dyn{time = 1}, dyn{height = 1}, 'sine')
    output[i]()
  end

end


 shift = function()
  clock.run(
    function()
      clock.sleep(0.05)
      add_to_shift(shift_register, input[1].volts)

      for i = 1, 2 do
        ii.jf.play_note(shift_register[i], 2)
        clock.sleep(math.random()/40)
      end
    end
  )
end
