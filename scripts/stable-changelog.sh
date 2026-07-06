#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/stable-changelog.sh CANDIDATE_SHA RELEASE_VERSION OUTPUT_FILE

Generate a detailed stable-branch changelog for CANDIDATE_SHA.
USAGE
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '==> %s\n' "$*" >&2
}

candidate_sha="${1:-}"
release_version="${2:-}"
output_file="${3:-}"
stable_branch="${STABLE_BRANCH:-stable}"
model="${AI_CHANGELOG_MODEL:-openai/gpt-4.1}"

if [ -z "$candidate_sha" ] || [ -z "$release_version" ] || [ -z "$output_file" ]; then
  usage >&2
  exit 2
fi

git rev-parse --verify "$candidate_sha^{commit}" >/dev/null ||
  die "candidate commit does not exist: $candidate_sha"

previous_source_sha=""
has_stable=0
if git rev-parse --verify "origin/$stable_branch^{commit}" >/dev/null 2>&1; then
  has_stable=1
  previous_source_sha="$(
    git log --format=%B -n 1 "origin/$stable_branch" |
      sed -nE 's/^Squashed from ([0-9a-f]{40})\.?$/\1/p' |
      head -n 1
  )"
fi

if [ -n "$previous_source_sha" ] &&
  ! git merge-base --is-ancestor "$previous_source_sha" "$candidate_sha"; then
  info "Previous source $previous_source_sha is not an ancestor of $candidate_sha; using full candidate history"
  previous_source_sha=""
fi

if [ -n "$previous_source_sha" ]; then
  log_range="$previous_source_sha..$candidate_sha"
  diff_range="$previous_source_sha..$candidate_sha"
  range_label="$previous_source_sha..$candidate_sha"
elif [ "$has_stable" -eq 1 ]; then
  log_range="origin/$stable_branch..$candidate_sha"
  diff_range="origin/$stable_branch..$candidate_sha"
  range_label="origin/$stable_branch..$candidate_sha"
else
  empty_tree="$(git hash-object -t tree /dev/null)"
  log_range="$candidate_sha"
  diff_range="$empty_tree..$candidate_sha"
  range_label="$candidate_sha"
fi

fallback_file="$(mktemp)"
prompt_file="$(mktemp)"
response_file="$(mktemp)"
trap 'rm -f "$fallback_file" "$prompt_file" "$response_file"' EXIT

if ! git log --reverse --format='- %s (%h)' "$log_range" >"$fallback_file"; then
  git log --reverse --format='- %s (%h)' "$candidate_sha" >"$fallback_file"
fi

if [ ! -s "$fallback_file" ]; then
  printf -- '- No commit changes detected.\n' >"$fallback_file"
fi

python3 - "$candidate_sha" "$release_version" "$log_range" "$diff_range" "$range_label" >"$prompt_file" <<'PY'
import subprocess
import sys

candidate_sha, release_version, log_range, diff_range, range_label = sys.argv[1:6]


def run_git(args, limit=60000):
    try:
        text = subprocess.check_output(["git", *args], text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        text = ""
    if len(text) > limit:
        return text[:limit] + "\n[truncated]\n"
    return text


commits = run_git([
    "log",
    "--reverse",
    "--format=commit %h%nsubject: %s%nbody:%n%b%n---",
    log_range,
], 30000)
diff_stat = run_git(["diff", "--stat", diff_range], 12000)
name_status = run_git(["diff", "--name-status", diff_range], 20000)
summary = run_git(["diff", "--compact-summary", diff_range], 20000)
shortstat = run_git(["diff", "--shortstat", diff_range], 2000)

print(f"""你是这个 nix-darwin / Home Manager 配置仓库的发布说明维护者。

请基于下面提供的 git 上下文，为 stable 分支 squash commit 生成中文 changelog。

要求：
- 只依据提供的 commit 和 diff 信息，不要编造不存在的改动。
- 内容要详细完整，但保持 commit message 适合阅读。
- 按子系统或主题分组，例如 CI/发布、nix-darwin、Home Manager、Shell/工具、文档等；没有相关改动的分组不要写。
- 每个分组使用 Markdown 二级标题 `## 标题`，条目使用 `- `。
- 说明用户可见影响和配置行为变化，避免逐文件机械罗列。
- 不要添加开场白、结尾客套、emoji 或代码围栏。

Release version: {release_version}
Candidate SHA: {candidate_sha}
Change range: {range_label}

Commit log:
{commits}

Diff shortstat:
{shortstat}

Diff stat:
{diff_stat}

Changed files:
{name_status}

Diff compact summary:
{summary}
""")
PY

write_fallback() {
  {
    printf 'AI changelog generation failed; fallback git log:\n\n'
    cat "$fallback_file"
  } >"$output_file"
}

if [ -z "${GITHUB_TOKEN:-}" ]; then
  info "GITHUB_TOKEN is not set; writing fallback changelog"
  write_fallback
  exit 0
fi

if ! python3 - "$model" "$prompt_file" "$response_file" <<'PY'; then
import json
import pathlib
import subprocess
import sys

model, prompt_path, response_path = sys.argv[1:4]
prompt = pathlib.Path(prompt_path).read_text()
payload = {
    "model": model,
    "messages": [
        {
            "role": "system",
            "content": "Generate accurate release changelogs from repository context.",
        },
        {"role": "user", "content": prompt},
    ],
    "temperature": 0.2,
    "max_tokens": 1800,
}
result = subprocess.run(
    [
        "curl",
        "-fsS",
        "https://models.github.ai/inference/chat/completions",
        "-H",
        "Accept: application/vnd.github+json",
        "-H",
        "Content-Type: application/json",
        "-H",
        "Authorization: Bearer " + __import__("os").environ["GITHUB_TOKEN"],
        "-d",
        json.dumps(payload),
    ],
    text=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)
if result.returncode != 0:
    sys.stderr.write(result.stderr)
    sys.exit(result.returncode)

pathlib.Path(response_path).write_text(result.stdout)
PY
  info "GitHub Models request failed; writing fallback changelog"
  write_fallback
  exit 0
fi

if ! python3 - "$response_file" "$output_file" <<'PY'; then
import json
import pathlib
import sys

response_path, output_path = sys.argv[1:3]
data = json.loads(pathlib.Path(response_path).read_text())
content = data["choices"][0]["message"]["content"].strip()
if not content:
    raise ValueError("empty model response")
pathlib.Path(output_path).write_text(content + "\n")
PY
  info "GitHub Models response was invalid; writing fallback changelog"
  write_fallback
fi
