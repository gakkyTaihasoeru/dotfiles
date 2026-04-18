# AGENTS.md

このリポジトリは macOS (Apple Silicon) 向けの dotfiles と bootstrap script を管理する。主な対象は `Brewfile`、`bin/`、`dotconfig/`、`zsh/`、`git/`、`vscode/`。

最初に使う確認コマンド:

```bash
bash bin/check.sh
```

副作用を避けて install flow を確認したいとき:

```bash
bash bin/install.sh --dry-run --skip-brew --skip-mise --skip-macos
bash bin/setup.sh --dry-run
```

非自明な変更ルール:

- `bin/install.sh` の link 対象を変える場合は、リポジトリ内の実ファイル配置と必ず一致させる
- `bin/setup.sh` は macOS の `defaults write` を実行するため、追加変更は `--dry-run` で確認可能な形を維持する
- JSON/TOML/YAML を編集したら syntax validation を通す
- shell script を編集したら少なくとも `bash -n` を通す
- 既存の macOS 前提を Linux 向けに一般化しない。macOS 専用であることを崩す変更は明示的な要求がある場合だけ行う

レビュー時の優先確認:

1. シンボリックリンク先の破壊
2. dry-run 不能化
3. shell syntax error
4. dotfile format error
