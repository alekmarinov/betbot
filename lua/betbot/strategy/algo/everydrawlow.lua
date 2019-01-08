-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everydrawlow.lua                                  --
-- Description:   Every draw/low strategy                           --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everydrawlow", package.seeall)

return function (home, _, away)
	if home > away then
		return {2, 1}, {"X", 1}
	else
		return {1, 1}, {"X", 1}
	end
end
