local roleAnchorItems = root.assetJson("/anchors.config:roleAnchorItems")
local shipMarkerItems = root.assetJson("/anchors.config:shipMarkerItems")
local anchorKeysRole = {}

function mmrx_crewCheckShip(args, board)

	local shipValidity = world.objectQuery(args.position, 275)

	for h, i in pairs(shipValidity) do
		local objectName = world.entityName(i)

		for a, b in ipairs(shipMarkerItems) do
			if objectName == b then
				-- sb.logInfo("")
				-- sb.logInfo("Ship item (" .. objectName .. ") checked with an entity id of: " .. i .. ". Assuming this crew is on the ship.")

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

					-- sb.logInfo("Added " .. d .. " on " .. args.role .. " anchorKeysRole table with an entity id of " .. i .. " and key " .. h .. ". Proceeding.")
					-- sb.logInfo("")
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

		-- sb.logInfo(crewName .. " (" .. args.role .. ") found an anchor point " .. anchorName .. " with entity id of: " .. anchorItem)
		-- sb.logInfo("")

		return true, {entity = anchorItem}
	else

		local anchorIndex = anchorKeysRandom[math.random(1, #anchorKeysRandom)]
		local anchorItem = crewAnchor[anchorIndex]
		local anchorName = world.entityName(anchorItem)

		-- sb.logInfo(crewName .. " (" .. args.role .. ") found a random anchor point " .. anchorName .. " with entity id of: " .. anchorItem)
		-- sb.logInfo("")

		return true, {entity = anchorItem}
	end
	
end