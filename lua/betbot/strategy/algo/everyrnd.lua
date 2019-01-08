-----------------------------------------------------------------------
--                                                                   --
-- Copyright (C) 2003-2009,  AVIQ Bulgaria Ltd                       --
--                                                                   --
-- Project:       BetBot                                             --
-- Filename:      everyrnd.lua                                       --
-- Description:   Every macth random bet                             --
--                                                                   --
-----------------------------------------------------------------------

module ("betbot.strategy.everyrnd", package.seeall)

math.randomseed(1234)

return function ()
	local rnd = math.random(3)
	if rnd == 1 then
		return {1, 1}
	elseif rnd == 2 then
		return {"X", 1}
	else
		return {2, 1}
	end
end
