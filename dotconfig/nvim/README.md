# Neovim minimal setup

最終確認日: 2026-04-18

このディレクトリの Neovim は、`lazy.nvim` を使った single-file 構成です。目的は「軽く、壊れにくく、検索と file navigation がすぐ使えること」です。

## 現在の到達点

今の構成は「日常編集、検索、LSP、format」という意味では実用段階に入っている。

- search: `fzf-lua`
- file navigation: `oil.nvim`
- LSP: `lua`, `sh`, `json`, `toml`, `yaml`, `terraform`, `helm`
- formatter: `lua`, `sh`, `json`, `yaml`, `markdown`, `toml`, `terraform`
- Treesitter: `terraform` を含め主要 parser 導入済み

結論として、terminal 内で使う editor としては十分強い。
ただし、厳密に「VSCode並み」と言うならまだ未実装の領域がある。

入れている plugin は以下です。

- `catppuccin`
- `fzf-lua`
- `oil.nvim`
- `nvim-lspconfig`
- `nvim-treesitter`
- `conform.nvim`
- `nvim-web-devicons`

入れていないものは以下です。

- statusline
- dashboard
- Ansible 関連
- luarocks / hererocks 依存

## 現在の役割分担

- file search / grep: `fzf-lua`
- file explorer: `oil.nvim`
- LSP: `nvim-lspconfig`
- syntax / highlight 補助: `nvim-treesitter`
- formatter: `conform.nvim`
- plugin manager の `luarocks` support: 無効
- 行番号: Normal mode は相対、Insert mode は絶対

## まず覚える操作

leader は `Space`。

```text
<Space>ff    project 内の file search
<Space>fg    project 内の live grep
<Space>fb    open buffer 一覧
<Space>fr    recent files
<Space>/     current buffer grep
-            parent directory を Oil で開く
gd           definition へ jump
gr           references 一覧
K            hover
<Space>rn    rename
<Space>ca    code action
<Space>e     diagnostic を float で表示
[d / ]d      previous / next diagnostic
<Space>f     manual format
<Space>w     write
<Space>q     quit
```

## 普段の使い方

最初の入口は `fzf-lua` です。

```bash
nvim
```

そのあとに使う流れはだいたい以下です。

1. `Space ff` で file を開く
2. `Space fg` で project grep
3. `-` で親 directory を開く
4. code を読んで `gd` / `gr` / `K` を使う
5. 保存時に自動 format、必要なら `Space f` で明示 format

`oil.nvim` は「tree を眺める」より「buffer として file operation をする」感覚で使う方が合っています。

## filetype ごとの有効機能

### LSP

- `lua`: `lua-language-server`
- `sh` / `bash` / `zsh`: `bash-language-server`
- `json`: `vscode-json-language-server`
- `toml`: `tombi`
- `yaml`: `yaml-language-server`
- `terraform`: `terraform-ls`
- `helm`: `helm_ls`

注意点:

- `taplo` LSP はこの環境で panic したため使わない
- TOML の LSP は `tombi lsp --offline` を使う
- Helm chart 配下では `templates/*.yaml` を `helm`、`values.yaml` を `yaml.helm-values` として判定
- `*.tfvars` / `*.auto.tfvars` は `terraform-vars`、`docker-compose*.yml|yaml` は `yaml.docker-compose` として判定

### formatter

- `lua`: `stylua`
- `sh` / `bash` / `zsh`: `shfmt`
- `json`: `prettier`
- `yaml`: `prettier`
- `markdown`: `prettier`
- `toml`: `tombi`
- `terraform`: `terraform fmt`

## 実施済みの動作確認

2026-04-18 時点で以下は確認済み。

- `nvim --headless '+qa'` が成功
- `nvim --headless '+checkhealth vim.lsp' +qa` が成功
- plugin install 済み
- formatter / LSP binary が `PATH` から解決可能
- 実ファイル確認で `lua_ls` / `bashls` / `jsonls` / `tombi` / `yamlls` / `terraformls` / `helm_ls` の attach を確認
- Treesitter parser は以下を install 済み

```text
bash
diff
dockerfile
git_config
gitcommit
gitignore
hcl
json
lua
markdown
markdown_inline
toml
terraform
vim
vimdoc
yaml
```

注意点:

