local generator = require "generator"

local sampleRate = 44100
local samplesPerBuffer = 512
local bitDepth = 16
local numChannels = 1

local source
local gen

local top_octave = 1
local bottom_octave = -2

local function tryQueueBuffer()

	if not gen or source:getFreeBufferCount() == 0 then
		return
	end

	local soundData = love.sound.newSoundData(samplesPerBuffer, sampleRate, bitDepth, numChannels)
	local mix = gen.generate(samplesPerBuffer)

	for i,sample in ipairs(mix) do
		soundData:setSample(i - 1, sample)
	end

	source:queue(soundData)
end

function love.load()
	source = love.audio.newQueueableSource(sampleRate, bitDepth, numChannels)
	gen = generator.new(sampleRate)
end

function love.update(dt)

	tryQueueBuffer()

	if gen and not source:isPlaying() then
		print "Started music"
		source:play()
	end
end

function love.draw()
	love.graphics.print("The cool 1bit synth. Ratio: " .. gen.ratio, 30, 30)
	love.graphics.print(table.concat(gen.notes, " "), 30, 70)
	love.graphics.print("Arp: " .. gen.arp_period .. (gen.arp and "!" or "..."), 30, 100)
end

local keys_top = {"q","2","w","3","e","r","5","t","6","y","7","u","i","9","o","0","p"}
local keys_bottom = {"z","s","x","d","c","v","g","b","h","n","j","m",",","l","."}

for i,v in ipairs(keys_top) do keys_top[v] = i end
for i,v in ipairs(keys_bottom) do keys_bottom[v] = i end

local function keyToPitch(key)

	if keys_top[key] then
		return keys_top[key] + top_octave * 12
	elseif keys_bottom[key] then
		return keys_bottom[key] + bottom_octave * 12
	end

end

function love.keypressed(key)
	local pitch = keyToPitch(key)
	if pitch then
		table.insert(gen.notes, pitch)
	end

	if key == "down" then
		gen.ratio = gen.ratio - 0.05
	elseif key == "up" then
		gen.ratio = gen.ratio + 0.05
	elseif key == "space" then
		gen.noise = true
	elseif key == "tab" then
		gen.arp = not gen.arp
	elseif key == "left" then
		gen.arp_period = gen.arp_period - 0.01
	elseif key == "right" then
		gen.arp_period = gen.arp_period + 0.01
	end
end

function love.keyreleased(key)
	local pitch = keyToPitch(key)
	if pitch then
		for i = 1,#gen.notes do
			if gen.notes[i] == pitch then
				table.remove(gen.notes, i)
				break
			end
		end
	end

	if key == "space" then
		gen.noise = false
	end
end
