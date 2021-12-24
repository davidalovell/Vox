scale = {}
sr = {0,0,0,0,0,0,0,0}

function play_note(note)
  print(note)
end


function next(shift_register, val, scale_table)

  -- insert new val at start of shift_register
  -- remove val from end of shift_register
  table.insert(shift_register, 1, val)
  table.remove(shift_register, #shift_register)

  -- compare val with existing values in scale_table
  local val_is_duplicate
  for k, v in ipairs(scale_table) do
    if val == v then val_is_duplicate = true end
  end
  
  -- add val if no duplicate value in scale_table
  if not val_is_duplicate then
    table.insert(scale_table, val)
  end

  -- sort the table in order to produce a scale
  table.sort(scale_table)

  -- print shift_register
  for i = 1, #shift_register do
    play_note(shift_register[i])
  end

  print()

  -- print scale_table
  for i = 1, #scale_table do
    print(scale_table[i])
  end

end



-- create a function that adds generated note to a table -done
-- remove duplicates -done
-- sort in order -done
-- multiply cv value x 12
-- round to cv value integer
-- remove transposed octaves - use %
-- create a pentatonic scale from the notes

-- other ideas which you may or may not wish to add:
-- play a third up from current note, etc
-- can use Vox