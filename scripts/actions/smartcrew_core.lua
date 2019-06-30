require "/scripts/actions/smartcrew_utils.lua"
require "/scripts/util.lua"

local roleAnchorItems = root.assetJson("/smartcrew.config:roleAnchorItems")
local roleScheduleTasks = root.assetJson("/smartcrew.config:roleScheduleTasks")
local roleTaskActions = root.assetJson("/smartcrew.config:roleTaskActions")
local shipMarkerItems = root.assetJson("/smartcrew.config:shipMarkerItems")
local taskDefaults = root.assetJson("/smartcrew.config:taskDefaults")
local taskDefaultActions = root.assetJson("/smartcrew.config:taskDefaultActions")
local taskDefaultEmotes = root.assetJson("/smartcrew.config:taskDefaultEmotes")
local taskChangeActivityChance = root.assetJson("/smartcrew.config:taskChangeActivityChance")
local anchorKeysRole = {}
local taskCrewStatus = {}

function mmrx_crewCheckShip(args, board)

	local shipValidity = world.objectQuery(args.position, 275)

	for h, i in pairs(shipValidity) do
		local objectName = world.entityName(i)

		for a, b in ipairs(shipMarkerItems) do
			if objectName == b then

				-- mmrx_testLog("mmrx_crewCheckShip", "Ship item (" .. objectName .. ") checked with an entity id of: " .. i .. ". Assuming this crew is on the ship.")

				return true
			end
		end
	end

	return false
end

