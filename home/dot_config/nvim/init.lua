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

vim.lsp.config("tombi", {
  cmd = { "tombi", "lsp", "--offline" },
  filetypes = { "toml" },
  root_markers = { ".tombi.toml", "tombi.toml", ".git" },
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
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
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
        end,
      })

      vim.lsp.config("lua_ls", {
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
      })

      for _, server in ipairs({
        "bashls",
        "helm_ls",
        "jsonls",
        "lua_ls",
        "tombi",
        "terraformls",
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
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
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
