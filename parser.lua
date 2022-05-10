local music = require "music"

local function parse_comment(str)
	if str == "" or str:match "^#" then
		return true
	end
end

local function parse_tempo(str, tracks)

	local tempo = str:match "^tempo (%d+)$"
	if tempo then
		tracks.tempo = tonumber(tempo)
		return
	end

	error("Expected tempo")
end

local function parse_instruments(str, tracks)

	local instruments = str:match "^tracks (.*)$"
	if instruments then
		for instru in instruments:gmatch "%w+" do
			table.insert(tracks, {
				instrument = instru,
				last_end_beat = 0
			})
		end
		return
	end

	error("Expected instrument list")
end

local function parse_line(str, tracks)

	local track_number, notes = str:match("^(%d+):(.*)$")
	if not (track_number and notes) then
		error("Line format expected '<track>:<notes>'")
	end

	track_number = tonumber(track_number)
	if not tracks[track_number] then
		error("Wrong track number: " .. track_number)
	end
	local track = tracks[track_number]

	local current_octave = 4
	local current_duration = 1

	for pitch, alteration, octave, duration in notes:gmatch "([abcdefgr])([#b]?)(%d?)/?([%d%.]*)" do

		current_octave = tonumber(octave) or current_octave
		current_duration = tonumber(duration) or current_duration

		local start_beat = track.last_end_beat
		track.last_end_beat = track.last_end_beat + current_duration

		local note = {
			pitch = pitch,
			alteration = alteration,
			octave = current_octave,
			duration = current_duration,
			start_beat = start_beat,
			end_beat = track.last_end_beat
		}
		music.add_frequency(note)

		table.insert(track, note)
	end

	return tracks
end

local function read_file(path)

	local tracks = {}

	for line in io.lines(path) do

		if parse_comment(line) then
			-- Do nothing
		elseif not tracks.tempo then
			parse_tempo(line, tracks)
		elseif #tracks == 0 then
			parse_instruments(line, tracks)
		else
			parse_line(line, tracks)
		end
	end

	return tracks
end

return {
	read_file = read_file
}
