sr = {0,0,0,0,0,0,0,0}

function next(shift_register, next_val)
  
  for i = 1, #shift_register do
    play_note(shift_register[i])
  end
  
  table.insert(shift_register, next_val)
  table.remove(shift_register, 1)
end

function play_note(note)
  print(note)
end


-- create a function that adds generated note to a table
-- remove duplicates
-- sort in order
-- create a pentatonic scale from the notes