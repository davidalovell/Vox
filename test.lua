-- shift register test

octave = -2

sr = {0,0,0,0,0,0,0,0}
sc = {}


function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function()
      clock.run(
        function()

          shift(sr, sc, input[1].volts)

          ii.jf.play_note(sr[1]/12 + octave, 2)
          clock.sync(1/(math.random(1,2)*4))
          ii.jf.play_note(sr[2]/12 + octave, 2)

        end
      )
    end
  }

  output[1]:clock(1/2)
end








function round(x)
  return x % 1 >= 0.5 and math.ceil(x) or math.floor(x)
end

function shift(shift_register, scale, val)

  -- convert voltage to nearest semitone, constrain to one octave (12tet)
  val = round(val * 12)
  scale_val = val % 12

  -- insert new val at start of shift_register
  -- remove val from end of shift_register
  table.insert(shift_register, 1, val)
  table.remove(shift_register, #shift_register)

  -- compare val with existing values in scale
  local scale_val_is_duplicate
  for k, v in ipairs(scale) do
    if scale_val == v then scale_val_is_duplicate = true end
  end
  
  -- add val if no duplicate value in scale_table
  if not scale_val_is_duplicate then
    table.insert(scale, scale_val)
  end

  -- sort the table in order to produce a scale
  table.sort(scale)

end