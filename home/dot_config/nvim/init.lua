vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "help",
  "tabpages",
  "winsize",
  "terminal",
  "localoptions",
}

local undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undodir, "p")
vim.opt.undofile = true
vim.opt.undodir = undodir

local number_toggle = vim.api.nvim_create_augroup("number_toggle", { clear = true })

vim.api.nvim_create_autocmd("InsertEnter", {
  group = number_toggle,
  callback = function()
    vim.opt_local.relativenumber = false
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = number_toggle,
  callback = function()
    vim.opt_local.relativenumber = true
  end,
})

local BIGFILE_SIZE = 2 * 1024 * 1024
local bigfile = vim.api.nvim_create_augroup("bigfile", { clear = true })

vim.api.nvim_create_autocmd("BufReadPre", {
  group = bigfile,
  callback = function(args)
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path == "" then
      return
    end

    local stat = vim.uv.fs_stat(path)
    if not stat or stat.size <= BIGFILE_SIZE then
      return
    end

    vim.b[args.buf].bigfile = true
    vim.bo[args.buf].swapfile = false
    vim.bo[args.buf].undofile = false
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = bigfile,
  callback = function(args)
    if not vim.b[args.buf].bigfile then
      return
    end

    vim.bo[args.buf].bufhidden = "unload"
    vim.api.nvim_buf_call(args.buf, function()
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      pcall(vim.treesitter.stop, args.buf)
    end)
  end,
})

if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

local function in_helm_chart(path)
  local chart = vim.fs.find("Chart.yaml", {
    path = vim.fs.dirname(path),
    upward = true,
  })[1]
  return chart ~= nil
end

