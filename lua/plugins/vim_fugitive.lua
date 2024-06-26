return {
    "tpope/vim-fugitive",
    config = function()
        local fugitiveMaps = vim.api.nvim_create_augroup("fugitive-maps", {})

        local autocmd = vim.api.nvim_create_autocmd
        autocmd("BufWinEnter", {
            group = fugitiveMaps,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local opts = { buffer = bufnr, remap = false }
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git('push')
                end, opts)

                -- rebase always
                vim.keymap.set("n", "<leader>f", function()
                    vim.cmd.Git({ 'pull', '--rebase' })
                end, opts)
            end,
        })
    end,
    cond = Not_vscode()
}
