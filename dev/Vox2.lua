--- Vox

-- scales and chords
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

-- chords
I = {1,3,5}
II = {2,4,6}
III = {3,5,7}
IV = {4,6,8}
V = {5,7,9}
VI = {6,8,10}
VII = {7,9,11}
--



-- divisions
divs = {1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32}
--



-- initial values
cv = {
  scale = mixolydian,
  octave = 0,
  degree = 1
}
--


-- Vox object
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
  o.synth = args.synth == nil and function(note, level) ii.jf.play_note(note / 12, level) end or args.synth
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

function Vox:newseq(args)
  local args = args == nil and {} or args

  self.addseq = function(self, args)
    self.seq.dyn = self.seq.dyn == nil and {} or self.seq.dyn
    for k, v in pairs(args) do
      self['seq'][k] = v
      self['seq']['dyn'][k] = (type(v) == 'function' or type(v) == 'table') and function() return v() end or v
    end
  end

  self:addseq(args)
end
  -- self.playseq = function(self)
  --   -- while true do
  --     return self:play(self.seq)
  --     -- self:play(self.seq)
  --     -- clock.sync(self.seq.sync() == nil and 1 or self.seq.sync())
  --   -- end
  -- end

  -- self.clock = clock.run(self.playseq)

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


function newseq(args)
  local args = args == nil and {} or args
  local seq, preset = {}, {}

  for k, v in pairs(args) do
    seq[k] = v
    preset[k] = (type(v) == 'function' or type(v) == 'table') and function() return v() end or v
  end

  return seq, preset
end


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
      -- tsnm:play(tsnm.seq.preset)
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

end