- `helm_ls` の binary 名は `helm-ls` ではなく `helm_ls`
- `taplo` は formatter / LSP ともに crash を確認したため使わない

## 自分で確認する手順

### 1. plugin と起動確認

```bash
nvim --headless '+qa'
nvim --headless '+checkhealth vim.lsp' +qa
```

Neovim の中でも確認するなら以下。

```vim
:LspInfo
:Lazy
:checkhealth vim.lsp
:ConformInfo
```

### 2. search / navigation

適当な Git repository で以下を試す。

```text
Space ff
Space fg
-
```

期待値:

- `Space ff` で file picker が開く
- `Space fg` で `rg` ベースの grep picker が開く
- `-` で parent directory が Oil buffer として開く

### 3. LSP

各 filetype の file を 1 枚開いて `:LspInfo` を見る。

`LspInfo` はこの設定で `:checkhealth vim.lsp` への alias を自前定義している。

おすすめの確認対象:

- `init.lua`
- `mise.toml`
- `values.yaml`
- `templates/deployment.yaml`
- `main.tf`
- `Dockerfile`
- `package.json`

期待値:

- 対応 server が attach する
- `gd`, `K`, `gr` が動く
- `]d`, `[d` で diagnostic 移動できる

補足:

- `mise.toml` は `tombi` が attach し、format も `tombi`
- `templates/deployment.yaml` は `helm_ls`
- `values.yaml` は `helm_ls` と `yamlls` が両方 attach しうる

### 4. formatter

対応 file をわざと崩して保存するか、`Space f` を押す。

期待値:

- 保存時に format される
- もしくは `Space f` で format される
- `:ConformInfo` で formatter の認識状況が見える

## よく使う実戦パターン

### Terraform

```text
Space ff -> main.tf
:LspInfo
gd
K
Space f
```

### Helm / YAML

```text
Space ff -> values.yaml
Space fg -> image:
K
Space e
Space f
```

### dotfiles / shell

```text
Space ff -> .zshrc or script.sh
K
gr
Space f
```

## トラブルシュート

### picker が開かない

以下を確認する。

```bash
command -v fzf rg fd
```

### LSP が attach しない

以下を確認する。

```vim
:LspInfo
:checkhealth vim.lsp
```

そのうえで binary があるか確認する。

```bash
command -v lua-language-server bash-language-server vscode-json-language-server yaml-language-server terraform-ls helm_ls tombi
```

### format されない

以下を確認する。

```vim
:ConformInfo
```

そのうえで formatter binary を確認する。

```bash
command -v stylua shfmt prettier tombi terraform
```

### Treesitter 周りでこける

現構成では startup 時に parser 自動 install はしない。必要な parser だけ個別に入れる方針。

例:

```bash
nvim --headless "+lua require('nvim-treesitter').install({'lua'}):wait(300000)" +qa
```

Terraform 系は `hcl` と `terraform` の両方が必要。

## この構成の評価

この構成は「最小で実用」という目的に対して十分に妥当です。特に良い点は以下です。

- 検索と移動の導線が短い
- builtin LSP に寄せていて将来の保守負荷が低い
- formatter を `conform.nvim` に一本化している
- tmux / terminal 前提でも余計な UI plugin がなく軽い

逆に、今はあえてやっていないこともあります。

- completion framework の追加
- snippet engine の追加
- statusline / dashboard の追加
- Git UI plugin の追加

必要性が出るまで増やさない方が筋が良いです。

## VSCodeとの比較

結論を先に書くと、今の Neovim は「あなたの現用途ではかなり戦えるが、まだ全面的に VSCode 並みとは言わない」が正確です。

すでに VSCode 並みに近い点:

- file search / grep
- file navigation
- LSP による jump / hover / rename / diagnostics
- save 時 format
- tmux / terminal での軽さと応答性

まだ VSCode に届いていない点:

- completion UI
- snippet 展開
- debug adapter
- test explorer 的な UI
- Git blame / diff / hunk 操作の統合 UI
- project-wide symbol UI や code action UI の厚み

つまり、SRE の日常編集に必要な「読む、探す、跳ぶ、整える」はもう足りている。一方で、IDE 的な厚みまではまだ足していない。

次に足すなら優先順位はこれです。

1. completion framework
2. snippet engine
3. Git hunk 操作
4. 必要なら DAP