vim.filetype.add({
  pattern = {
    [".*%.tfvars$"] = "terraform-vars",
    [".*%.auto%.tfvars$"] = "terraform-vars",
    [".*/docker%-compose[^/]*%.ya?ml"] = "yaml.docker-compose",
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.github",
    [".*/playbooks?/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
    [".*/group_vars/.*%.ya?ml"] = "yaml.ansible",
    [".*/host_vars/.*%.ya?ml"] = "yaml.ansible",
    [".*/inventory/.*%.ya?ml"] = "yaml.ansible",
    [".*/site%.ya?ml"] = "yaml.ansible",
    [".*/playbook%.ya?ml"] = "yaml.ansible",
    [".*/templates/.*%.ya?ml"] = function(path)
      if in_helm_chart(path) then
        return "helm"
      end
    end,
    [".*/values%.ya?ml"] = function(path)
      if in_helm_chart(path) then
        return "yaml.helm-values"
      end
    end,
  },
})

vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {
  desc = "Alias to :checkhealth vim.lsp",
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim")
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    keys = {
      {
        "<leader>ps",
        function()
          require("persistence").load()
        end,
        desc = "Restore session",
      },
      {
        "<leader>pS",
        function()
          require("persistence").select()
        end,
        desc = "Select session",
      },
      {
        "<leader>pl",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore last session",
      },
      {
        "<leader>pw",
        function()
          require("persistence").save()
        end,
        desc = "Save session",
      },
      {
        "<leader>pr",
        function()
          require("persistence").start()
        end,
        desc = "Resume session saving",
      },
      {
        "<leader>pd",
        function()
          require("persistence").stop()
        end,
        desc = "Stop session saving",
      },
    },
    opts = {
      branch = true,
      need = 1,
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      spec = {
        { "<leader>f", group = "find/format" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "lint" },
        { "<leader>o", group = "overseer" },
        { "<leader>p", group = "session" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "terminal" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-mocha",
        globalstatus = true,
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = {
              modified = "[+]",
              readonly = "[-]",
              unnamed = "[No Name]",
            },
          },
        },
        lualine_x = {
          "diagnostics",
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>ff",
        function()
          require("fzf-lua").files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fr",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "Recent files",
      },
      {
        "<leader>/",
        function()
          require("fzf-lua").grep_curbuf()
        end,
        desc = "Grep current buffer",
      },
    },
    opts = {
      winopts = {
        height = 0.85,
        width = 0.90,
      },
      files = {
        cwd_prompt = false,
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'",
      },
    },
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = true,
      columns = { "icon" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      signs_staged_enable = true,
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buffer, desc = desc })
        end

        map("n", "]h", gs.next_hunk, "Next hunk")
        map("n", "[h", gs.prev_hunk, "Prev hunk")
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", gs.blame_line, "Blame line")
        map("n", "<leader>gd", gs.diffthis, "Diff this")
      end,
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter search",
      },
    },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Float terminal" },
      { "<leader>th", "<cmd>ToggleTerm size=15 direction=horizontal<cr>", desc = "Horizontal terminal" },
      { "<leader>tv", "<cmd>ToggleTerm size=80 direction=vertical<cr>", desc = "Vertical terminal" },
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    },
    opts = {
      open_mapping = nil,
      start_in_insert = true,
      persist_size = true,
      persist_mode = true,
      direction = "float",
      float_opts = {
        border = "curved",
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
    end,
  },
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "normal" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      automatic_enable = false,
      ensure_installed = {
        "ansiblels",
        "bashls",
        "docker_compose_language_service",
        "dockerls",
        "gh_actions_ls",
        "helm_ls",
        "jsonls",
        "terraformls",
        "tflint",
        "yamlls",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      run_on_start = true,
      ensure_installed = {
        "actionlint",
        "ansible-language-server",
        "bash-language-server",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "gh-actions-language-server",
        "hadolint",
        "helm-ls",
        "json-lsp",
        "prettierd",
        "shellcheck",
        "shfmt",
        "stylua",
        "terraform-ls",
        "tflint",
        "yaml-language-server",
        "yamllint",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      local function with_capabilities(config)
        return vim.tbl_deep_extend("force", {
          capabilities = capabilities,
        }, config or {})
      end

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = { spacing = 2, source = "if_many" },
        float = { border = "rounded", source = "if_many" },
        signs = true,
        underline = true,
        update_in_insert = false,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol, opts)
          vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol, opts)
        end,
      })

      vim.lsp.config("ansiblels", with_capabilities({
        filetypes = { "yaml.ansible" },
        root_markers = {
          "ansible.cfg",
          ".ansible-lint",
          ".git",
        },
      }))

      vim.lsp.config("docker_compose_language_service", with_capabilities({
        filetypes = { "yaml.docker-compose" },
      }))

      vim.lsp.config("gh_actions_ls", with_capabilities({
        filetypes = { "yaml.github" },
      }))

      vim.lsp.config("lua_ls", with_capabilities({
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            telemetry = {
              enable = false,
            },
          },
        },
      }))

      vim.lsp.config("tombi", with_capabilities({
        cmd = { "tombi", "lsp", "--offline" },
        filetypes = { "toml" },
        root_markers = { ".tombi.toml", "tombi.toml", ".git" },
      }))

      vim.lsp.config("yamlls", with_capabilities({
        filetypes = {
          "yaml",
          "yaml.ansible",
          "yaml.docker-compose",
          "yaml.github",
          "yaml.helm-values",
        },
        settings = {
          yaml = {
            keyOrdering = false,
            schemaStore = {
              enable = true,
            },
            schemas = {
              ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*.{yml,yaml}",
              ["https://json.schemastore.org/github-action.json"] = "/action.{yml,yaml}",
              ["https://json.schemastore.org/chart.json"] = "Chart.yaml",
              ["https://json.schemastore.org/kustomization.json"] = "kustomization.{yml,yaml}",
            },
            validate = true,
            completion = true,
            hover = true,
          },
        },
      }))

      for _, server in ipairs({
        "ansiblels",
        "bashls",
        "docker_compose_language_service",
        "dockerls",
        "gh_actions_ls",
        "helm_ls",
        "jsonls",
        "lua_ls",
        "tombi",
        "terraformls",
        "tflint",
        "yamlls",
      }) do
        vim.lsp.enable(server)
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      require("nvim-treesitter-textobjects").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      {
        "<leader>xx",
        function()
          require("trouble").toggle("diagnostics")
        end,
        desc = "Workspace diagnostics",
      },
      {
        "<leader>xX",
        function()
          require("trouble").toggle("diagnostics", { filter = { buf = 0 } })
        end,
        desc = "Buffer diagnostics",
      },
      {
        "<leader>xq",
        function()
          require("trouble").toggle("quickfix")
        end,
        desc = "Quickfix list",
      },
      {
        "<leader>xl",
        function()
          require("trouble").toggle("loclist")
        end,
        desc = "Location list",
      },
      {
        "<leader>xs",
        function()
          require("trouble").toggle("symbols")
        end,
        desc = "Symbols",
      },
    },
    opts = {
      focus = true,
    },
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Prev todo comment",
      },
      {
        "<leader>xt",
        "<cmd>TodoTrouble<cr>",
        desc = "Todo list",
      },
      {
        "<leader>st",
        function()
          require("fzf-lua").grep({
            search = [[\b(KEYWORDS|TODO|FIX|FIXME|HACK|NOTE|WARN|PERF|TEST):]],
            regex = true,
            no_esc = true,
            prompt = "Todo> ",
          })
        end,
        desc = "Search todo comments",
      },
    },
    opts = {
      signs = true,
      highlight = {
        multiline = false,
      },
      search = {
        pattern = [[\b(KEYWORDS):]],
      },
    },
  },
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerRun",
      "OverseerToggle",
      "OverseerOpen",
      "OverseerClose",
      "OverseerInfo",
      "OverseerTaskAction",
      "OverseerQuickAction",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "akinsho/toggleterm.nvim",
    },
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Toggle task list" },
      { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
      { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Quick task action" },
      { "<leader>oi", "<cmd>OverseerInfo<cr>", desc = "Overseer info" },
    },
    opts = {
      strategy = {
        "toggleterm",
        direction = "horizontal",
        quit_on_exit = "success",
      },
      task_list = {
        direction = "bottom",
        min_height = 10,
        max_height = 20,
        default_detail = 1,
      },
    },
    config = function(_, opts)
      local overseer = require("overseer")

      overseer.setup(opts)

      local function has_executable(cmd)
        return vim.fn.executable(cmd) == 1
      end

      local function current_dir()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= "" then
          return vim.fs.dirname(bufname)
        end
        return vim.fn.getcwd()
      end

      local function register_task(template)
        if template.enabled == false then
          return
        end
        template.enabled = nil
        overseer.register_template(template)
      end

      register_task({
        name = "SRE: Terraform validate",
        desc = "Run terraform validate in the current module directory",
        tags = { "sre", "terraform" },
        condition = {
          filetype = { "terraform" },
        },
        enabled = has_executable("terraform"),
        builder = function()
          return {
            cmd = { "terraform", "validate", "-no-color" },
            cwd = current_dir(),
          }
        end,
      })

      register_task({
        name = "SRE: Terraform plan",
        desc = "Run terraform plan in the current module directory",
        tags = { "sre", "terraform" },
        condition = {
          filetype = { "terraform" },
        },
        enabled = has_executable("terraform"),
        builder = function()
          return {
            cmd = { "terraform", "plan", "-input=false", "-no-color" },
            cwd = current_dir(),
          }
        end,
      })

      register_task({
        name = "SRE: Docker compose ps",
        desc = "Show service state for the current compose project",
        tags = { "sre", "docker" },
        condition = {
          filetype = { "docker-compose" },
        },
        enabled = has_executable("docker"),
        builder = function()
          return {
            cmd = { "docker", "compose", "ps" },
            cwd = current_dir(),
          }
        end,
      })

      register_task({
        name = "SRE: Docker compose logs",
        desc = "Tail recent logs for the current compose project",
        tags = { "sre", "docker" },
        condition = {
          filetype = { "docker-compose" },
        },
        enabled = has_executable("docker"),
        builder = function()
          return {
            cmd = { "docker", "compose", "logs", "--tail=200" },
            cwd = current_dir(),
          }
        end,
      })

      register_task({
        name = "SRE: Kubectl current context",
        desc = "Show the active kubectl context",
        tags = { "sre", "kubernetes" },
        enabled = has_executable("kubectl"),
        builder = function()
          return {
            cmd = { "kubectl", "config", "current-context" },
            cwd = vim.fn.getcwd(),
          }
        end,
      })

      register_task({
        name = "SRE: Kubectl get pods -A",
        desc = "List pods across all namespaces",
        tags = { "sre", "kubernetes" },
        enabled = has_executable("kubectl"),
        builder = function()
          return {
            cmd = { "kubectl", "get", "pods", "-A" },
            cwd = vim.fn.getcwd(),
          }
        end,
      })

      register_task({
        name = "SRE: Kubectl get events -A",
        desc = "Show recent cluster events sorted by timestamp",
        tags = { "sre", "kubernetes" },
        enabled = has_executable("kubectl"),
        builder = function()
          return {
            cmd = {
              "kubectl",
              "get",
              "events",
              "-A",
              "--sort-by=.metadata.creationTimestamp",
            },
            cwd = vim.fn.getcwd(),
          }
        end,
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>ll",
        function()
          require("lint").try_lint()
        end,
        desc = "Lint buffer",
      },
    },
    opts = {
      linters_by_ft = {
        bash = { "shellcheck" },
        dockerfile = { "hadolint" },
        sh = { "shellcheck" },
        terraform = { "tflint" },
        ["yaml"] = { "yamllint" },
        ["yaml.ansible"] = { "yamllint" },
        ["yaml.docker-compose"] = { "yamllint" },
        ["yaml.github"] = { "actionlint", "yamllint" },
        ["yaml.helm-values"] = { "yamllint" },
        zsh = { "shellcheck" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      local lint_group = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_group,
        callback = function()
          local linters = lint.linters_by_ft[vim.bo.filetype]
          if not linters or vim.tbl_isempty(linters) then
            return
          end
          lint.try_lint()
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({
            async = true,
            lsp_format = "fallback",
          })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters = {
        tombi = {
          args = { "format", "--offline", "--stdin-filename", "$FILENAME", "-" },
        },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        json = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        ["yaml.ansible"] = { "prettierd", "prettier", stop_after_first = true },
        ["yaml.docker-compose"] = { "prettierd", "prettier", stop_after_first = true },
        ["yaml.github"] = { "prettierd", "prettier", stop_after_first = true },
        ["yaml.helm-values"] = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        toml = { "tombi" },
        terraform = { "terraform_fmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    },
  },
}, {
  change_detection = { notify = false },
  checker = { enabled = false },
  rocks = { enabled = false },
})

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
