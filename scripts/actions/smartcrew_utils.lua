require "/scripts/companions/recruitable.lua"

local prevLogType = ""
local enableLog = true;

function mmrx_getCrewRole(args, board)
	local crewDetails = config.getParameter("crew.role", {})

	for h,i in pairs(crewDetails) do
		if type(i) == "table" then
			-- future reference
		else
			if h == "name" then
				return true, {role = i}
			end
		end
	end
end

function mmrx_getTime(args, board)
	local shipCurrentDay = world.day()
	local shipCurrentDayLength = world.dayLength()
	local shipTime = world.time()
	local shipTimeNow = world.timeOfDay()

	mmrx_testLog("mmrx_crewCheckTime", "Current Day: " .. shipCurrentDay)
	mmrx_testLog("mmrx_crewCheckTime", "Current Day Length: " .. shipCurrentDayLength)
	mmrx_testLog("mmrx_crewCheckTime", "Time: " .. shipTime)
	mmrx_testLog("mmrx_crewCheckTime", "Now: " .. shipTimeNow)

	return true, {timeworld = shipTime, timenow = shipTimeNow}
end

function mmrx_testLog(type, log)

	if enableLog == true then

		if prevLogType == type then
			sb.logInfo(log)
		else
			prevLogType = type
			sb.logInfo("")
			sb.logInfo(log)
		end
	end
end
