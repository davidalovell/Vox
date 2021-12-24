

octave = -3



function skip()
  local i = 0
  return
    function()
      i = i + 1
      return i
    end
end

function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  -- input[1]{mode = 'stream'}

  lead_sr = {input[1].volts}

  input[2]{
    mode = 'change',
    threshold = 4,
    direction = 'rising',
    change = function()
      clock.run(
        function()
          table.insert(lead_sr, input[1].volts)
          ii.jf.play_note(input[1].volts + octave, 1)
          clock.sync(1/(math.random(1,2)*4))
          ii.jf.play_note(table.remove(lead_sr, 1) - 1 + octave, 1)
        end
      )
    end
  }

  output[1]:clock(1/2)
end