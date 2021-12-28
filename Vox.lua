--- Vox

-- scales
-- modes
ionian = {0,2,4,5,7,9,11}
dorian = {0,2,3,5,7,9,10} -- flat 3rd, flat 7th
phrygian = {0,1,3,5,7,8,10} -- flat 2nd, flat 6th
lydian = {0,2,4,6,7,9,11} -- sharp 4th
mixolydian = {0,2,4,5,7,9,10} -- flat 7th
aeolian = {0,2,3,5,7,8,10} -- flat 3rd, flat 6th, flat 7th
locrian = {0,1,3,5,6,8,10} -- flat 2nd, flat 5th, flat 6th, flat 7th

-- scale mask function
function mask(scale, degrees)
  local m = {}
  for k, v in ipairs(degrees) do
    m[k] = scale[v]
  end
  return m
end

-- initial values
cv = {
  scale = lydian,
  octave = 0,
  degree = 1
}
--



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



-- Vox object
Vox = {}
function Vox:new(args)
  local o = setmetatable( {}, {__index = Vox} )
  local args = args == nil and {} or args

  o.on = args.on == nil and true or args.on
  o.scale = args.scale == nil and {0,2,4,6,7,9,11} or args.scale
  o.transpose = args.transpose == nil and 0 or args.transpose
  o.degree = args.degree == nil and 1 or args.degree
  o.octave = args.octave == nil and 0 or args.octave 
  o.wrap = args.wrap ~= nil and args.wrap or false
  o.mask = args.mask
  o.negharm = args.negharm ~= nil and args.negharm or false

  o.action = args.action == nil and function(self, args) return end or args.action
  o.synth = args.synth == nil and function(self, args) return end or args.synth

  o.level = args.level == nil and 1 or args.level
  o.voice = args.voice == nil and 1 or args.voice
  o.user = args.user == nil and {} or args.user

  o.s = args.s == nil and {} or args.s -- contaner for sequins
  o.l = args.l == nil and {} or args.l -- container for lattice
  o.seq = args.seq == nil and {} or args.seq -- container for seq

  return o
end

function Vox:play(args)
  local args = args == nil and {} or args

  local updated_args = {}

  for k, v in pairs(args) do
    if sequins.is_sequins(v) or type(v) == 'function' then
      updated_args[k] = v()
    else
      updated_args[k] = v
    end

    if updated_args[k] == nil then
      return
    end
  end

  args = updated_args

  args.on = self.on and (args.on == nil and true or args.on)
  args.scale = args.scale == nil and self.scale or args.scale
  args.transpose = self.transpose + (args.transpose == nil and 0 or args.transpose)
  args.degree = (self.degree - 1) + ((args.degree == nil and 1 or args.degree) - 1)
  args.octave = self.octave + (args.octave == nil and 0 or args.octave)
  args.wrap = args.wrap == nil and self.wrap or args.wrap
  args.mask = args.mask == nil and self.mask or args.mask
  args.negharm = args.negharm == nil and self.negharm or args.negharm

  args.action = args.action == nil and self.action or args.action
  args.synth = args.synth == nil and self.synth or args.synth
  
  args.level = args.level == nil and self.level or args.level
  args.voice = args.voice == nil and self.voice or args.voice
  args.user = args.user == nil and self.user or args.user

  args.scale = args.scale == nil and self.scale or args.scale
  args.octave = args.wrap and args.octave or args.octave + math.floor(args.degree / #args.scale)

  args.degree = args.mask and self.apply_mask(args.degree, args.scale, args.mask) or args.degree
  args.ix = args.degree % #args.scale + 1
  args.note = args.negharm and (7 - args.scale[args.ix]) % 12 or args.scale[args.ix]
  args.note = args.note + args.transpose + (args.octave * 12)

  if args.on then
    args.action(self, args)
    args.synth(args)
    return args.note
  end
end

-- TODO function that creates sequins
-- TODO function that creates seq

function Vox:reset()
  -- -- TODO error handling if no sequins, seq or midi
  -- self.seq:reset()

  -- for k, v in pairs(self.s) do
  --   self.s[k]:reset()
  -- end
end

function Vox.jfn(args)
  ii.jf.play_note(args.note / 12, args.level) 
end

function Vox.jfv(args)
  ii.jf.play_voice(args.voice, args.note / 12, args.level) 
end

function Vox.wsn(args)
  ii.wsyn.play_note(args.note / 12, args.level) 
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

function Vox.set(objects, property, val)
  for k, v in pairs(objects) do
    v[property] = val
  end
end

function Vox.call(objects, method, args)
  for k, v in pairs(objects) do
    v[method](v, args)
  end
end
--



-- init
function init()
  ii.jf.mode(1)
  ii.wsyn.ar_mode(1)

  input[1]{mode = 'scale', notes = cv.scale,
    scale = function(s)
      cv.degree = s.index
      cv.octave = s.octave
    end
  }

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







  input[2]{mode = 'change', threshold = 4, direction = 'rising',
    change = function()
      -- tsnm:play(tsnm.seq.preset)
      -- bass:play{degree = cv.degree, octave = cv.octave, level = linlin(txi.param[1], 0, 5, 0, 2)}
      
      
      
      -- main = clock.run(
      --   function()
          lead:play{degree = cv.degree, octave = cv.octave, level = linlin(txi.param[2], 0, 5, 0, 2)}
      --   end
      -- )

    end
  }

  output[1]:clock(1)
end



-- tsnm = Vox:new{
--   level = 0.3,
--   synth = function(note, level) ii.jf.play_note(note / 12, level) end,
--   seq = {
--     preset = {
--       degree = function() return cv.degree end,
--       octave = function() return cv.octave - 3 end,
--       level = function() return linlin(txi.input[4], 0, 5, 0, 2) end
--     }
--   }
-- }

-- bass = Vox:new{
--   synth = Vox.jfv,
--   scale = cv.scale,
--   octave = -2
-- }

lead = Vox:new{
  synth = Vox.jfn,
  scale = cv.scale,
}

-- harmony = Vox:new{
--   synth = Vox.jfn,
--   scale = cv.scale,
--   octave = -1,
-- }

-- flourish = Vox:new{
--   synth = Vox.wsn,
--   scale = cv.scale,
--   mask = {1,2,3,4,6},
--   octave = 1,
--   level = 0.1,
--   s = {
--     degree = sequins{1,2,3,4,5,6,7,8}
--   }
-- }

