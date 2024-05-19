---@class P4Commands
local M = {}

M.file = require("p4.commands.file")
M.cl = require("p4.commands.cl")
M.client = require("p4.commands.client")
M.login = require("p4.commands.login").login

return M
