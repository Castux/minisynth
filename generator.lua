local bits_per_sample = 16
local max_value = 2 ^ (bits_per_sample - 1) - 1
local sample_rate = 44100

local envelope_rate = 0.005

local function create(notes)
	return {
		notes = notes,
		note_index = 1,
		volume = 0,
		beat = 0,	-- beats
		phi = 0,	-- periods
		finished = false,

		func = "silence",
		frequency = nil
	}
end

local low_noise_sample = 0
local low_noise_cutout = 0.97

local high_noise_sample = 0
local last_noise = 0
local high_noise_cutout = 0.5

local oscillators =
{
	sine = function(phi)
		return math.sin(phi * 2 * math.pi)
	end,

	square = function(phi)
		return (phi % 1) > 0.5 and 1 or -1
	end,

	saw = function(phi)
		return (phi % 1) * 2 - 1
	end,

	triangle = function(phi)
		return 1 - 4 * math.abs(0.5 - (phi % 1))
	end,

	kick = function(phi)
		return math.sin(phi / 5 * 2 * math.pi)
	end,

	highhat = function(phi)
		local new_noise = math.random() * 2 - 1
		local new = high_noise_cutout * (high_noise_sample + new_noise - last_noise)
		last_noise = new_noise
		high_noise_sample = new
		return math.random() * 2 - 1
	end,

	silence = function(phi)
		return 0
	end
}

local function generate(channel, buffer, num_samples)

	for i = 1,num_samples do

		local note = channel.notes[channel.note_index]
		if not note then
			channel.finished = true
			buffer[i] = 0
			goto continue
		end

		if note.pitch ~= "r" then
			channel.func = note.func
			channel.frequency = note.frequency
		end

		buffer[i] = oscillators[channel.func](channel.phi) * channel.volume

		-- Advance time (dt = 1 / sample_rate)

		local dbeat = note.tempo / 60 / sample_rate		-- tempo / 60 * dt

		channel.beat = channel.beat + dbeat

		if channel.frequency then
			channel.phi = channel.phi + channel.frequency / sample_rate
		end

		-- Envelope

		if note.func == "highhat" and note.pitch ~= "r" then
			local note_played_for = channel.beat - note.start_time
			channel.volume = math.max(0, 1 - 3 * note_played_for)
		elseif note.func == "kick"  and note.pitch ~= "r" then
			local note_played_for = channel.beat - note.start_time
			if note_played_for < 0.01 then
				channel.volume = note_played_for / 0.01
			else
				channel.volume = math.max(0, 1 - 3 * (note_played_for - 0.01))
			end
		else
			local target = note.pitch == "r" and 0 or 1
			channel.volume = channel.volume + (target - channel.volume) * envelope_rate
		end

		-- Next note?
		while channel.beat > note.end_time do
			channel.note_index = channel.note_index + 1
			note = channel.notes[channel.note_index]
			if not note then
				channel.finished = true
				break
			end
		end

		::continue::
	end
end

local function write_buffer(buffer, fp)
	for i = 1, #buffer do
		local tmp = math.floor(buffer[i] * max_value)
		tmp = string.pack("i2", tmp)
		fp:write(tmp)
	end
end

local function make_generator(tracks)

	local channels = {}
	for i,track in ipairs(tracks) do
		channels[i] = create(track)
	end

	local tmp = {}
	local mix = {}

	return function(num_samples)

		for i = 1,num_samples do
			mix[i] = 0
		end

		local active_channels = 0

		for i = 1,#tracks do
			generate(channels[i], tmp, num_samples)
			for j = 1,num_samples do
				mix[j] = mix[j] + tmp[j]
			end

			if not channels[i].finished then
				active_channels = active_channels + 1
			end
		end

		for i = 1,num_samples do
			mix[i] = mix[i] / #tracks
		end

		return mix, active_channels
	end
end

return
{
	create = make_generator,
	write_buffer = write_buffer
}
