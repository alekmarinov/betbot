-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everyhigh.lua                                      --
-- Description:   Bet on every higher odd                            --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everyhigh", package.seeall)

return function (home, _, away)
	if home > away then
		return {1, 1}
	else
		return {2, 1}
	end
end
