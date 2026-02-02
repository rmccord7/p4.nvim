---@meta

--- Represents a file path.
--- @alias Local_File_Path string Local path to the file.
--- @alias Depot_File_Path string Depot path to the file.
--- @alias Client_File_Path string Client path to the file.
--- @alias File_Path Local_File_Path | Depot_File_Path | Client_File_Path Any file path.

--- Represents a file path or multiple file paths using wildcards.
--- @alias Local_File_Spec string Local file syntax.
--- @alias Depot_File_Spec string Depot file syntax.
--- @alias Client_File_Spec string Client file syntax.
--- @alias File_Spec Local_File_Spec | Depot_File_Spec | Client_File_Spec Any file syntax.

--- @class P4_File_Depot_Path
--- @field depot_path Depot_File_Path Depot path to the file.
--- @field local_path Local_File_Path? Optional local path to the file.

---@class P4_Date_Time
---@field date string Date
---@field time string Time


