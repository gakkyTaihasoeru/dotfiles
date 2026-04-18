# dotfiles

macOS (Apple Silicon) 向けの個人開発環境設定です。
Infrastructure / SRE 用途を前提に、CLI ツール・エディタ・シェルを一括セットアップします。

---

## 動作環境

| 項目 | 要件 |
|------|------|
| OS | macOS (Apple Silicon) |
| Shell | zsh |
| パッケージ管理 | Homebrew |
| ツール管理 | mise |

## セットアップ手順

### 1. Xcode Command Line Tools

```bash
xcode-select --install
```

### 2. Homebrew のインストール

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. dotfiles のクローン

```bash
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 4. ワンコマンドでセットアップ

```bash
bash bin/install.sh
```

`bin/install.sh` は以下をまとめて実行します。

- `Brewfile` と任意の `Brewfile.local` の適用
- `mise install`
- `bin/setup.sh`
- 各種 dotfiles のシンボリックリンク作成

必要に応じて一部だけスキップできます。

```bash
bash bin/install.sh --skip-brew
bash bin/install.sh --skip-mise
bash bin/install.sh --skip-macos
bash bin/install.sh --dry-run
```

個人用の package / cask / VS Code extension を shared な `Brewfile` に混ぜたくない場合は、`Brewfile.local.example` を `Brewfile.local` にコピーして使います。`Brewfile.local` は Git 追跡対象外です。

```bash
cp Brewfile.local.example Brewfile.local
```

### 5. macOS システム設定だけを確認したい場合

```bash
bash bin/setup.sh --dry-run
```

> **注意**: `setup.sh` は `defaults write` で macOS の設定を変更し、Finder と SystemUIServer を再起動します。`--dry-run` で事前確認できます。

### 6. シェルの再起動

```bash
exec zsh
```

### 7. 運用タスク

`mise` task で日常メンテナンスをまとめて実行できます。

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

`ghq-pull` は detached HEAD、upstream なし、dirty worktree、local commit がある repository を自動で skip します。`brew-update` は `Brewfile` と、存在すれば `Brewfile.local` にある不足分をインストール・更新しますが、未記載のものは削除しません。`brew-reconcile` は `Brewfile` と `Brewfile.local` を合わせた定義を正として、削除対象の preview だけを表示します。実際に削除するのは `brew-reconcile-apply` です。

---

## ファイル構成

```
dotfiles/
├── Brewfile                      # Homebrew パッケージ・Cask・VSCode 拡張 (共有)
├── Brewfile.local.example        # 個人用パッケージ上書きのサンプル
├── mise.toml                     # mise task 定義 (brew-update, ghq-pull 等)
├── AGENTS.md                     # リポジトリ開発時のエージェント向け説明
├── .codex/                       # このリポジトリ編集時の Codex CLI 設定
├── .github/workflows/ci.yml      # CI (shellcheck / shfmt / JSON / TOML / YAML / py syntax)
├── bin/
│   ├── install.sh                # ブートストラップ + シンボリックリンク作成
│   ├── setup.sh                  # macOS システム設定スクリプト
│   ├── brew-bundle.sh            # Brewfile + Brewfile.local の install / cleanup
│   └── check.sh                  # ヘルスチェック (mise run doctor から呼ばれる)
├── scripts/
│   ├── validate_json.py          # JSON / JSONC 検証 (trailing comma 対応)
│   ├── validate_toml.py          # TOML 検証
│   └── validate_yaml.py          # YAML 検証
├── zsh/
│   ├── .zshrc                    # zsh 設定・エイリアス・補完
│   ├── .zshenv                   # 全 zsh 呼び出しで読まれる env (Homebrew hardening)
│   └── .zprofile                 # login shell 用 (brew shellenv)
├── git/
│   ├── .gitconfig                # Git グローバル設定
│   └── .gitignore_global         # OS/エディタ一時ファイル用の exclude
├── tmux/
│   └── .tmux.conf                # tmux 設定
├── dotconfig/
│   ├── ghostty/config            # Ghostty ターミナル
│   ├── mise/config.toml          # mise tool バージョン管理
│   ├── atuin/config.toml         # Atuin シェル履歴
│   ├── bat/config                # bat テーマ
│   └── nvim/
│       ├── init.lua              # Neovim 設定 (lazy.nvim)
│       ├── lazy-lock.json        # プラグイン版ロック
│       └── README.md             # nvim 設定メモ
├── vscode/
│   └── settings.json             # VS Code ユーザー設定 (JSONC)
├── claude/                       # ~/.claude/ にリンクされる Claude Code グローバル設定
│   ├── CLAUDE.md
│   ├── settings.json
│   ├── statusline.sh
│   ├── rules/
│   └── hooks/                    # secret-scan / sensitive-read PreToolUse hook
├── gemini/                       # ~/.gemini/ にリンク (Gemini CLI)
│   ├── GEMINI.md
│   ├── settings.json
│   └── policies/sre_policy.toml
└── codex/                        # ~/.codex/ にリンク (Codex CLI グローバル)
    ├── AGENTS.md
    └── config.toml
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
| eamodio.gitlens | Git 拡張 |
| redhat.vscode-yaml | YAML |

---

## Git 設定の方針

| 設定 | 値 | 理由 |
|------|----|------|
| `merge.ff` | `false` | マージコミットを必ず作成 |
| `pull.ff` | `only` | fast-forward のみ許可（意図しないマージを防止） |
| `push.default` | `current` | 現在のブランチを同名 upstream に push |
| `push.autoSetupRemote` | `true` | 新規ブランチの `-u` 指定を自動化 |
| `rebase.updateRefs` | `true` | stacked branch の ref を自動更新 |
| `rerere.enabled` | `true` | conflict 解決を学習・再適用 |
| `fetch.prune` | `true` | 削除済み remote branch を自動整理 |

## AI エージェント設定

`claude/` / `gemini/` / `codex/` は各 CLI のグローバル設定を版管理します。
インストール後は以下にリンクされます。

| リンク元 (repo) | リンク先 (home) |
|---|---|
| `claude/` の各ファイル | `~/.claude/` 配下 |
| `gemini/` の各ファイル | `~/.gemini/` 配下 |
| `codex/{AGENTS.md,config.toml}` | `~/.codex/` 配下 |

`claude/hooks/secret-scan.py` は Write/Edit/MultiEdit/NotebookEdit 前に走り、
AWS / GitHub / Slack / Anthropic 等のトークンや PEM 秘密鍵を含むコミットを block します。
`sensitive-read.py` は Read ツールで機密ファイルを開く際に確認を挟みます。
