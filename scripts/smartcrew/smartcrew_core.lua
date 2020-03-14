require "/scripts/smartcrew/smartcrew_utils.lua"
require "/scripts/util.lua"

local roleAnchorItems = root.assetJson("/smartcrew.config:roleAnchorItems")
local roleScheduleTasks = root.assetJson("/smartcrew.config:roleScheduleTasks")
local roleTaskReactions = root.assetJson("/smartcrew.config:roleTaskReactions")
local shipMarkerItems = root.assetJson("/smartcrew.config:shipMarkerItems")
local taskDefaults = root.assetJson("/smartcrew.config:taskDefaults")
local taskChangeActivityChance = root.assetJson("/smartcrew.config:taskChangeActivityChance")
local taskCrewAct = {}

function smartcrew_isInsideShip(args, board)
	local shipValidity = world.objectQuery(args.position, 275)

	for h, i in pairs(shipValidity) do
		local objectName = world.entityName(i)

		for a, b in ipairs(shipMarkerItems) do
			if objectName == b then

				-- setTestLog("isInsideShip", "Ship item (" .. objectName .. ") checked with an entity id of: " .. i .. ". Assuming this crew is on the ship.")

				return true
			end
		end
	end

	return false
end

function smartcrew_getRoleAnchor(args, board)
	local crewAnchor = world.objectQuery(args.position, 450)
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local anchorKeysRole = {}
	local anchorKeysRandom = {}

	for a, b in pairs(crewAnchor) do
		local objectName = world.entityName(b)

		if roleAnchorItems[crewRole] ~= nil then
			for c, d in pairs(roleAnchorItems[crewRole]) do
				if d == objectName then
					anchorKeysRole[#anchorKeysRole+1] = a
					-- setTestLog("getRoleAnchor", "Added " .. d .. " on " .. crewRole .. " anchorKeysRole table with an entity id of " .. b .. " and key " .. a .. ". Proceeding.")
				elseif #anchorKeysRandom <= 15 then
					anchorKeysRandom[#anchorKeysRandom+1] = a
				end
			end
		elseif #anchorKeysRandom <= 15 then
			anchorKeysRandom[#anchorKeysRandom+1] = a
		end
	end

	if roleAnchorItems[crewRole] ~= nil and next(anchorKeysRole) ~= nil then

		local anchorIndex = anchorKeysRole[math.random(1, #anchorKeysRole)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- setTestLog("getRoleAnchor", crewName .. " (" .. crewRole .. ") found an anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	else

		local anchorIndex = anchorKeysRandom[math.random(1, #anchorKeysRandom)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- setTestLog("getRoleAnchor", crewName .. " (" .. crewRole .. ") found a random anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	end
	
end

function smartcrew_getTaskCurrent(args, board)
	local dayNow = world.day()
	local timeNow = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")

	if taskCrewAct[crewRole .. "_" .. crewName] ~= nil and taskCrewAct[crewRole .. "_" .. crewName][dayNow] ~= nil then
		local crewTasks =  taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]
		local crewTaskCurrent =  taskCrewAct[crewRole .. "_" .. crewName][dayNow]["current"]

		if util.isTimeInRange(timeNow, crewTasks[crewTaskCurrent]["schedule"]) == true then

			-- setTestLog("getTaskCurrent", crewName .. " (" .. crewRole .. ") is currently doing " .. crewTasks[crewTaskCurrent]["task"] .. " up until ".. crewTasks[crewTaskCurrent]["schedule"][2] .. " (Current Time: " .. timeNow .. ")")

			return true
		else
			-- setTestLog("getTaskCurrent", crewName .. " (" .. crewRole .. ") task " .. crewTasks[crewTaskCurrent]["task"] .. " is past the schedule, changing... (Current Time: " .. timeNow .. ")")

			return false
		end
	else
		return false
	end
end

function smartcrew_getTaskSetup(args, board)
	local dayNow = world.day()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")

	if taskCrewAct[crewRole .. "_" .. crewName] ~= nil and taskCrewAct[crewRole .. "_" .. crewName][dayNow] ~= nil then
		local crewTaskList = taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]
		local crewCurrent = taskCrewAct[crewRole .. "_" .. crewName][dayNow]["current"]
		local crewCurrentTask = crewTaskList[crewCurrent]

		if args.taskpick == args.taskqueue then
			-- setTestLog("getTaskDuration", crewName .. " (" .. crewRole .. ") agreed to " .. args.taskpick .. " (" .. crewCurrentTask["task"] .. " pulled from table) from " .. crewCurrentTask["schedule"][1] .. " to " .. crewCurrentTask["schedule"][2])

			return true, {duration = crewCurrentTask["schedule"]}
		else
			return false
		end
	else
		-- setTestLog("getTaskDuration", "No tasks found, skipping")

		return false
	end
end

function smartcrew_setTaskReaction(args, board)
	local dayNow = world.day()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local crewReaction = nil
	local crewEmote = nil
	local crewReactionDuration = math.random(1, 10)
	local crewMonologue = ""

	if roleTaskReactions[crewRole] ~= nil and roleTaskReactions[crewRole][args.task] ~= nil then
		local crewReact = roleTaskReactions[crewRole][args.task][math.random(1, #roleTaskReactions[crewRole][args.task])]

		crewReactType = crewReact["type"]
		crewReaction = crewReact["reaction"]
		crewMonologue = crewReact["monologue"][math.random(1, #crewReact["monologue"])]

		if crewReactType == "custom" then
			
			crewEmote = crewReact["emote"][math.random(1, #crewReact["emote"])]
			crewReactionDuration = crewReact["duration"]

			-- setTestLog("setTaskReaction", "Initiating Crew " .. crewReactType .. " reaction of " .. crewName .. " (" .. crewRole .. ") with a current task of " .. args.task .. " (" .. crewReaction .. ", " .. crewEmote .. ", " .. crewMonologue .. ")")

			return true, {duration = crewReactionDuration, emote = crewEmote, reaction = crewReaction, speech = crewMonologue, type = "custom"}

		elseif crewReactType ~= "custom" then

			-- setTestLog("setTaskReaction", "Initiating Crew " .. crewReactType .. " reaction of " .. crewName .. " (" .. crewRole .. ") with a current task of " .. args.task .. " (" .. crewReaction .. ", " .. crewMonologue .. ")")

			return true, {duration = nil, emote = nil, reaction = crewReaction, speech = crewMonologue, type = crewReactType}

		end

	else
		local crewReact = roleTaskReactions["_default"][args.task][math.random(1, #roleTaskReactions["_default"][args.task])]

		if crewReact["type"] ~= nil then

			crewReaction = crewReact["reaction"]
			crewEmote = crewReact["emote"][math.random(1, #crewReact["emote"])]
			crewReactionDuration = crewReact["duration"]
			crewMonologue = crewReact["monologue"][math.random(1, #crewReact["monologue"])]

			-- setTestLog("setTaskReaction", "No Mood to present by " .. crewName .. " (" .. crewRole .. ") for his " .. args.task .. " task. Picking random reaction instead (" .. crewReaction .. ", " .. crewEmote .. ")")

			return true, {duration = crewReactionDuration, emote = crewEmote, reaction = crewReaction, speech = crewMonologue}

		else 

			return false

		end
	end
end

function smartcrew_setTaskSchedule(args, board)
	local dayNow = world.day()
	local timeNow = world.timeOfDay()
	local crewName = world.entityName(args.entity)
	local crewRole = string.gsub(args.role, "%s+", "")
	local crewChangeTaskWeight = math.random(1, 100)

	if taskCrewAct[crewRole .. "_" .. crewName] == nil then
		taskCrewAct[crewRole .. "_" .. crewName] = {}
		taskCrewAct[crewRole .. "_" .. crewName][dayNow] = {
			prevact = "",
			current = 1,
			activities = {}
		}
	end

	if taskCrewAct[crewRole .. "_" .. crewName][dayNow] == nil then
		taskCrewAct[crewRole .. "_" .. crewName] = {}
		taskCrewAct[crewRole .. "_" .. crewName][dayNow] = {
			prevact = "",
			current = 1,
			activities = {}
		}

		-- setTestLog("setTaskSchedule", crewName .. " (" .. crewRole .. ") has done his yesterday's entry and is now erased from his schedule pool. " .. crewName .. " will now be picking schedule for today (Day " .. dayNow .. ").")
	end

	if taskCrewAct[crewRole .. "_" .. crewName][dayNow] ~= nil and next(taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]) == nil then
		local activityMerge = ""

		if roleScheduleTasks[crewRole] ~= nil and next(roleScheduleTasks[crewRole]) ~= nil then
			-- setTestLog("setTaskSchedule", crewName .. " (" .. crewRole .. ") is about to schedule daily task.")

			for a, b in pairs(roleScheduleTasks[crewRole]) do
				local crewActivity = b["tasks"][math.random(1, #b["tasks"])]
				local crewSchedule = b["time"]
				local crewActivityCount = #taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]

				if activityMerge == crewActivity then
					taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"][crewActivityCount]["schedule"][2] = crewSchedule[2]
				else
					table.insert(taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"], {
						task = crewActivity,
						schedule = crewSchedule
					})
				end

				activityMerge = crewActivity
			end
		else
			-- setTestLog("setTaskSchedule", crewName .. " (" .. crewRole .. ") has no default role task. Prewriting based on a random.")

			local tempCounter = 0

			while tempCounter <= 10 do
				local tempStartTime = tempCounter/10
				local tempEndTime = (tempCounter+1)/10
				local crewActivity = taskDefaults[math.random(1, #taskDefaults)]
				local crewSchedule = {tempStartTime, tempEndTime}
				local crewActivityCount = #taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]

				if tempCounter == 10 then
					crewSchedule = {1.0, 0.0}
				end

				if activityMerge == crewActivity then
					taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"][crewActivityCount]["schedule"][2] = crewSchedule[2]
				else
					table.insert(taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"], {
						task = crewActivity,
						schedule = crewSchedule
					})
				end

				activityMerge = crewActivity
				tempCounter = tempCounter + 1
			end
		end
	end

	for a, b in pairs(taskCrewAct[crewRole .. "_" .. crewName][dayNow]["activities"]) do
		if util.isTimeInRange(timeNow, b["schedule"]) == true then

			if b["task"] ~= taskCrewAct[crewRole .. "_" .. crewName][dayNow]["prevact"] then
				-- setTestLog("setTaskSchedule", crewName .. " (" .. crewRole .. ") is now doing " .. b["task"] .. " with a schedule of " .. b["schedule"][1] .. " to " .. b["schedule"][2] .. " (Current Time: " .. timeNow .. ")")
			elseif b["task"] == taskCrewAct[crewRole .. "_" .. crewName][dayNow]["prevact"] and crewChangeTaskWeight <= taskChangeActivityChance then
				-- setTestLog("setTaskSchedule", crewName .. " (" .. crewRole .. ") will modify his " .. b["task"] .. " a little bit. It's still going on from " .. b["schedule"][1] .. " to " .. b["schedule"][2] .. " (Current Time: " .. timeNow .. ")")
			else
				return false
			end

			taskCrewAct[crewRole .. "_" .. crewName][dayNow]["prevact"] = b["task"]
			taskCrewAct[crewRole .. "_" .. crewName][dayNow]["current"] = a

			return true, {task = b["task"]}
		end
	end

	return false
end
