local function new(rate)

	local gen = {
		sample_rate = rate,
		sample = 0,

		noise = false,

		arp = false,
		arp_period = 0.1,

		ratio = 0.25,		-- how much of the period is high for a square wave
		notes = {}		-- in semitones from A440
	}

	local mix = {}
	function gen.generate(num_samples)

		for i = 1,num_samples do

			local t = gen.sample / gen.sample_rate
			mix[i] = 0

			if gen.noise then
				mix[i] = math.random() < 0.1 and 1 or 0
			end

			for note_index,note in ipairs(gen.notes) do

				local freq = 2 ^ (note / 12) * 440
				local period = 1 / freq

				local x = (t % period) / period
				local high = x < gen.ratio

				if gen.arp then  -- play one note at a time
					local which = math.floor((t % gen.arp_period) / gen.arp_period * #gen.notes) + 1
					if note_index == which then
						mix[i] = high and 1 or 0
					end
				else 	-- boolean OR all the samples
					if high then
						mix[i] = 1
					end
				end
			end

			gen.sample = gen.sample + 1
		end

		return mix
	end

	return gen
end

return
{
	new = new
}
