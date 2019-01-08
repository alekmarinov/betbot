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

    if math.min(100 / home, 100 / away) + 100 / draw > math.max(100 / home, 100 / away) then
        if home > away then
            return {1, 1}, {"X", 1}, {2, 2}
        else
            return {2, 1}, {"X", 1}, {1, 2}
        end
    end

end

