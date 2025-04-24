--- @class P4_Context
--- @field current_client P4_Current_Client? Current client
local P4_Context = {}

-- Check if telescope is supported
 local has_telescope, _ = pcall(require, "telescope")

 if has_telescope then

   P4_Context.telescope = true
 else
   P4_Context.telescope = false
 end

return P4_Context
