[[ "$TERM_PROGRAM" == "WezTerm" ]] || return 0

__wezterm_set_user_var() {
  printf '\033]1337;SetUserVar=%s=%s\007' "$1" "$(printf '%s' "$2" | base64)"
}

__wezterm_report_status() {
  local git_info repo branch
  git_info=("${(@f)$(git rev-parse --path-format=absolute --git-common-dir --abbrev-ref HEAD 2>/dev/null)}")
  if (( ${#git_info} == 2 )); then
    repo="${git_info[1]:h:t}"
    branch="${git_info[2]}"
  fi
  __wezterm_set_user_var GIT_REPO "$repo"
  __wezterm_set_user_var GIT_BRANCH "$branch"
  __wezterm_set_user_var AWS_PROFILE "${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __wezterm_report_status
