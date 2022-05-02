local midi = require "MIDI"
local music = require "music"

local function split_track_into_voices(track)

	local start
	local notes = {}

	local voices = {}

	for _,event in ipairs(track) do
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

	for _,event in ipairs(voice) do

		local name, octave = music.midi_to_pitch(event.note)

		-- Insert rest?

		local dtime = event.time - last_end_time
		if dtime > 0 then
			fp:write "r"
			if dtime ~= last_duration then
				fp:write("/", dtime / ticks_per_beat)
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
			fp:write("/", event.duration / ticks_per_beat)
			last_duration = event.duration
		end

		last_end_time = event.end_time

		fp:write " "
	end

	fp:write "\n"
end

local function correct_event(event)

	event.type = event[1]
	event.time = event[2]

	if event.type == "note_on" or event.type == "note_off" then
		event.channel = event[3]
		event.note = event[4]
		event.velocity = event[5]
	elseif event.type == "note" then
		event.duration = event[3]
		event.channel = event[4]
		event.note = event[5]
		event.velocity = event[6]
		event.end_time = event.time + event.duration
	elseif event.type == "set_tempo" then
		event.tempo = event[3]
	end
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

	local voice_index = 1

	for i,track in ipairs(score) do
		for _,event in ipairs(track) do
			correct_event(event)
		end
		table.sort(track, function(a,b) return a.time < b.time end)

		local voices = split_track_into_voices(track)

		for _,voice in ipairs(voices) do
			out_file:write(voice_index, ",sine: ")
			print_voice(voice, score.ticks_per_beat, out_file)
			voice_index = voice_index + 1
		end
	end

end


main()
