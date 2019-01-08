-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      highcombo.lua                                      --
-- Description:   Bet on higher odd when higher - draw < lower       --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.highcombo", package.seeall)

return function (home, draw, away)
	if math.min(home, away)  + draw > math.max(home, away) then
		if home > away then
			return {1, 1}
		else
			return {2, 1}
		end
	end
end
