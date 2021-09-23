--- Vox
-- DL 2021-09-20

-- divisions
divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32}
--


-- scales

-- modes
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10} -- flat 3rd, flat 7th
phrygian = {0,1,3,5,7,8,10} -- flat 2nd, flat 6th
lydian = {0,2,4,6,7,9,11} -- sharp 4th
mixolydian = {0,2,4,5,7,9,10} -- flat 7th
aeolian = {0,2,3,5,7,8,10} -- flat 3rd, flat 6th, flat 7th
locrian = {0,1,3,5,6,8,10} -- flat 2nd, flat 5th, flat 6th, flat 7th

-- other
chromatic = {0,1,2,3,4,5,6,7,8,9,10,11}
harmoninc_min = {0,2,3,5,7,8,11} -- aeolian, sharp 7th
diminished = {0,2,3,5,6,8,9,11}
whole = {0,2,4,6,8,10}

-- scale mask function
function mask(scale, degrees)
  local m = {}
  for k, v in ipairs(degrees) do
    m[k] = scale[v]
  end
  return m
end

-- pentatonic scales
penta_maj = mask(ionian, {1,2,3,5,6})
penta_sus = mask(dorian, {1,2,4,5,7})
blues_min = mask(phrygian, {1,3,4,6,7})
blues_maj = mask(mixolydian, {1,2,4,5,6})
penta_min = mask(aeolian, {1,3,4,5,7})
japanese = mask(phrygian, {1,2,4,5,6})
--


-- chords
I = {1,3,5}
II = {2,4,6}
III = {3,5,7}
IV = {4,6,8}
V = {5,7,9}
VI = {6,8,10}
VII = {7,9,11}
--


-- initial values
cv = {
  scale = mixolydian,
  octave = 0,
  degree = 1
}
--


-- Vox object
-- DL, last modified 2021-09-21
Vox = {}
function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on = args.on == nil and true or args.on
  o.level = args.level == nil and 1 or args.level
  o.scale = args.scale == nil and cv.scale or args.scale
  o.transpose = args.transpose == nil and 0 or args.transpose
  o.degree = args.degree == nil and 1 or args.degree
  o.octave = args.octave == nil and 0 or args.octave
  o.synth = args.synth == nil and function(note, level) ii.jf.play_note(note / 12, level) or args.synth
  o.wrap = args.wrap ~= nil and args.wrap or false
  o.mask = args.mask
  o.negharm = args.negharm ~= nil and args.negharm or false
  o.seq = args.seq == nil and {} or args.seq

  return o
end

