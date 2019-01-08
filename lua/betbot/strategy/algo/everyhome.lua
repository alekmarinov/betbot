-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everyhome.lua                                     --
-- Description:   Bet on every home                                 --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everyhome", package.seeall)

return function ()
	return {1, 1} -- every match bet 1 on 1
end
