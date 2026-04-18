# ==============================
# 基本設定
# ==============================

typeset -U path fpath

BREW_PREFIX="/opt/homebrew"
if [[ ! -x "$BREW_PREFIX/bin/brew" ]] && (( $+commands[brew] )); then
  BREW_PREFIX="$(brew --prefix)"
fi

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

if [[ -z "${EDITOR:-}" ]]; then
  if (( $+commands[nvim] )); then
    export EDITOR="nvim"
  else
    export EDITOR="vi"
  fi
fi
export VISUAL="${VISUAL:-$EDITOR}"

path=(
  "$HOME/.local/bin"
  "$BREW_PREFIX/bin"
  $path
)

export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# ==============================
# zsh設定
# ==============================

setopt append_history
setopt auto_cd
setopt auto_pushd
setopt always_to_end
setopt complete_in_word
setopt extended_glob
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt interactive_comments
setopt no_beep
setopt no_flow_control
setopt notify
setopt pushd_ignore_dups
setopt share_history

export HISTFILE=~/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000

# ==============================
# エイリアス・関数
# ==============================

has() {
  (( $+commands[$1] ))
}

source_if_exists() {
  [[ -r "$1" ]] && source "$1"
}

open_editor() {
  local -a editor_cmd

  editor_cmd=(${=EDITOR})

  "${editor_cmd[@]}" "$@"
}

list_dir() {
  local target="${1:-.}"

  if has eza; then
    eza -alh --icons --group-directories-first --git --time-style=long-iso "$target"
  else
    command ls -alF "$target"
  fi
}

if has eza; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -alh --icons --group-directories-first --git --time-style=long-iso'
  alias la='eza -a --icons --group-directories-first --time-style=long-iso'
  alias tree='eza --tree --icons --group-directories-first'
else
  alias ls='ls -F'
  alias ll='ls -alF'
  alias la='ls -AF'
fi

if has bat; then
  alias cat='bat --paging=never --style=plain'
fi

if has gsed; then
  alias sed='gsed'
fi

alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate'
alias gb='git branch -vv'
alias gd='git diff'

# ==============================
# fzf設定
# ==============================

typeset -ga FZF_EXCLUDE_DIRS FZF_FD_EXCLUDE_ARGS
FZF_EXCLUDE_DIRS=(.git node_modules .terraform)
FZF_FD_EXCLUDE_ARGS=()
for _exclude_dir in "${FZF_EXCLUDE_DIRS[@]}"; do
  FZF_FD_EXCLUDE_ARGS+=(--exclude "$_exclude_dir")
done
unset _exclude_dir

if has bat; then
  FZF_FILE_PREVIEW_CMD='bat --style=numbers --color=always --line-range=:200 {} 2>/dev/null || command cat -n {} 2>/dev/null'
else
  FZF_FILE_PREVIEW_CMD='command cat -n {} 2>/dev/null'
fi

if has eza; then
  FZF_DIR_PREVIEW_CMD='eza --tree --icons --group-directories-first -L 2 {} 2>/dev/null || eza -alh --icons --group-directories-first --time-style=long-iso {} 2>/dev/null || command ls -la {} 2>/dev/null'
else
  FZF_DIR_PREVIEW_CMD='command ls -la {} 2>/dev/null'
fi

if has fd; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow ${(j: :)FZF_FD_EXCLUDE_ARGS}"
else
  export FZF_DEFAULT_COMMAND='find -L . \( -path "*/.git" -o -path "*/node_modules" -o -path "*/.terraform" \) -prune -o -type f -print'
fi

export FZF_CTRL_R_OPTS='--height 45% --layout=reverse'
export FZF_DEFAULT_OPTS='
  --height 45%
  --layout=reverse
  --border
  --preview "'"$FZF_FILE_PREVIEW_CMD"'"
  --preview-window=hidden
  --bind "?:toggle-preview"
'

FZF_SHELL_DIR="$BREW_PREFIX/opt/fzf/shell"

# ==============================
# ツール初期化
# ==============================

eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"
eval "$(atuin init zsh)"

# ==============================
# 補完設定
# ==============================

