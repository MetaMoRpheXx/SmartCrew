require "/scripts/companions/recruitable.lua"

local taskActionSpeechChance = root.assetJson("/smartcrew.config:taskActionSpeechChance")

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

function mmrx_getCrewLounging(args, board)
	return npc.isLounging()
end

function mmrx_setCrewMood(args, board, _, dt)
	local speechWeight = math.random(1, 100)
	local duration = args.duration

	if args.action then
		npc.dance(args.action)
	end

	if args.emote then
		npc.emote(args.emote)
	end

	if args.speech and args.speech ~= "" and speechWeight <= taskActionSpeechChance then
		npc.say(args.speech)
	end

	while duration > 0 do
		dt = coroutine.yield()
		duration = duration - dt
	end

	return true
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

function mmrx_dumpTable(item)
	if type(item) == "table" then

		local tableDump = "{ \n"

		for a, b in pairs(item) do

			if type(k) ~= "number" then
				k = "'" .. k .. "'"
			end

			tableDump = tableDump .. "\t [" .. k .. "] = " .. dump(v) .. "\n"
		end

		return tableDump .. "} "
	else
		return tostring(item)
   end
end
