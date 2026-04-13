# ========================================
# 基本設定
# ========================================

# brew のパスを通す
export PATH="/opt/homebrew/bin:$PATH"

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

# 1Password SSH エージェント
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ========================================
# ファイル操作ユーティリティ
# ========================================
# eza が使えればそちらを優先、なければ標準 ls にフォールバック
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -alh --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons --group-directories-first -L 2'
  alias tree='eza --tree --icons --group-directories-first'
else
  alias ls='ls -F --color=auto'
  alias ll='ls -alF --color=auto'
  alias la='ls -AF --color=auto'
  alias tree='tree -C'
fi

# sed を GNU 版に差し替え
if command -v gsed >/dev/null 2>&1; then
  alias sed='gsed'
fi

# ripgrep を grep に差し替え
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
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
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# プレビューはデフォルト非表示（? でトグル）にして起動を高速化
export FZF_DEFAULT_OPTS='
  --height 40% --layout=reverse --border
  --preview "bat --style=numbers --color=always --line-range=:200 {}"
  --preview-window=hidden
  --bind "?:toggle-preview"
'

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

# ファイル検索 + batプレビュー + nvimで開く
ff() {
  local file
  file=$(fzf --walker file,hidden \
             --walker-skip .git,node_modules,.terraform \
             --preview "bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat -n {}" \
             --preview-window "right:55%:wrap:nohidden" \
             --header "Enter: nvim" \
             --prompt="  File > ")
  [[ -n "$file" ]] && nvim "$file"
}

# ghq リポジトリを fzf で選択して移動
ghqcd() {
  local repo
  repo=$(ghq list --full-path \
         | fzf --prompt="  Repo > " \
               --preview "eza --tree --icons -L 2 {} 2>/dev/null || ls -la {}" \
               --preview-window "right:45%:nohidden" \
               --header "Enter: cd")
  [[ -n "$repo" ]] && cd "$repo" && { command -v eza >/dev/null 2>&1 && eza --icons --group-directories-first || ls -F; }
}

# fzf でディレクトリ移動（ディレクトリのみ）
fz() {
  local dir
  dir=$(fd --type d --hidden --follow \
           --exclude .git --exclude node_modules --exclude .terraform \
           . "${1:-.}" 2>/dev/null \
        | fzf --prompt="  Dir > " \
              --preview "eza --tree --icons -L 2 {} 2>/dev/null || ls -la {}" \
              --preview-window "right:40%:nohidden" \
              --header "Enter: cd")
  [[ -n "$dir" ]] && cd "$dir" && { command -v eza >/dev/null 2>&1 && eza --icons --group-directories-first || ls -F; }
}
