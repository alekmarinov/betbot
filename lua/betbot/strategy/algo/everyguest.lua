-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everyguest.lua                                     --
-- Description:   Bet on every guest                                 --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everyguest", package.seeall)

return function ()
	return {2, 1} -- every match bet 1 on 2
end
