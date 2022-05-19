local parser = require "parser"
local generator = require "generator"

local sampleRate = 44100
local samplesPerBuffer = 2048 * 2
local bitDepth = 16
local numChannels = 1

local path
local source
local callback

local function tryQueueBuffer()

	if not callback or source:getFreeBufferCount() == 0 then
		return
	end

	local soundData = love.sound.newSoundData(samplesPerBuffer, sampleRate, bitDepth, numChannels)
	local mix, activeChannels = callback(samplesPerBuffer)

	for i,sample in ipairs(mix) do
		soundData:setSample(i - 1, sample)
	end

	source:queue(soundData)
end

function love.load()
	source = love.audio.newQueueableSource(sampleRate, bitDepth, numChannels)
end

function love.update(dt)

	tryQueueBuffer()

	if callback and not source:isPlaying() then
		print "Started music"
		source:play()
	end
end

function love.draw()
	love.graphics.print(path or "Drag and drop a .synth file on this window", 30, 30)
end

function love.filedropped(file)

	file:open("r")
	path = file:getFilename()

	local tracks = parser.read_file(file:lines())
	callback = generator.create(tracks)
end

function love.keypressed(key, scancode, isrepeat)

end
