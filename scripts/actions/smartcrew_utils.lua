require "/scripts/companions/recruitable.lua"

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