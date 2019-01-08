-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everydrawhigh.lua                                  --
-- Description:   Every draw/high strategy                           --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everydrawhigh", package.seeall)

return function (home, _, away)
	if home > away then
		return {1, 1}, {"X", 1}
	else
		return {2, 1}, {"X", 1}
	end
end
