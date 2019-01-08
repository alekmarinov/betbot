-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everylow.lua                                      --
-- Description:   Bet on every lower odd                            --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everylow", package.seeall)

return function (home, _, away)
	if home > away then
		return {2, 1}
	else
		return {1, 1}
	end
end
