# dotfiles

macOS (Apple Silicon) 向けの個人開発環境設定です。
Infrastructure / SRE 用途を前提に、CLI ツール・エディタ・シェルを [chezmoi](https://www.chezmoi.io/) で一括管理します。

---

## 動作環境

| 項目 | 要件 |
|------|------|
| OS | macOS (Apple Silicon) |
| Shell | zsh |
| パッケージ管理 | Homebrew |
| dotfile 管理 | chezmoi |
| ツール管理 | mise |

## セットアップ手順

### 1. Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. リポジトリ取得 & ブートストラップ

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/work/ghq/github.com/<your-username>/dotfiles
cd ~/work/ghq/github.com/<your-username>/dotfiles
bash bin/install.sh
```

`bin/install.sh` は薄い bootstrap で、以下だけを実行します。

- Homebrew が未インストールなら導入
- chezmoi が未インストールなら `brew install chezmoi`
- 初回だけ `~/.config/chezmoi/chezmoi.toml` を seed する
- `chezmoi apply` を実行する

既存の `~/.config/chezmoi/chezmoi.toml` が別の `sourceDir` を向いている場合、`bin/install.sh` は上書きせずに停止します。

副作用が大きい brew bundle と `mise install` は opt-in です。

```bash
bash bin/install.sh --dry-run    # apply 内容の事前確認
bash bin/install.sh --brew       # apply 後に brew bundle install まで実行
bash bin/install.sh --mise       # apply 後に mise install まで実行
```

`Brewfile.local.example` を `Brewfile.local` にコピーすると、共有 Brewfile を汚さず個人用 package を追加できます (`.gitignore` 対象)。

```bash
cp Brewfile.local.example Brewfile.local
```

### 3. 日常運用 (chezmoi)

リポジトリで設定を編集したら、明示的に `chezmoi apply` を実行して home に反映します。`mise run maintenance` チェーンには意図的に組み込んでいません。

```bash
chezmoi apply --dry-run --verbose   # 差分確認
chezmoi apply                        # 反映
chezmoi diff                         # source と destination の差分
chezmoi managed                      # 管理対象一覧
```

home 側で先に変更してしまった場合は `chezmoi merge <file>` か `chezmoi re-add <file>` で source に反映します。

`~/.gitconfig` は `home/dot_gitconfig.tmpl` から render し、`name` / `email` / `signingkey` はローカルの `~/.config/chezmoi/chezmoi.toml` の `[data.git]` から供給します。`ghq` の root も同ファイルの `[data.paths]` で上書きできます。`chezmoi.toml` 自体は source state には含めず、ローカル制御面として扱います。

### 4. macOS システム設定

`home/.chezmoiscripts/run_once_after_apply-macos-defaults.sh.tmpl` が `chezmoi apply` 時に一度だけ走り、`defaults write` を適用します。再適用したい場合はスクリプト内容を変更するか chezmoi state を消してください。

`home/.chezmoiignore.tmpl` により、`Library/**` は `darwin` 以外では配布しません。

### 5. Docker daemon 設定

`dotconfig/docker/daemon.json` は chezmoi 管理外です。Docker Desktop が `~/.docker/daemon.json` を上書きすることがあるため、明示的に diff を確認しつつ適用します。

```bash
bash bin/docker-apply.sh
```

### 6. mise タスク (運用)

```bash
mise tasks ls
mise run ghq-pull
mise run brew-update
mise run brew-reconcile
mise run brew-reconcile-apply
mise run mise-update
mise run doctor
mise run maintenance
```

`ghq-pull` は detached HEAD、upstream なし、dirty worktree、local commit がある repository を自動で skip します。`brew-update` は `Brewfile` と `Brewfile.local` の不足分をインストール・更新しますが、未記載のものは削除しません。`brew-reconcile` は削除対象を preview 表示し、`brew-reconcile-apply` で実削除します。

---

## ファイル構成

chezmoi の source root は `home/`（`.chezmoiroot` で指定）。`home/` 配下は chezmoi 命名規則に従います (`dot_` → `.`、`executable_` → 実行ビット、`run_once_` → 1 回実行 script など)。

```
dotfiles/
├── .chezmoiroot                     # chezmoi に "home/" を source として認識させる
├── Brewfile                         # Homebrew パッケージ・Cask・VSCode 拡張 (共有)
├── Brewfile.local.example           # 個人用 package のサンプル
├── mise.toml                        # mise task 定義 (brew-update, ghq-pull 等)
├── .codex/                          # このリポジトリ編集時の Codex CLI 設定
├── .github/workflows/ci.yml         # CI (shellcheck / chezmoi dry-run / JSON / TOML / YAML)
├── bin/
│   ├── install.sh                   # 薄い chezmoi bootstrap
│   ├── brew-bundle.sh               # Brewfile + Brewfile.local の install / cleanup
│   ├── docker-apply.sh              # ~/.docker/daemon.json への明示適用 (diff 確認付き)
│   └── check.sh                     # ヘルスチェック (mise run doctor から呼ばれる)
├── scripts/
│   ├── validate_json.py             # JSON / JSONC 検証 (trailing comma 対応)
│   ├── validate_toml.py             # TOML 検証
│   └── validate_yaml.py             # YAML 検証
├── docs/
│   └── nvim.md                      # Neovim 設定メモ (chezmoi 管理外)
├── dotconfig/
│   └── docker/daemon.json           # Docker daemon 設定 (chezmoi 管理外、bin/docker-apply.sh で適用)
└── home/                            # ← chezmoi source root
    ├── .chezmoiignore.tmpl          # non-darwin では Library/** を除外
    ├── .chezmoiscripts/
    │   ├── run_once_before_install-homebrew.sh.tmpl   # 初回 apply 時に Homebrew 導入
    │   └── run_once_after_apply-macos-defaults.sh.tmpl # macOS defaults を一度だけ適用
    ├── dot_zshrc                    # → ~/.zshrc
    ├── dot_zshenv                   # → ~/.zshenv
    ├── dot_zprofile                 # → ~/.zprofile
    ├── dot_gitconfig.tmpl           # → ~/.gitconfig
    ├── dot_tmux.conf                # → ~/.tmux.conf
    ├── dot_config/
    │   ├── ghostty/config           # → ~/.config/ghostty/config
    │   ├── mise/config.toml         # → ~/.config/mise/config.toml
    │   ├── atuin/config.toml        # → ~/.config/atuin/config.toml
    │   ├── bat/config               # → ~/.config/bat/config
    │   ├── starship.toml            # → ~/.config/starship.toml
    │   └── nvim/
    │       ├── init.lua             # → ~/.config/nvim/init.lua
    │       └── lazy-lock.json       # → ~/.config/nvim/lazy-lock.json
    ├── dot_claude/                  # → ~/.claude/ (Claude Code グローバル設定)
    │   ├── CLAUDE.md
    │   ├── settings.json
    │   ├── executable_statusline.sh # 実行ビット付与
    │   └── rules/
    ├── dot_gemini/                  # → ~/.gemini/
    │   ├── GEMINI.md
    │   ├── settings.json
    │   └── policies/sre_policy.toml
    ├── private_dot_codex/           # → ~/.codex/ (mode 0700)
    │   ├── AGENTS.md
    │   └── private_config.toml      #   → mode 0600 (auth / personality を含む)
    └── Library/Application Support/Code/User/settings.json   # → 同パス (darwin のみ)
```

> **管理対象から除外しているもの**: 認証情報 (`~/.gemini/oauth_creds.json` など)、
> セッション/履歴/キャッシュ (`~/.claude/projects/`, `~/.codex/sessions/`, sqlite DB 等)。
> これらは各 CLI の runtime データのためコミットしない。

---

## 主要コンポーネント

### シェル環境

| ツール | 用途 |
|--------|------|
| [starship](https://starship.rs/) | プロンプトカスタマイズ |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | 学習型ディレクトリ移動 |
| [atuin](https://github.com/atuinsh/atuin) | シェル履歴の同期・検索 (Ctrl+R) |
| [fzf](https://github.com/junegunn/fzf) | ファジー検索 |
| [fd](https://github.com/sharkdp/fd) | 高速ファイル検索 |
| [bat](https://github.com/sharkdp/bat) | シンタックスハイライト付き cat |

### ツール管理 (mise)

| ツール | 用途 |
|--------|------|
| awscli | AWS CLI |
| terraform | IaC |
| kubectl / kind / minikube | Kubernetes |
| trivy | コンテナ脆弱性スキャン |
| go / python / node | 言語ランタイム |
| neovim | エディタ |
| gh | GitHub CLI |

主要な言語・基盤ツールは再現性を上げるために major / minor を固定しています。

### VS Code 主要拡張

| 拡張 | 用途 |
|------|------|
| hashicorp.terraform | Terraform |
| ms-kubernetes-tools.vscode-kubernetes-tools | Kubernetes |
| golang.go | Go |
| github.copilot-chat | AI コード補完 |
| redhat.vscode-yaml | YAML |

---

## Git 設定の方針

`user.name` / `user.email` / `user.signingkey` はローカルの `~/.config/chezmoi/chezmoi.toml` の `[data.git]` を変更すれば差し替えられます。

| 設定 | 値 | 理由 |
|------|----|------|
| `merge.ff` | `false` | マージコミットを必ず作成 |
| `pull.ff` | `only` | fast-forward のみ許可（意図しないマージを防止） |
| `push.default` | `current` | 現在のブランチを同名 upstream に push |
| `push.autoSetupRemote` | `true` | 新規ブランチの `-u` 指定を自動化 |
| `rebase.updateRefs` | `true` | stacked branch の ref を自動更新 |
| `rerere.enabled` | `true` | conflict 解決を学習・再適用 |
| `fetch.prune` | `true` | 削除済み remote branch を自動整理 |
| `transfer.fsckObjects` / `fetch.fsckObjects` / `receive.fsckObjects` | `true` | 取り込むオブジェクトを fsck し、壊れた push を拒否 |

## AI エージェント設定

`home/dot_claude/` / `home/dot_gemini/` / `home/private_dot_codex/` は各 CLI のグローバル設定を chezmoi 経由で管理します。Codex は auth/personality を含むため `private_` prefix で `~/.codex/` を 0700、`config.toml` を 0600 に強制します。
`chezmoi apply` 後は以下の実ファイルとして配置されます。

| chezmoi source | apply 先 |
|---|---|
| `home/dot_claude/...` | `~/.claude/...` |
| `home/dot_gemini/...` | `~/.gemini/...` |
| `home/private_dot_codex/{AGENTS.md,private_config.toml}` | `~/.codex/...` (dir 0700, config.toml 0600) |

`home/dot_claude/hooks/executable_secret-scan.py` は Write/Edit/MultiEdit/NotebookEdit 前に走り、AWS / GitHub / Slack / Anthropic 等のトークンや PEM 秘密鍵を含むコミットを block します。
`executable_sensitive-read.py` は Read ツールで機密ファイルを開く際に確認を挟みます。
