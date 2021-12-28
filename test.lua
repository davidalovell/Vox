-- shift register test

octave = -2

shift_register = {0,0,0,0,0,0,0,0}
scale = {0}









-- ii getters and event handlers
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

function ii_getter()
  if txi then
    for i = 1, 4 do
      ii.txi.get('param', i)
      ii.txi.get('in', i)
    end
  end
end

ii.txi.event = function(e, val)
  if txi then
    txi[e.name == 'in' and 'input' or e.name][e.arg] = val
  end
end

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

function apply_mask(degree, scale, mask)
  local ix, closest_val = degree % #scale + 1, mask[1]
  for _, val in ipairs(mask) do
    val = (val - 1) % #scale + 1
    closest_val = math.abs(val - ix) < math.abs(closest_val - ix) and val or closest_val
  end
  local degree = closest_val - 1
  return degree
end
--







function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  -- main clock loop
  main = clock.run(
    function()
      while true do
        ii_getter()
        clock.tempo = linlin(txi.input[2], 0, 5, 30, 300)
        clock.sync(1/64)
      end
    end
  )

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function()
      clock.run(
        function()

          local val = input[1].volts
          do_shift(shift_register, val)
          do_scale(scale, val)

          -- ii.wsyn.play_note(scale[(shift_register[1] + (seq() - 1)) % #scale + 1] / 12 + 1, 1)
          clock.sync(1/16)
          ii.jf.play_note(shift_register[1]/12 + octave, 2)
          clock.sync(1/(math.random(1,2)*12))
          ii.jf.play_note(shift_register[2]/12 + octave, 2)
        end
      )
    end
  }

  seq = sequins{1,2,3,4,6}:step(2)



  harmony = clock.run(
    function()
      while true do
        ii.wsyn.play_note(scale[(shift_register[1] + (seq() - 1)) % #scale + 1] / 12 + 1, 1)
        clock.sync(selctor(txi.input[4], {1/8, 1/4, 1/2, 1, 2, 3, 4, 8}, 0, 5))
      end
    end
  )



  output[1]:clock(1)
  end
















function do_shift(shift_register, val)
  val = round(val * 12)
  table.insert(shift_register, 1, val)
  table.remove(shift_register, #shift_register)
end

function do_scale(scale, val)
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