-- Reference is a4 <=> 440 Hz

local names_to_semitones =
{
	c = -9,
	d = -7,
	e = -5,
	f = -4,
	g = -2,
	a = 0,
	b = 2
}

local alteration_to_semitones =
{
	["#"] = 1,
	["b"] = -1
}

local function add_frequency(note)

	if note.pitch == "r" then
		note.frequency = 0
		return
	end

	local semitones_diff =
		12 * (note.octave - 4) +
		names_to_semitones[note.pitch] +
		(alteration_to_semitones[note.alteration] or 0)

	note.frequency = 2 ^ (semitones_diff / 12) * 440
end

local note_name = {[0] = 'c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b'}

local function midi_to_pitch(semitones)
	-- 60 is c4
	-- 0 is c0

	local octave = semitones // 12
	local note = semitones % 12

	return note_name[note], octave
end

return {
	add_frequency = add_frequency,
	midi_to_pitch = midi_to_pitch
}
