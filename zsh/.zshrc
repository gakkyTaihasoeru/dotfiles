# ========================================
# 基本設定
# ========================================

# PATH / FPATH の重複を自動で除去
typeset -U path fpath

has() {
  (( $+commands[$1] ))
}

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

# Homebrew の場所を検出して PATH に追加
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
elif has brew; then
  export HOMEBREW_PREFIX="$(brew --prefix)"
fi

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi

# 履歴設定（重複・空コマンド除外）
export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_reduce_blanks

# 1Password SSH エージェント
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ========================================
# ツール初期化
# ========================================

if has zoxide; then
  eval "$(zoxide init zsh)"
fi

if has mise; then
  eval "$(mise activate zsh)"
fi

if has starship && [[ -t 1 ]]; then
  eval "$(starship init zsh)"
fi

# ========================================
# ファイル操作ユーティリティ
# ========================================

if has eza; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -alh --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons --group-directories-first -L 2'
  alias tree='eza --tree --icons --group-directories-first'
else
  alias ls='ls -F'
  alias ll='ls -alF'
  alias la='ls -AF'
  has tree && alias tree='tree -C'
fi

if has gsed; then
  alias sed='gsed'
fi

if has rg; then
  alias rg='rg --smart-case'
  alias grep='grep --color=auto'
  alias gr='rg'
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

if has fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
fi

if has bat; then
  export FZF_DEFAULT_OPTS='
    --height 40% --layout=reverse --border
    --preview "bat --style=numbers --color=always --line-range=:200 {}"
    --preview-window=hidden
    --bind "?:toggle-preview"
  '
else
  export FZF_DEFAULT_OPTS='
    --height 40% --layout=reverse --border
    --preview "cat -n {} 2>/dev/null"
    --preview-window=hidden
    --bind "?:toggle-preview"
  '
fi

# Ctrl+R は Warp の独自履歴 UI と競合するため、fzf 側の設定は軽量に保つ
export FZF_CTRL_R_OPTS='--height 40% --layout=reverse'

# ========================================
# コマンド補完・プラグイン設定
# ========================================

if [[ -n "$HOMEBREW_PREFIX" ]]; then
  [[ -d "$HOMEBREW_PREFIX/share/zsh-completions" ]] && fpath=("$HOMEBREW_PREFIX/share/zsh-completions" $fpath)
fi
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

autoload -Uz compinit
zcompdump_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zcompdump_file="$zcompdump_dir/.zcompdump-${HOST}-${ZSH_VERSION}"
[[ -d "$zcompdump_dir" ]] || mkdir -p "$zcompdump_dir"
compinit -d "$zcompdump_file" -u
unset zcompdump_dir zcompdump_file

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

if [[ -n "$HOMEBREW_PREFIX" && -o interactive ]]; then
  source_if_exists "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  source_if_exists "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  source_if_exists "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"

  # zle 依存のキーバインドは TTY 付き対話シェルでのみ有効化
  if [[ -t 0 ]]; then
    source_if_exists "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  fi
fi

if has terraform; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi

# ========================================
# fzf + zoxide 拡張関数
# ========================================

list_dir() {
  if has eza; then
    eza --icons --group-directories-first
  else
    ls -F
  fi
}

# ファイル検索 + プレビュー + nvim で開く
ff() {
  has fzf || return 1

  local file
  file=$(fzf --walker file,hidden \
             --walker-skip .git,node_modules,.terraform \
             --preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat -n {} 2>/dev/null' \
             --preview-window 'right:55%:wrap:nohidden' \
             --header 'Enter: nvim' \
             --prompt '  File > ')
  [[ -n "$file" ]] && nvim "$file"
}

# ghq リポジトリを fzf で選択して移動
ghqcd() {
  has ghq && has fzf || return 1

  local repo
  repo=$(ghq list --full-path \
         | fzf --prompt '  Repo > ' \
               --preview 'eza --tree --icons -L 2 {} 2>/dev/null || ls -la {}' \
               --preview-window 'right:45%:nohidden' \
               --header 'Enter: cd')
  [[ -n "$repo" ]] && cd "$repo" && list_dir
}

# fzf でディレクトリ移動（ディレクトリのみ）
fz() {
  has fd && has fzf || return 1

  local dir
  dir=$(fd --type d --hidden --follow \
           --exclude .git --exclude node_modules --exclude .terraform \
           . "${1:-.}" 2>/dev/null \
        | fzf --prompt '  Dir > ' \
              --preview 'eza --tree --icons -L 2 {} 2>/dev/null || ls -la {}' \
              --preview-window 'right:40%:nohidden' \
              --header 'Enter: cd')
  [[ -n "$dir" ]] && cd "$dir" && list_dir
}
