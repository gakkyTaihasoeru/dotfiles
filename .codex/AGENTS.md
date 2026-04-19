# AGENTS.md

このリポジトリは macOS (Apple Silicon) 向けの dotfiles を chezmoi で管理する。主な対象は `Brewfile`、`bin/`、`home/`（chezmoi source、`.chezmoiroot` で root 指定）、`dotconfig/docker/`（chezmoi 管理外、`bin/docker-apply.sh` で明示適用）。

最初に使う確認コマンド:

```bash
bash bin/check.sh
```

副作用を避けて apply 内容を確認したいとき:

```bash
chezmoi apply --dry-run --verbose
bash bin/install.sh --dry-run
```

非自明な変更ルール:

- `home/` 配下のファイル名は chezmoi 命名規則に従う（`dot_` prefix で `.foo` に展開、`executable_` prefix で実行ビット付与）
- `home/.chezmoiscripts/run_once_*` を編集したら chezmoi state を考慮する。スクリプト内容のハッシュが変わると再実行されるため、副作用を持つ変更は意識的に行う
- `chezmoi apply` を maintenance chain（`mise run maintenance`）に組み込まない。明示実行を維持する
- `Brewfile` の自動同期は行わない（`run_onchange_*` を入れない）。`brew-update` task で明示的に reconcile する
- JSON/TOML/YAML を編集したら syntax validation を通す
- shell script を編集したら少なくとも `bash -n` を通す
- 既存の macOS 前提を Linux 向けに一般化しない。macOS 専用であることを崩す変更は明示的な要求がある場合だけ行う

レビュー時の優先確認:

1. chezmoi naming の不整合（dot_/executable_ prefix の付け忘れ）
2. run_once script の意図しない再実行
3. dry-run 不能化
4. shell syntax error
5. dotfile format error
