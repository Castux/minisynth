local gen = require "gen"

local b1,b2,b3 = {},{},{}
gen.generate(b1, 2, 220, gen.oscillators.sine)
gen.generate(b2, 2, 440, gen.oscillators.saw)
gen.generate(b3, 3, 660, gen.oscillators.triangle)

local out = {}
gen.mix_buffers(out, b1, b2, b3)

gen.write_buffer(out)
