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

return {
	add_frequency = add_frequency
}
