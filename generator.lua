local bits_per_sample = 16
local max_value = 2 ^ (bits_per_sample - 1) - 1
local sample_rate = 44100


local function create(notes)
	return {
		tempo = notes.tempo,
		instrument = notes.instrument,

		notes = notes,
		note_index = 1,

		volume = 0,
		sample = 0,
		phi = 0,	-- periods
		finished = false,

		frequency = nil
	}
end

local envelope_rate = 0.005
local function standard_envelope(current_volume, t, is_silence)
	local target = is_silence and 0 or 1
	return current_volume + (target - current_volume) * envelope_rate
end

local drum_attack = 0.001
local drum_release = 5

local function drum_envelope(current_volume, t, is_silence)
	if is_silence then
		return 0
	elseif t < drum_attack then
		return t / drum_attack
	else
		return math.max(0, 1 - drum_release * (t - drum_attack))
	end
end

local instruments =
{
	sine = {
		func = function(phi)
			return math.sin(phi * 2 * math.pi)
		end,
		envelope = standard_envelope
	},

	square = {
		func = function(phi)
			return (phi % 1) > 0.5 and 1 or -1
		end,
		envelope = standard_envelope
	},

	saw = {
		func = function(phi)
			return (phi % 1) * 2 - 1
		end,
		envelope = standard_envelope
	},

	triangle = {
		func = function(phi)
			return 1 - 4 * math.abs(0.5 - (phi % 1))
		end,
		envelope = standard_envelope
	},

	kick = {
		func = function(phi, t)
			return math.sin(t * 55 * 2 * math.pi)
		end,
		envelope = drum_envelope
	},

	hihat = {
		func = function(phi)
			return (math.random() * 2 - 1) * 0.75
		end,
		envelope = drum_envelope
	}
}

local function generate(channel, buffer, num_samples)

	for i = 1,num_samples do

		if channel.finished then
			buffer[i] = 0
			goto continue
		end

		local note = channel.notes[channel.note_index]

		if note.pitch ~= "r" then
			channel.frequency = note.frequency
		end

		-- Time

		local t = channel.sample / sample_rate
		local beat = channel.tempo / 60 * t

		-- Envelope

		local note_played_for = t - note.start_beat / channel.tempo * 60
		local env_func = instruments[channel.instrument].envelope
		channel.volume = env_func(channel.volume, note_played_for, note.pitch == "r")

		-- Generation

		local oscillator = instruments[channel.instrument].func
		buffer[i] = oscillator(channel.phi, t) * channel.volume

		-- Advance time

		if channel.frequency then
			channel.phi = channel.phi + channel.frequency / sample_rate
		end

		channel.sample = channel.sample + 1

		-- Next note?

		while beat > note.end_beat do
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
