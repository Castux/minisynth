local generator = require "generator"
local parser = require "parser"

if #arg ~= 1 then
    error("Usage: lua main.lua <filename>")
end

local tracks = parser.read_file(arg[1])
generator.generate(tracks)
