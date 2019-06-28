require "/scripts/actions/smartcrew_utils.lua"
require "/scripts/util.lua"

local roleAnchorItems = root.assetJson("/smartcrew.config:roleAnchorItems")
local roleScheduleTasks = root.assetJson("/smartcrew.config:roleScheduleTasks")
local shipMarkerItems = root.assetJson("/smartcrew.config:shipMarkerItems")
local anchorKeysRole = {}

function mmrx_crewCheckShip(args, board)

	local shipValidity = world.objectQuery(args.position, 275)

	for h, i in pairs(shipValidity) do
		local objectName = world.entityName(i)

		for a, b in ipairs(shipMarkerItems) do
			if objectName == b then

				mmrx_testLog("mmrx_crewCheckShip", "Ship item (" .. objectName .. ") checked with an entity id of: " .. i .. ". Assuming this crew is on the ship.")

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

	for h, i in pairs(crewAnchor) do
		local objectName = world.entityName(i)

		for a, b in pairs(roleAnchorItems) do
			for c, d in ipairs(b) do
				if a == args.role and d == objectName then
					roleAnchor[#roleAnchor+1] = h

					mmrx_testLog("mmrx_crewFindRoleAnchor", "Added " .. d .. " on " .. args.role .. " anchorKeysRole table with an entity id of " .. i .. " and key " .. h .. ". Proceeding.")
				else
					anchorKeysRandom[#anchorKeysRandom+1] = h
				end
			end
		end
	end

	if next(roleAnchor) ~= nil then

		local anchorIndex = roleAnchor[math.random(1, #roleAnchor)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. args.role .. ") found an anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	else

		local anchorIndex = anchorKeysRandom[math.random(1, #anchorKeysRandom)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		mmrx_testLog("mmrx_crewFindRoleAnchor", crewName .. " (" .. args.role .. ") found a random anchor point " .. anchorName .. " with entity id of: " .. anchorItem)

		return true, {entity = anchorItem}
	end
	
end

function mmrx_crewPickScheduledTask(args, board)
	local timeNow = world.timeOfDay()
	local crewName = world.entityName(args.entity)

	for a, b in pairs(roleScheduleTasks) do
		if a == args.role then
			for c, d in pairs(b) do
				local timeRange = util.isTimeInRange(timeNow, d["time"])

				if timeRange == true then
					local crewPickTask = d["tasks"][math.random(1, #d["tasks"])]

					mmrx_testLog("mmrx_crewPickScheduledTask", crewName .. " (" .. args.role .. ") has " .. crewPickTask .. " task right now (" .. timeNow .. ")")

					return true, {task = crewPickTask}
				end
			end
		end
	end
end

function mmrx_crewDoScheduledTask(args, board)
	local timeOfDay = world.timeOfDay()

	if args.taskpick == args.taskqueue then
		return true
	else
		return false
	end
end
