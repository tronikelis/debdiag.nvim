local utils = require("debdiag.utils")

local M = {
    config = {
        --- the command which will disable and enable the diagnostics after debounce
        autocmd = "TextChangedI",
        --- enable diagnostics after leaving insert mode
        enable_leave_insert = true,
        --- debounce timer
        ms = 600,
    },
}

function M.setup(config)
    config = config or {}
    M.config = vim.tbl_deep_extend("force", M.config, config)

    ---@type table<integer, boolean?>
    local disabled_map = {}

    ---@param bufnr integer
    local function enable_diagnostics(bufnr)
        if disabled_map[bufnr] then
            vim.diagnostic.enable(true, { bufnr = bufnr })
            disabled_map[bufnr] = false
        end
    end
    ---@param bufnr integer
    local function disable_diagnostics(bufnr)
        if not disabled_map[bufnr] then
            vim.diagnostic.enable(false, { bufnr = bufnr })
            disabled_map[bufnr] = true
        end
    end

    local debounced_enable_diagnostics = utils.debounce(function(buf)
        if vim.api.nvim_buf_is_valid(buf) then
            enable_diagnostics(buf)
        end
    end, M.config.ms)

    vim.api.nvim_create_autocmd(M.config.autocmd, {
        callback = vim.schedule_wrap(function()
            local buf = vim.api.nvim_get_current_buf()

            disable_diagnostics(buf)
            debounced_enable_diagnostics(buf)
        end),
    })

    if M.config.enable_leave_insert then
        vim.api.nvim_create_autocmd("InsertLeave", {
            callback = function()
                local buf = vim.api.nvim_get_current_buf()
                enable_diagnostics(buf)
            end,
        })
    end
end

return M
