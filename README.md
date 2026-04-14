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

- `brew bundle --file=Brewfile`
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

### 5. macOS システム設定だけを確認したい場合

```bash
bash bin/setup.sh --dry-run
```

> **注意**: `setup.sh` は `defaults write` で macOS の設定を変更し、Finder と SystemUIServer を再起動します。`--dry-run` で事前確認できます。

### 6. シェルの再起動

```bash
exec zsh
```

---

## ファイル構成

```
dotfiles/
├── Brewfile                      # Homebrew パッケージ・Cask・VSCode 拡張
├── bin/
│   ├── install.sh                # 初期セットアップとリンク作成
│   └── setup.sh                  # macOS システム設定スクリプト
├── dotconfig/
│   ├── ghostty/
│   │   └── config                # Ghostty ターミナル設定
│   └── mise/
│       └── config.toml           # mise ツールバージョン管理
├── git/
│   └── .gitconfig                # Git グローバル設定
├── scripts/
│   ├── validate_json.py          # JSON / JSONC 検証
│   ├── validate_toml.py          # TOML 検証
│   └── validate_yaml.py          # YAML 検証
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

主要な言語・基盤ツールは再現性を上げるために major / minor を固定しています。

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