if [[ -d "$BREW_PREFIX/share/zsh-completions" ]]; then
  fpath=("$BREW_PREFIX/share/zsh-completions" $fpath)
fi

if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

autoload -Uz select-word-style
select-word-style bash

autoload -Uz compinit compaudit
_compdump="$ZSH_CACHE_DIR/.zcompdump-${HOST}-${ZSH_VERSION}"
typeset -i _compdump_fresh=0
typeset -a _compdump_stat _insecure_compdirs

if zmodload -F zsh/stat b:zstat 2>/dev/null && [[ -r "$_compdump" ]]; then
  zstat -A _compdump_stat +mtime -- "$_compdump" 2>/dev/null
  if (( ${#_compdump_stat[@]} )) && (( EPOCHSECONDS - _compdump_stat[1] < 86400 )); then
    _compdump_fresh=1
  fi
fi

if (( _compdump_fresh )); then
  compinit -d "$_compdump" -C
else
  _insecure_compdirs=("${(@f)$(compaudit 2>/dev/null)}")
  if (( ${#_insecure_compdirs[@]} )); then
    compinit -d "$_compdump" -i
  else
    compinit -d "$_compdump"
  fi
fi
unset _compdump_fresh _compdump_stat _insecure_compdirs

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

source_if_exists "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

if [[ -t 0 && -t 1 ]]; then
  source_if_exists "$FZF_SHELL_DIR/completion.zsh"
  source_if_exists "$FZF_SHELL_DIR/key-bindings.zsh"
fi

source_if_exists "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

if has terraform; then
  _terraform_bin="$(command -v terraform)"
  terraform() {
    unfunction terraform
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C "$_terraform_bin" terraform
    command terraform "$@"
  }
fi

if has kubectl; then
  kubectl() {
    unfunction kubectl
    source <(command kubectl completion zsh)
    command kubectl "$@"
  }
fi

if has helm; then
  helm() {
    unfunction helm
    source <(command helm completion zsh)
    command helm "$@"
  }
fi

if has aws; then
  _aws_completer_bin="$(command -v aws_completer 2>/dev/null)"
  if [[ -n "$_aws_completer_bin" ]]; then
    aws() {
      unfunction aws
      autoload -U +X bashcompinit && bashcompinit
      complete -C "$_aws_completer_bin" aws
      command aws "$@"
    }
  fi
fi

autoload -Uz edit-command-line
zle -N edit-command-line

# ==============================
# fzf 拡張関数
# ==============================

_fzf_file_candidates() {
  local root="${1:-.}"

  if has fd; then
    fd --type f --hidden --follow \
      "${FZF_FD_EXCLUDE_ARGS[@]}" \
      . "$root" 2>/dev/null
  else
    find -L "$root" \
      \( -path '*/.git' -o -path '*/node_modules' -o -path '*/.terraform' \) -prune \
      -o -type f -print 2>/dev/null
  fi
}

_fzf_dir_candidates() {
  local base_dir="${1:-.}"
  local base_abs="${base_dir:A}"
  local ghq_root=''
  local dir=''
  local -a zoxide_cmd
  typeset -A seen

  shift 2>/dev/null || true

  if has ghq; then
    ghq_root="$(ghq root 2>/dev/null)"
    [[ -n "$ghq_root" ]] && ghq_root="${ghq_root:A}"
  fi

  if has zoxide; then
    zoxide_cmd=(zoxide query -l --all)
    if (( $# )); then
      zoxide_cmd+=(-- "$@")
    fi

    while IFS= read -r dir; do
      [[ -n "$dir" && -d "$dir" ]] || continue
      dir="${dir:A}"
      [[ "$dir" == "$base_abs" || "$dir" == "$base_abs"/* ]] || continue
      [[ -z "$ghq_root" || "$dir" != "$ghq_root" && "$dir" != "$ghq_root"/* ]] || continue
      [[ -n "${seen[$dir]:-}" ]] && continue
      seen[$dir]=1
      print -r -- "$dir"
    done < <("${zoxide_cmd[@]}" 2>/dev/null)
  fi

  if has fd; then
    while IFS= read -r dir; do
      [[ -n "$dir" && -d "$dir" ]] || continue
      dir="${dir:A}"
      [[ -z "$ghq_root" || "$dir" != "$ghq_root" && "$dir" != "$ghq_root"/* ]] || continue
      [[ -n "${seen[$dir]:-}" ]] && continue
      seen[$dir]=1
      print -r -- "$dir"
    done < <(
      fd --type d --hidden --follow \
        "${FZF_FD_EXCLUDE_ARGS[@]}" \
        . "$base_dir" 2>/dev/null
    )
  else
    while IFS= read -r dir; do
      [[ -n "$dir" && -d "$dir" ]] || continue
      dir="${dir:A}"
      [[ -z "$ghq_root" || "$dir" != "$ghq_root" && "$dir" != "$ghq_root"/* ]] || continue
      [[ -n "${seen[$dir]:-}" ]] && continue
      seen[$dir]=1
      print -r -- "$dir"
    done < <(
      find -L "$base_dir" \
        \( -path '*/.git' -o -path '*/node_modules' -o -path '*/.terraform' \) -prune \
        -o -type d -print 2>/dev/null
    )
  fi
}

_fzf_select_dir() {
  local base_dir="${1:-.}"
  local initial_query="${2:-}"

  _fzf_dir_candidates "$base_dir" ${=initial_query} \
    | fzf --prompt="  Dir > " \
          --query "$initial_query" \
          --preview "$FZF_DIR_PREVIEW_CMD" \
          --preview-window "right:45%:nohidden" \
          --header "Enter: cd"
}

# ファイル検索 + batプレビュー + Neovimで開く
ff() {
  has fzf || return 1

  local root="${1:-.}"
  local file=''

  file=$(
    _fzf_file_candidates "$root" \
      | fzf --prompt="  File > " \
            --preview "$FZF_FILE_PREVIEW_CMD" \
            --preview-window "right:55%:wrap:nohidden" \
            --header "Enter: ${EDITOR}"
  ) || return

  [[ -n "$file" ]] && open_editor "$file"
}

# zoxide + fd + fzf でディレクトリ検索 (ghqは除外)
fz() {
  has fzf || return 1

  local base_dir='.'
  local initial_query=''
  local dir=''

  if (( $# )) && [[ -d "$1" ]]; then
    base_dir="$1"
    shift
  fi

  initial_query="$*"

  dir=$(_fzf_select_dir "$base_dir" "$initial_query") || return

  [[ -n "$dir" ]] && builtin cd "$dir" && list_dir
}

# Ctrl + g で ghq のリポジトリ選択して移動
ghqcd() {
  has ghq && has fzf || return 1

  local repo=''
  local ghq_root=''
  local preview_cmd=''

  ghq_root="$(ghq root 2>/dev/null)" || return 1
  [[ -n "$ghq_root" ]] || return 1
  ghq_root="${ghq_root:A}"
  preview_cmd="${FZF_DIR_PREVIEW_CMD//\{\}/\{2\}}"

  repo=$(
    ghq list \
      | awk -v root="$ghq_root" '{print $0 "\t" root "/" $0}' \
      | fzf --prompt="  Repo > " \
            --delimiter=$'\t' \
            --with-nth=1 \
            --accept-nth=2 \
            --preview "$preview_cmd" \
            --preview-window "right:45%:nohidden" \
            --header "Enter: cd"
  ) || return

  [[ -n "$repo" ]] && builtin cd "$repo" && list_dir
}

ghqcd_widget() {
  zle -I
  ghqcd
  zle reset-prompt
}

fzf-cd-widget() {
  setopt localoptions pipefail no_aliases 2>/dev/null

  local dir=''
  dir="$(_fzf_select_dir "." "")" || return

  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi

  zle push-line
  BUFFER="builtin cd -- ${(q)dir:a} && list_dir"
  zle accept-line
  local ret=$?
  unset dir
  zle reset-prompt
  return $ret
}

zle -N ghqcd-widget ghqcd_widget
bindkey '^G' ghqcd-widget
zle -N fzf-cd-widget
bindkey -M emacs '\ec' fzf-cd-widget
bindkey -M vicmd '\ec' fzf-cd-widget
bindkey -M viins '\ec' fzf-cd-widget
