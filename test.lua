local gen = require "gen"
local parser = require "parser"

local tracks = parser.read_file "example"
gen.generate(tracks)
