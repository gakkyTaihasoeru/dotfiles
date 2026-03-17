# ========================================
# 基本設定
# ========================================

# zoxide（ディレクトリ移動を学習して自動補完）
eval "$(zoxide init zsh)"

# mise（ツールバージョン管理）
eval "$(mise activate zsh)"

# starship
eval "$(starship init zsh)"

# 履歴設定（重複・空コマンド除外）
export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt hist_ignore_dups hist_ignore_space share_history hist_expire_dups_first hist_find_no_dups

# ========================================
# ファイル操作ユーティリティ
# ========================================
# 色付きを基本にする
alias ls='ls -F --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -AF --color=auto'
# treeコマンド
alias tree='tree -C'

# sed を GNU 版に差し替え
if command -v gsed >/dev/null 2>&1; then
  alias sed='gsed'
fi

# Git ショートカット
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate'
alias gb='git branch -vv'
alias gd='git diff'

# ========================================
# 検索支援
# ========================================
# fzf のテーマとキーバインド改善
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview "bat --style=numbers --color=always {} | head -200"'

# Ctrl+R は Warp の独自履歴UIと競合するため、Warp上では fzf-history は呼ばれない
# fzf 自体は他の関数 (ff, fz など) で有効
export FZF_CTRL_R_OPTS="--height 40% --layout=reverse"

# ========================================
# コマンド補完・プラグイン設定
# ========================================

# FPATH の設定（compinit 前に実施）
if type brew &>/dev/null; then
  BREW_PREFIX="/opt/homebrew"
  fpath=($BREW_PREFIX/share/zsh-completions $fpath)
  fpath=(/Users/rh1/.docker/completions $fpath)
fi

# 補完の初期化 (-u で権限警告を無視)
autoload -Uz compinit
compinit -u

# 補完スタイルの設定
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# プラグインの読み込み
if type brew &>/dev/null; then
  # サジェスト
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  # シンタックスハイライト (最後の方で読み込む)
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  # fzf 統合
  source <(fzf --zsh)
fi

# Terraform補完 (compinit 後に実行)
if type terraform &>/dev/null; then
  # zsh 用の補完関数をロード
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(which terraform)" terraform
fi

# ========================================
# fzf + zoxide 拡張関数
# ========================================

# ファイル検索 + catプレビュー + nvimで開く
ff() {
  local file
  file=$(fd --type f --hidden --exclude .git | \
         fzf --preview "cat -n {} | head -200" \
             --prompt="🔍 Select file > ")
  [[ -n "$file" ]] && { tput cuu1; nvim "$file"; }
}

# zoxide + fzf でディレクトリ移動
fz() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | \
        fzf --prompt="📂 Change Directory > " \
            --preview "ls -F {} | head -100")
  if [[ -n "$dir" ]]; then
    cd "$dir" || return
  fi
}
