-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.

return {
    'mfussenegger/nvim-dap',
    dependencies = {
        -- Creates a beautiful debugger UI
        'rcarriga/nvim-dap-ui',

        -- Required dependency for nvim-dap-ui
        'nvim-neotest/nvim-nio',

        -- Installs the debug adapters for you
        'williamboman/mason.nvim',
        'jay-babu/mason-nvim-dap.nvim',

        -- Add your own debuggers here
        'leoluz/nvim-dap-go',
    },
    config = function()
        local dap = require 'dap'
        local dapui = require 'dapui'

        require('mason-nvim-dap').setup {
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_setup = true,

            -- You can provide additional configuration to the handlers,
            -- see mason-nvim-dap README for more information
            handlers = {},

            -- You'll need to check that you have the required things installed
            -- online, please don't ask me how to install them :)
            ensure_installed = {},
        }


        local function continue()
            if vim.fn.filereadable(".vscode/launch.json") == 1 then
                require("dap.ext.vscode").load_launchjs()
            end
            dap.continue()
        end

        -- Basic debugging keymaps, feel free to change to your liking!
        vim.keymap.set('n', '<F5>', continue, { desc = 'Debug: Start/Continue' })
        vim.keymap.set('n', '<F6>', dap.step_into, { desc = 'Debug: Step Into' })
        vim.keymap.set('n', '<F7>', dap.step_over, { desc = 'Debug: Step Over' })
        vim.keymap.set('n', '<F8>', dap.step_out, { desc = 'Debug: Step Out' })
        vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
        vim.keymap.set('n', '<leader>B', function()
            dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end, { desc = 'Debug: Set Breakpoint' })

        -- Dap UI setup
        -- For more information, see |:help nvim-dap-ui|
        dapui.setup {
            -- Set icons to characters that are more likely to work in every terminal.
            --    Feel free to remove or use ones that you like more! :)
            --    Don't feel like these are good choices.
            icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
            controls = {
                icons = {
                    pause = '⏸',
                    play = '▶',
                    step_into = '⏎',
                    step_over = '⏭',
                    step_out = '⏮',
                    step_back = 'b',
                    run_last = '▶▶',
                    terminate = '⏹',
                    disconnect = '⏏',
                },
            },
        }

        -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
        vim.keymap.set('n', '<F4>', dapui.toggle, { desc = 'Debug: See last session result.' })

        dap.listeners.after.event_initialized['dapui_config'] = dapui.open
        dap.listeners.before.event_terminated['dapui_config'] = dapui.close
        dap.listeners.before.event_exited['dapui_config'] = dapui.close

        local path_delve = "dlv"
        if vim.loop.os_uname().sysname == "Windows_NT" then
            path_delve = vim.fn.expand("$HOME") .. "\\AppData\\Local\\nvim-data\\mason\\bin\\dlv.cmd"
        end

        -- Install golang specific config
        require('dap-go').setup({
            -- Additional dap configurations can be added.
            -- dap_configurations accepts a list of tables where each entry
            -- represents a dap configuration. For more details do:
            -- :help dap-configuration
            -- delve configurations
            delve = {
                -- the path to the executable dlv which will be used for debugging.
                -- by default, this is the "dlv" executable on your PATH.
                path = path_delve,
                -- time to wait for delve to initialize the debug session.
                -- default to 20 seconds
                initialize_timeout_sec = 20,
                -- a string that defines the port to start delve debugger.
                -- default to string "${port}" which instructs nvim-dap
                -- to start the process in a random available port
                port = "38697",
                -- additional args to pass to dlv
                args = {},
                -- the build flags that are passed to delve.
                -- defaults to empty string, but can be used to provide flags
                -- such as "-tags=unit" to make sure the test suite is
                -- compiled during debugging, for example.
                -- passing build flags using args is ineffective, as those are
                -- ignored by delve in dap mode.
                -- build_flags = "",
                -- whether the dlv process to be created detached or not. there is
                -- an issue on Windows where this needs to be set to false
                -- otherwise the dlv server creation will fail.
                detached = true
            },
            enrich_config = function(finalConfig, on_config)
                local final_config = vim.deepcopy(finalConfig)

                -- Placeholder expansion for launch directives
                local placeholders = {
                    ["${file}"] = function(_)
                        return vim.fn.expand("%:p")
                    end,
                    ["${fileBasename}"] = function(_)
                        return vim.fn.expand("%:t")
                    end,
                    ["${fileBasenameNoExtension}"] = function(_)
                        return vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r")
                    end,
                    ["${fileDirname}"] = function(_)
                        return vim.fn.expand("%:p:h")
                    end,
                    ["${fileExtname}"] = function(_)
                        return vim.fn.expand("%:e")
                    end,
                    ["${relativeFile}"] = function(_)
                        return vim.fn.expand("%:.")
                    end,
                    ["${relativeFileDirname}"] = function(_)
                        return vim.fn.fnamemodify(vim.fn.expand("%:.:h"), ":r")
                    end,
                    ["${workspaceFolder}"] = function(_)
                        return vim.fn.getcwd()
                    end,
                    ["${workspaceFolderBasename}"] = function(_)
                        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                    end,
                    ["${env:([%w_]+)}"] = function(match)
                        return os.getenv(match) or ""
                    end,
                }

                if final_config.envFile then
                    local filePath = final_config.envFile
                    for key, fn in pairs(placeholders) do
                        filePath = filePath:gsub(key, fn)
                    end

                    for line in io.lines(filePath) do
                        local words = {}
                        for word in string.gmatch(line, "[^=]+") do
                            table.insert(words, word)
                        end
                        if not final_config.env then
                            final_config.env = {}
                        end
                        final_config.env[words[1]] = words[2]
                    end
                end

                on_config(final_config)
            end,

        })
    end,
    cond = Not_vscode()
}