function Vox:play(args)
  local args = args == nil and {} or self.update(args)
  local on, level, scale, transpose, degree, octave, synth, mask, wrap, negharm, ix, val, note

  on = self.on and (args.on == nil and true or args.on)
  level = self.level * (args.level == nil and 1 or args.level)
  scale = args.scale == nil and self.scale or args.scale
  transpose = self.transpose + (args.transpose == nil and 0 or args.transpose)
  degree = (self.degree - 1) + ((args.degree == nil and 1 or args.degree) - 1)
  octave = self.octave + (args.octave == nil and 0 or args.octave)
  synth = args.synth == nil and self.synth or args.synth
  wrap = args.wrap == nil and self.wrap or args.wrap
  mask = args.mask == nil and self.mask or args.mask
  negharm = args.negharm == nil and self.negharm or args.negharm

  octave = wrap and octave or octave + math.floor(degree / #scale)
  ix = mask and self.apply_mask(degree, scale, mask) % #scale + 1 or degree % #scale + 1
  val = negharm and (7 - scale[ix]) % 12 or scale[ix]
  note = val + transpose + (octave * 12)

  return on and synth(note, level)
end

function Vox.update(data)
  local updated = {}
  for k, v in pairs(data) do
    updated[k] = type(v) == 'function' and data[k]() or data[k]
  end
  return updated
end

function Vox.apply_mask(degree, scale, mask)
  local ix, closest_val = degree % #scale + 1, mask[1]
  for _, val in ipairs(mask) do
    val = (val - 1) % #scale + 1
    closest_val = math.abs(val - ix) < math.abs(closest_val - ix) and val or closest_val
  end
  local degree = closest_val - 1
  return degree
end

-- helper functions
function Vset(objects, property, val)
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function Vdo(objects, method, args)
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end
--


-- ii getters and event handlers
-- DL, last modified 2021-09-12

-- ii tables
txi = {param = {0,0,0,0}, input = {0,0,0,0}}

-- ii getters
function ii_getter()
  if txi then
    for i = 1, 4 do
      ii.txi.get('param', i)
      ii.txi.get('in', i)
    end
  end
end

-- ii event handlers
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
--


-- init
function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)
  ii.jf.run_mode(1)
  ii.jf.run(5)

  input[1]{mode = 'scale', notes = cv.scale,
    scale = function(s)
      cv.degree = s.index
      cv.octave = s.octave
    end
  }

  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      tsnm:play(tsnm.seq.vox_preset)
    end
  }

  output[1]:clock(1)

  all = {
    division = 1,
    action = function()
      while true do
        ii_getter()
        clock.tempo = linlin(txi.input[1], 0, 5, 30, 300)
        all.division = selector(txi.param[1], divs, 0, 10)
        clock.sync(1/32)
      end
    end
  }
  all.clock = clock.run(all.action)

  bass = Vox:new{
    octave = -2,
    synth = function(note, level) ii.jf.play_voice(6, note / 12, level) end,
    seq = {
      sync = sequins{3,1,2,2,1,3,2,2},
      division = 1,
      degree = sequins{1,1,sequins{5,8,7,5},sequins{8,5,6,2}:all():every(4)},
      vox_preset = {
        degree = function() return cv.degree + (bass.seq.degree() - 1) end,
        level = function() return linlin(txi.input[2], 0, 5, 0, 3) end
      },
      sync_preset = function()
        return
          bass.seq.sync() *
          bass.seq.division *
          all.division *
          selector(txi.param[2], divs, 0, 10)
      end,
      action = function()
        while true do
          bass:play(bass.seq.vox_preset)
          clock.sync(bass.seq.sync_preset())
        end
      end
    }
  }
  bass.clock = clock.run(bass.seq.action)

  lead1 = Vox:new{
    level = 0.5,
    octave = 0,
    synth = function(note, level) ii.jf.play_note(note / 12, level) end,
    seq = {
      sync = sequins{16,1,0.5,0.5,2},
      division  = 1,
      degree = sequins{1,4,5,9},
      vox_preset = {
        degree = function() return cv.degree + (lead1.seq.degree() - 1) end,
        level = function() return linlin(txi.input[3], 0, 5, 0, 3) end
      },
      sync_preset = function()
        return
          lead1.seq.sync() *
          lead1.seq.division *
          all.division *
          selector(txi.param[3], divs, 0, 10)
      end,
      action = function()
        while true do
          lead1:play(lead1.seq.vox_preset)
          clock.sync(lead1.seq.sync_preset())
        end
      end
    }
  }
  lead1.clock = clock.run(lead1.seq.action)

  lead2 = Vox:new{
    level = 0.5,
    octave = 0,
    degree = 7,
    synth = function(note, level) ii.jf.play_note(note / 12, level) end,
    seq = {
      sync = sequins{16,1.5,1,2,0.5},
      division = 1,
      degree = sequins{1,4,5,9}:step(3),
      vox_preset = {
        degree = function() return cv.degree + (lead2.seq.degree() - 1) end,
        level = function() return linlin(txi.input[3], 0, 5, 0, 3) end
      },
      sync_preset = function()
        return
          lead2.seq.sync() *
          lead2.seq.division *
          all.division *
          selector(txi.param[4], divs, 0, 10)
      end,
      action = function()
        while true do
          lead2:play(lead2.seq.vox_preset)
          clock.sync(lead2.seq.sync_preset())
        end
      end
    }
  }
  lead2.clock = clock.run(lead2.seq.action)

  tsnm = Vox:new{
    level = 0.3,
    synth = function(note, level) ii.wsyn.play_note(note / 12, level) end,
    seq = {
      on = sequins{true,true,false},
      vox_preset = {
        degree = function() return cv.degree end,
        octave = function() return cv.octave end,
        on = function() return tsnm.seq.on() end,
        level = function() return linlin(txi.input[4], 0, 5, 0, 2) end
      }
    }
  }

end
