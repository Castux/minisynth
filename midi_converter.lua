package.path = package.path .. ";./LuaMidi/src/?.lua"
local midi = require "LuaMidi"
local music = require "music"

local midi_ts_to_beats = 120

local function convert_track(track)

	local start
	local notes = {}

	for _,event in ipairs(track.events) do

		if event.type == "note_on" then

			if event.timestamp ~= 0 then
				table.insert(notes, {
					name = "r",
					duration = event.timestamp / midi_ts_to_beats
				})
			end

			start = event

		elseif event.type == "note_off" then

			if not start then
				--print("Off before on?")
			elseif start.pitch ~= event.pitch then
				--print("Different pitches. Polyphony?")
			else
				local name, octave = music.midi_to_pitch(start.pitch)
				table.insert(notes, {
					name = name,
					octave = octave,
					duration = event.timestamp / midi_ts_to_beats
				})
				start = nil
			end
		end
	end

	return notes
end

local function print_track(track, track_number)

	io.write(track_number, ",sine: ")

	local last_octave, last_duration
	for _,note in ipairs(track) do
		io.write(note.name)

		if note.name ~= "r" and note.octave ~= last_octave then
			io.write(note.octave)
			last_octave = note.octave
		end

		if note.duration ~= last_duration then
			io.write("/", note.duration)
			last_duration = note.duration
		end

		io.write(" ")
	end
	io.write "\n"
end

function main()

	if #arg ~= 1 then
		error "Usage: lua midi_converter.lua <midi file>"
	end

	local path = arg[1]

	local tracks = midi.get_MIDI_tracks(path)

	for i,track in ipairs(tracks) do
		local tmp = convert_track(track)
		print_track(tmp, i)
	end
end


main()
