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

---

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

### 4. Homebrew パッケージ・アプリ・VSCode 拡張の一括インストール

```bash
brew bundle --file=Brewfile
```

### 5. mise でツールのインストール

```bash
mise install
```

### 6. macOS システム設定の適用

```bash
bash bin/setup.sh
```

> **注意**: `setup.sh` は `defaults write` で macOS の設定を変更し、Finder と SystemUIServer を再起動します。実行前に内容を確認してください。

### 7. 設定ファイルのシンボリックリンク作成

各設定ファイルを所定の場所にリンクします。

```bash
# zsh
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

# Git
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

# Ghostty
mkdir -p ~/.config/ghostty
ln -sf ~/dotfiles/dotconfig/ghostty/config ~/.config/ghostty/config

# mise
mkdir -p ~/.config/mise
ln -sf ~/dotfiles/dotconfig/mise/config.toml ~/.config/mise/config.toml

# VSCode
ln -sf ~/dotfiles/vscode/settings.json \
  "$HOME/Library/Application Support/Code/User/settings.json"
```

### 8. シェルの再起動

```bash
exec zsh
```

---

## ファイル構成

```
dotfiles/
├── Brewfile                      # Homebrew パッケージ・Cask・VSCode 拡張
├── bin/
│   └── setup.sh                  # macOS システム設定スクリプト
├── dotconfig/
│   ├── ghostty/
│   │   └── config                # Ghostty ターミナル設定
│   └── mise/
│       └── config.toml           # mise ツールバージョン管理
├── git/
│   └── .gitconfig                # Git グローバル設定
├── vscode/
│   └── settings.json             # VSCode ユーザー設定
└── zsh/
    └── .zshrc                    # zsh 設定・エイリアス・補完
```

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

### VSCode 主要拡張

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
| `push.default` | `nothing` | push 時に remote/branch を明示することで事故を防止 |
