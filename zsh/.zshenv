# Loaded for all zsh invocations (login/interactive/non-interactive).
# Keep minimal to avoid side effects in subshells.

# Homebrew supply-chain hardening
# Review before lifting any of these.
export HOMEBREW_NO_AUTO_UPDATE=1        # require explicit `brew update` before install
export HOMEBREW_NO_INSTALL_CLEANUP=1    # prevent surprise removal of older versions
export HOMEBREW_NO_INSECURE_REDIRECT=1  # reject non-https / cross-domain redirects
export HOMEBREW_NO_ENV_HINTS=1          # quiet env suggestion output
export HOMEBREW_NO_ANALYTICS=1          # disable InfluxDB analytics upload
