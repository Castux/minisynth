local midi = require "MIDI"
local music = require "music"

local function split_channel_into_voices(channel)

	local start
	local notes = {}

	local voices = {}

	for _,event in ipairs(channel) do
		if event.type == "note" then

			-- insert into first silent voice

			for i = 1,#voices + 1 do
				local voice = voices[i]
				if not voice then
					voice = {}
					table.insert(voices, voice)
					table.insert(voice, event)
					break
				elseif voice[#voice].end_time <= event.time then
					table.insert(voice, event)
					break
				end
			end
		end
	end

	return voices
end

local function print_voice(voice, ticks_per_beat, fp)

	local last_end_time = 0
	local last_octave, last_duration

	local function write_duration(d)
		local rounded = math.floor(d / ticks_per_beat * 100000) / 100000
		fp:write(string.format("/%g", rounded))
	end

	for _,event in ipairs(voice) do

		local name, octave = music.midi_to_pitch(event.note)

		-- Insert rest?

		local dtime = event.time - last_end_time
		if dtime > 0 then
			fp:write "r"
			if dtime ~= last_duration then
				write_duration(dtime)
				last_duration = dtime
			end
			fp:write " "
		end

		fp:write(name)

		if octave ~= last_octave then
			fp:write(octave)
			last_octave = octave
		end

		if event.duration ~= last_duration then
			write_duration(event.duration)
			last_duration = event.duration
		end

		last_end_time = event.end_time

		fp:write " "
	end
end

local function correct_event(event)

	event.type = event[1]
	event.time = event[2]

	if event.type == "note" then
		event.duration = event[3]
		event.channel = event[4]
		event.note = event[5]
		event.velocity = event[6]
		event.end_time = event.time + event.duration

	elseif event.type == "patch_change" then
		event.channel = event[3]
		event.patch = event[4]

	else
		return false
	end

	return true
end

local function split_by_track_channel(score)

	local tmp = {}

	for track_index, track in ipairs(score) do
		for _,event in ipairs(track) do

			if not correct_event(event) then
				goto continue
			end

			local name = string.format("Track %2d: channel %2d", track_index, event.channel)
			if not tmp[name] then
				tmp[name] = {}
			end

			if event.type == "note" then
				table.insert(tmp[name], event)

			elseif event.type == "patch_change" then
				if event.channel == 9 then
					tmp[name].instrument = "Percussions"
				else
					tmp[name].instrument = midi.Number2patch[event.patch]
				end
			end

			::continue::
		end
	end

	local result = {}

	for name,channel in pairs(tmp) do
		channel.name = name
		table.sort(channel, function(a,b) return a.time < b.time end)
		table.insert(result, channel)
	end

	table.sort(result, function(a,b) return a.name < b.name end)
	return result
end

function main()

	if #arg ~= 1 then
		error "Usage: lua midi_converter.lua <midi file>"
	end

	local path = arg[1]
	local file = io.open(path, "rb")
	if not file then
		error("Could not open " .. path)
	end
	local bytes = file:read "a"
	local score = midi.midi2score(bytes)

	local out_path = path:gsub(".mid$", ".synth")
	local out_file = io.open(out_path, "w")
	if not out_file then
		error("Could not open " .. out_path)
	end

	score.ticks_per_beat = table.remove(score, 1)

	local channels = split_by_track_channel(score)

	local voice_index = 1

	for _,channel in pairs(channels) do
		local voices = split_channel_into_voices(channel)
		local str = string.format("%s (%s), %d voices", channel.name, channel.instrument, #voices)
		print(str)
		out_file:write("# ", str, "\n\n")

		for _,voice in ipairs(voices) do
			out_file:write(voice_index, ": ")
			print_voice(voice, score.ticks_per_beat, out_file)
			out_file:write("\n\n")
			voice_index = voice_index + 1
		end
	end

end


main()
