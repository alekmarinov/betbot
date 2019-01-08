-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      test.lua                                           --
-- Description:   test strategy algorithm                            --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.test", package.seeall)

return function (home, draw, away)
	return {1, 1}, {"X", 1}, {2, 1}
end
