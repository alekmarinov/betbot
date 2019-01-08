-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      highcombolimited.lua                               --
-- Description:   Bet on higher odd when higher - draw < lower       --
--                and lower is not higher than a limit               --
--                                                                   --
-----------------------------------------------------------------------

return function (home, draw, away, tid1, tid2, limit)
	limit = tonumber(limit)
	if math.min(home, away) > math.max(home, away) - draw and math.min(home, away) < limit then
		if home > away then
			return {1, 1}
		else
			return {2, 1}
		end
	end
end
