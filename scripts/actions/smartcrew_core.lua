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
	local crewRole = string.gsub(args.role, "%s+", "")
	local anchorKeysRandom = {}

	anchorKeysRole[crewRole] = {}

	local roleAnchor = anchorKeysRole[crewRole]

	for a, b in pairs(crewAnchor) do
		local objectName = world.entityName(b)

		for c, d in pairs(roleAnchorItems) do
			for e, f in ipairs(d) do
				if c == crewRole and f == objectName then
					roleAnchor[#roleAnchor+1] = a

					-- mmrx_testLog("mmrx_crewFindRoleAnchor", "Added " .. f .. " on " .. crewRole .. " anchorKeysRole table with an entity id of " .. b .. " and key " .. a .. ". Proceeding.")
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

		-- mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. crewRole .. ") found an anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	else

		local anchorIndex = anchorKeysRandom[math.random(1, #anchorKeysRandom)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. crewRole .. ") found a random anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	end
	
end

function mmrx_crewWorkRoleAction(args, board)
	local dayNow = world.day()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local crewTaskMoodAction = taskDefaultActions[math.random(1, #taskDefaultActions)]
	local crewTaskMoodEmote = taskDefaultEmotes[math.random(1, #taskDefaultEmotes)]
	local crewTaskMoodDuration = 2.0
	local crewTaskMoodSpeech = ""

	if roleTaskActions[crewRole] ~= nil and roleTaskActions[crewRole][args.task] ~= nil then
		local crewTaskMood = roleTaskActions[crewRole][args.task][math.random(1, #roleTaskActions[crewRole][args.task])]

		if crewTaskMood["action"] ~= nil then
			crewTaskMoodAction = crewTaskMood["action"]
			-- mmrx_testLog("mmrx_crewWorkRoleAction", "Generated action for " .. crewName .. " (" .. crewRole .. ") " .. crewTaskMoodAction)
		end

		if crewTaskMood["emote"] ~= nil then
			crewTaskMoodEmote = crewTaskMood["emote"][math.random(1, #crewTaskMood["emote"])]
			-- mmrx_testLog("mmrx_crewWorkRoleAction", "Generated emote for " .. crewName .. " (" .. crewRole .. ") " .. crewTaskMoodEmote)
		end

		crewTaskMoodDuration = crewTaskMood["duration"]
		crewTaskMoodSpeech = crewTaskMood["monologue"][math.random(1, #crewTaskMood["monologue"])]

		-- mmrx_testLog("mmrx_crewWorkRoleAction", "Initiating Crew Mood of " .. crewName .. " (" .. crewRole .. ") with a current task of " .. args.task .. " (" .. crewTaskMoodAction .. ", " .. crewTaskMoodEmote .. ", " .. crewTaskMoodSpeech .. ")")

		return true, {action = crewTaskMoodAction, duration = crewTaskMoodDuration, emote = crewTaskMoodEmote, speech = crewTaskMoodSpeech}
	else

		-- mmrx_testLog("mmrx_crewWorkRoleAction", "No Mood to present by " .. crewName .. " (" .. crewRole .. ") for his " .. args.task .. " task. Picking random reaction instead (" .. crewTaskMoodAction .. ", " .. crewTaskMoodEmote .. ")")

		return true, {action = crewTaskMoodAction, duration = crewTaskMoodDuration, emote = crewTaskMoodEmote, speech = crewTaskMoodSpeech}
	end
end

function mmrx_crewPickScheduledTask(args, board)
	local dayNow = world.day()
	local timeNow = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local crewChangeTaskWeight = math.random(1, 100)

	if taskCrewStatus[crewRole .. "_" .. crewName] == nil then
		taskCrewStatus[crewRole .. "_" .. crewName] = {}
		taskCrewStatus[crewRole .. "_" .. crewName][dayNow] = {
			current = 1,
			activities = {}
		}
	end

	if taskCrewStatus[crewRole .. "_" .. crewName][dayNow - 1] ~= nil then
		taskCrewStatus[crewRole .. "_" .. crewName] = {}
		taskCrewStatus[crewRole .. "_" .. crewName][dayNow] = {
			current = 1,
			activities = {}
		}

		-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. crewRole .. ") has done his yesterday's entry (Day " .. dayNow - 1 .. ") and is now erased from his schedule pool. " .. crewName .. " will now be picking schedule for today (Day " .. dayNow .. ").")
	end

	if next(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]) == nil then
		local activityMerge = ""

		if roleScheduleTasks[crewRole] ~= nil and next(roleScheduleTasks[crewRole]) ~= nil then
			-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. crewRole .. ") is about to schedule daily task.")

			for a, b in pairs(roleScheduleTasks[crewRole]) do
				local crewActivity = b["tasks"][math.random(1, #b["tasks"])]
				local crewSchedule = b["time"]
				local crewActivityCount = #taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]

				if activityMerge == crewActivity then
					taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"][crewActivityCount]["schedule"][2] = crewSchedule[2]
				else
					table.insert(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"], {
						task = crewActivity,
						schedule = crewSchedule
					})
				end

				activityMerge = crewActivity
			end
		else
			-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. crewRole .. ") has no default role task. Prewriting based on a random.")
			local tempCounter = 0

			while tempCounter <= 10 do
				local tempStartTime = tempCounter/10
				local tempEndTime = (tempCounter+1)/10
				local crewActivity = taskDefaults[math.random(1, #taskDefaults)]
				local crewSchedule = {tempStartTime, tempEndTime}
				local crewActivityCount = #taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]

				if tempCounter == 10 then
					crewSchedule = {1.0, 0.0}
				end

				if activityMerge == crewActivity then
					taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"][crewActivityCount]["schedule"][2] = crewSchedule[2]
				else
					table.insert(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"], {
						task = crewActivity,
						schedule = crewSchedule
					})
				end

				activityMerge = crewActivity
				tempCounter = tempCounter + 1
			end
		end
	end

	if next(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]) == nil then
		local crewPickedDefaultTask = taskDefaults[math.random(1, #taskDefaults)]

		table.insert(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"], {
			task = crewPickedDefaultTask,
			schedule = crewSchedule
		})

		-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. crewRole .. ") has no picked task and was assigned to " .. crewPickedDefaultTask .. " by default for the current schedule (" .. timeNow .. ")")

		return true, {task = crewPickedDefaultTask}
	else
		for a, b in pairs(taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]) do

			if util.isTimeInRange(timeNow, b["schedule"]) == true then
				taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["current"] = a

				-- mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. crewRole .. ") is now doing " .. b["task"] .. " with a schedule of " .. b["schedule"][1] .. " to " .. b["schedule"][2])

				return true, {task = b["task"]}
			end
		end
	end
end

function mmrx_crewDoScheduledTask(args, board)
	local dayNow = world.day()
	local timeOfDay = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local crewTaskList = taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["activities"]
	local crewCurrent = taskCrewStatus[crewRole .. "_" .. crewName][dayNow]["current"]
	local crewCurrentTask = crewTaskList[crewCurrent]

	-- mmrx_testLog("mmrx_crewDoScheduledTask", crewName .. " (" .. crewRole .. ") agreed to " .. args.taskpick .. " (" .. crewCurrentTask["task"] .. " pulled from table) from " .. crewCurrentTask["schedule"][1] .. " to " .. crewCurrentTask["schedule"][2])

	if args.taskpick == args.taskqueue then
		return true, {duration = crewCurrentTask["schedule"]}
	else
		return false
	end
end