function mmrx_crewFindRoleAnchor(args, board)
	local crewAnchor = world.objectQuery(args.position, 450)
	local crewName = world.entityName(args.entity)
	local anchorKeysRandom = {}

	anchorKeysRole[args.role] = {}

	local roleAnchor = anchorKeysRole[args.role]

	for a, b in pairs(crewAnchor) do
		local objectName = world.entityName(b)

		for c, d in pairs(roleAnchorItems) do
			for e, f in ipairs(d) do
				if c == args.role and f == objectName then
					roleAnchor[#roleAnchor+1] = a

					-- mmrx_testLog("mmrx_crewFindRoleAnchor", "Added " .. f .. " on " .. args.role .. " anchorKeysRole table with an entity id of " .. b .. " and key " .. a .. ". Proceeding.")
				else
					anchorKeysRandom[#anchorKeysRandom+1] = a
				end
			end
		end
	end

	if next(roleAnchor) ~= nil then

		local anchorIndex = roleAnchor[math.random(1, #roleAnchor)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. args.role .. ") found an anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	else

		local anchorIndex = anchorKeysRandom[math.random(1, #anchorKeysRandom)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. args.role .. ") found a random anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	end
	
end

function mmrx_crewWorkRoleAction(args, board)
	local dayNow = world.day()
	local crewName = world.entityName(args.entity)
	local crewTaskMoodAction = taskDefaultActions[math.random(1, #taskDefaultActions)]
	local crewTaskMoodEmote = taskDefaultEmotes[math.random(1, #taskDefaultEmotes)]
	local crewTaskMoodDuration = 2.0
	local crewTaskMoodSpeech = ""

	if roleTaskActions[args.role] ~= nil and roleTaskActions[args.role][args.task] ~= nil then
		local crewTaskMood = roleTaskActions[args.role][args.task][math.random(1, #roleTaskActions[args.role][args.task])]

		if crewTaskMood["action"] ~= nil then
			crewTaskMoodAction = crewTaskMood["action"]
			-- mmrx_testLog("mmrx_crewWorkRoleAction", "Generated action for " .. crewName .. " (" .. args.role .. ") " .. crewTaskMoodAction)
		end

		if crewTaskMood["emote"] ~= nil then
			crewTaskMoodEmote = crewTaskMood["emote"][math.random(1, #crewTaskMood["emote"])]
			-- mmrx_testLog("mmrx_crewWorkRoleAction", "Generated emote for " .. crewName .. " (" .. args.role .. ") " .. crewTaskMoodEmote)
		end

		crewTaskMoodDuration = crewTaskMood["duration"]
		crewTaskMoodSpeech = crewTaskMood["monologue"][math.random(1, #crewTaskMood["monologue"])]

		-- mmrx_testLog("mmrx_crewWorkRoleAction", "Initiating Crew Mood of " .. crewName .. " (" .. args.role .. ") with a current task of " .. args.task .. " (" .. crewTaskMoodAction .. ", " .. crewTaskMoodEmote .. ", " .. crewTaskMoodSpeech .. ")")

		return true, {action = crewTaskMoodAction, duration = crewTaskMoodDuration, emote = crewTaskMoodEmote, speech = crewTaskMoodSpeech}
	else

		-- mmrx_testLog("mmrx_crewWorkRoleAction", "No Mood to present by " .. crewName .. " (" .. args.role .. ") for his " .. args.task .. " task. Picking random reaction instead (" .. crewTaskMoodAction .. ", " .. crewTaskMoodEmote .. ")")

		return true, {action = crewTaskMoodAction, duration = crewTaskMoodDuration, emote = crewTaskMoodEmote, speech = crewTaskMoodSpeech}
	end
end

function mmrx_crewPickScheduledTask(args, board)
	local dayNow = world.day()
	local timeNow = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewChangeTaskWeight = math.random(1, 100)
	local activityMerge = ""

	if taskCrewStatus[args.role .. "_" .. crewName] == nil then
		taskCrewStatus[args.role .. "_" .. crewName] = {}
		taskCrewStatus[args.role .. "_" .. crewName][dayNow] = {
			current = 1,
			activities = {}
		}
	end

	if taskCrewStatus[args.role .. "_" .. crewName][dayNow - 1] ~= nil then
		taskCrewStatus[args.role .. "_" .. crewName] = {}
		taskCrewStatus[args.role .. "_" .. crewName][dayNow] = {
			current = 1,
			activities = {}
		}

		-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. args.role .. ") has done his yesterday's entry (Day " .. dayNow - 1 .. ") and is now erased from his schedule pool. " .. crewName .. " will now be picking schedule for today (Day " .. dayNow .. ").")
	end

	if next(taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"]) == nil then
		for a, b in pairs(roleScheduleTasks) do
			if a == args.role then
				for c, d in pairs(b) do
					local crewActivity = d["tasks"][math.random(1, #d["tasks"])]
					local crewSchedule = d["time"]
					local crewActivityCount = #taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"]

					if activityMerge == crewActivity then
						taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"][crewActivityCount]["schedule"][2] = crewSchedule[2]
					else
						table.insert(taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"], {
							task = crewActivity,
							schedule = crewSchedule
						})
					end

					activityMerge = crewActivity
				end

				break
			end
		end
	end

	if next(taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"]) == nil then
		local crewPickedDefaultTask = taskDefaults[math.random(1, #taskDefaults)]

		-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. args.role .. ") has no picked task and was assigned to " .. crewPickedDefaultTask .. " by default for the current schedule (" .. timeNow .. ")")

		return true, {task = crewPickedDefaultTask}
	else
		for a, b in pairs(taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"]) do

			if util.isTimeInRange(timeNow, b["schedule"]) == true then
				taskCrewStatus[args.role .. "_" .. crewName][dayNow]["current"] = a

				-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. args.role .. ") is now doing " .. b["task"] .. " with a schedule of " .. b["schedule"][1] .. " to " .. b["schedule"][2])

				return true, {task = b["task"]}
			end
		end
	end
end

function mmrx_crewDoScheduledTask(args, board)
	local dayNow = world.day()
	local timeOfDay = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewTaskList = taskCrewStatus[args.role .. "_" .. crewName][dayNow]["activities"]
	local crewCurrent = taskCrewStatus[args.role .. "_" .. crewName][dayNow]["current"]
	local crewCurrentTask = crewTaskList[crewCurrent]

	-- mmrx_testLog("mmrx_crewDoScheduledTask", crewName .. " (" .. args.role .. ") agreed to " .. args.taskpick .. " (" .. crewCurrentTask["task"] .. " pulled from table) from " .. crewCurrentTask["schedule"][1] .. " to " .. crewCurrentTask["schedule"][2])

	if args.taskpick == args.taskqueue then
		return true, {duration = crewCurrentTask["schedule"]}
	else
		return false
	end
end
