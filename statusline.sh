#!/usr/bin/env bash
# ~/.claude/statusline.sh — Claude Code status line. Left to right:
#   <thin colored context bar, % in the center>  ·  <effort> · <model> · <tokens>
# The bar uses ━/─ glyphs (thin), fills from the left in proportion to context %,
# and the percentage is written in the CENTER of the bar (without lengthening it).
# Bar color by threshold: 0–20 blue, 21–90 green, 91–95 yellow, 96–100 red.
# used_percentage can be null (fresh start / after /compact) → 0%;
# effort.level may be absent (model without reasoning effort) → that segment is hidden.
# Deliberately WITHOUT `set -e`: the status line must never blank out over a trifle.

input=$(cat)

model=$(printf '%s'  "$input" | jq -r '.model.display_name // "Claude"')
effort=$(printf '%s' "$input" | jq -r '.effort.level // ""')
pct_raw=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0')
size=$(printf '%s'   "$input" | jq -r '.context_window.context_window_size // 200000')
in_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
pct=$(printf '%.0f' "$pct_raw" 2>/dev/null); [ -z "$pct" ] && pct=0
[ "$pct" -lt 0 ]   && pct=0
[ "$pct" -gt 100 ] && pct=100

WIDTH=26     # bar length in characters (thin; tweak to taste)

# --- bar color by threshold ---
if   [ "$pct" -le 20 ]; then color=$'\033[38;5;39m'    # blue    0–20
elif [ "$pct" -le 90 ]; then color=$'\033[38;5;40m'    # green   21–90
elif [ "$pct" -le 95 ]; then color=$'\033[38;5;220m'   # yellow  91–95
else                        color=$'\033[38;5;196m'    # red     96–100
fi
dim=$'\033[38;5;240m'            # unfilled part of the bar / separators
bold=$'\033[1m'                  # percentage digits
reset=$'\033[0m'
mcol=$'\033[1m\033[38;5;252m'    # model
ecol=$'\033[38;5;244m'           # effort
tcol=$'\033[38;5;244m'           # tokens
sep=$'\033[38;5;240m'            # separator

# --- how many cells are filled ---
fill=$(( (pct * WIDTH + 50) / 100 ))              # round to the nearest cell
[ "$fill" -gt "$WIDTH" ] && fill=$WIDTH
[ "$pct" -gt 0 ] && [ "$fill" -eq 0 ] && fill=1   # >0% → at least one visible cell

# --- percentage label centered on the bar ---
label=" ${pct}% "
L=${#label}
start=$(( (WIDTH - L) / 2 )); [ "$start" -lt 0 ] && start=0
end=$(( start + L ))

# --- build the bar cell by cell ---
bar=""
for (( i=0; i<WIDTH; i++ )); do
  if (( i >= start && i < end )); then
    bar+="${bold}${color}${label:i-start:1}"     # label character (incl. space)
  elif (( i < fill )); then
    bar+="${color}━"                             # filled part
  else
    bar+="${dim}─"                               # empty part
  fi
done
bar+="$reset"

# --- human-readable tokens (340000 → 340k, 1000000 → 1.0M) ---
human() { awk -v n="$1" 'BEGIN{ if(n>=1e6) printf "%.1fM", n/1e6; else if(n>=1e3) printf "%dk", int(n/1e3+0.5); else printf "%d", n }'; }
tok="$(human "$in_tok")/$(human "$size")"

# --- right tail: effort · model · tokens (effort hidden when empty) ---
sepstr=" ${sep}·${reset} "
right=""
[ -n "$effort" ] && right="${ecol}${effort}${reset}"
[ -n "$right" ] && right+="$sepstr"; right+="${mcol}${model}${reset}"
right+="${sepstr}${tcol}${tok}${reset}"

printf '%s  %s\n' "$bar" "$right"
