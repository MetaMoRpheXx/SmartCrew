require "/scripts/companions/recruitable.lua"
require "/scripts/actions/reaction.lua"

local taskActionSpeechChance = root.assetJson("/smartcrew.dev.config:taskActionSpeechChance")

local prevLogType = ""
local enableLog = true;

function dumpTable(item)
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

function smartcrew_getCrewLoungeStatus(args, board)
	return npc.isLounging()
end

function smartcrew_getCrewRole(args, board)
	local crewRoleName = config.getParameter("crew.role.name", {})

	return true, {role = crewRoleName}
end

function smartcrew_setCrewReaction(args, board, _, dt)
	local speechWeight = math.random(1, 100)
	local duration = args.duration

	if args.type == "custom" then

		if args.reaction then
			npc.dance(args.reaction)
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

		return false

	else

		if args.speech and args.speech ~= "" and speechWeight <= taskActionSpeechChance then
			npc.say(args.speech)
		end

		return true

	end

end

function setTestLog(type, log)

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
