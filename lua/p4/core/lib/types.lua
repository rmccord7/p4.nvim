---@meta

--- Represents a file path.
---@alias Local_File_Path string Local path to the file.
---@alias Depot_File_Path string Depot path to the file.
---@alias Client_File_Path string Client path to the file.
---@alias File_Path Local_File_Path | Depot_File_Path | Client_File_Path Any file path.

--- Represents a file path or multiple file paths using wildcards.
---@alias Local_File_Spec string Local file syntax.
---@alias Depot_File_Spec string Depot file syntax.
---@alias Client_File_Spec string Client file syntax.
---@alias File_Spec Local_File_Spec | Depot_File_Spec | Client_File_Spec Any file syntax.

---@class P4_Date_Time
---@field date string Date
---@field time string Time

---@class P4_File_Info
---@field clientFile Client_File_Path? Local path to the file.
---@field depotFile Depot_File_Path? Depot path to the file.
---@field isMapped boolean? Indicates if file is mapped to the current client workspace.
---@field shelved boolean? Indicates if file is shelved.
---@field change string? Open change list number if file is opened in client workspace.
---@field headRev integer? Head revision number if in depot.
---@field haveRev integer? Revision last synced to workpace.
---@field workRev integer? Revision if file is opened.
---@field action string? Open action if opened in workspace (one of add, edit, delete, branch, move/add, move/delete, integrate, import, purge, or archive).

---@class P4_File_Output
---@field output string File output.
---@field action string Action.
---@field change string Identifies the CL.
---@field depot_file Depot_File_Path Name of the file in the depot for this file.
---@field file_size string Size of the file.
---@field rev string Revision number.
---@field time string Time/date revision was integrated.

---@class P4_Revision
---@field index integer Identifies the revision across branch history (Head revision is 1).
---@field number string Identifies the revision for this branch (Tail revision is 1). P4 branch history will re-use revision numbers for each branch.
---@field depot_file Depot_File_Path Name of the file in the depot for this revision.
---@field action string Action.
---@field change string Identifies the CL.
---@field user string Identifies the user.
---@field client string Identifies the client.
---@field time string Time/date revision was integrated.
---@field description string Description from associated CL.

---@class P4_Revisions
---@field count integer Number of revisions.
---@field list P4_Revision[] List of revisions.
