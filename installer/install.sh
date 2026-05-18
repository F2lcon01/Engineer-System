#!/bin/bash
#
# Install-EngineerSystem.sh
# Installs the Principal Engineer System into the current project.
#
# Usage:
#   ./install.sh                     # install in current dir from default source
#   ./install.sh -t /path/to/project # install in specific target
#   ./install.sh -m Upgrade          # upgrade mode (preserves user data)
#   ./install.sh -m DryRun           # show what would change without writing

set -euo pipefail

# ==================== Configuration ====================

SOURCE_PATH="${HOME}/Desktop/Engineer System"
TARGET_PATH="$(pwd)"
MODE="Install"
FORCE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
RESET='\033[0m'

# Counters
CREATED=0
UPDATED=0
SKIPPED=0
WARNINGS=()

# ==================== Output helpers ====================

step()    { echo -e "${CYAN}→ $1${RESET}"; }
ok()      { echo -e "${GREEN}✓ $1${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $1${RESET}"; WARNINGS+=("$1"); }
err()     { echo -e "${RED}✗ $1${RESET}"; }
info()    { echo -e "${GRAY}  $1${RESET}"; }

banner() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${RESET}"
    echo -e "${MAGENTA}    Principal Engineer System — Installer v1.0${RESET}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${RESET}"
    echo ""
}

# ==================== Argument parsing ====================

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -s, --source PATH    Source folder (default: ~/Desktop/Engineer System)
    -t, --target PATH    Target project (default: current directory)
    -m, --mode MODE      Install | Upgrade | DryRun (default: Install)
    -f, --force          Overwrite without prompting
    -h, --help           Show this help

EXAMPLES:
    $0
    $0 -t ~/projects/polar-os -m Upgrade
    $0 -m DryRun
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source) SOURCE_PATH="$2"; shift 2 ;;
        -t|--target) TARGET_PATH="$2"; shift 2 ;;
        -m|--mode)   MODE="$2"; shift 2 ;;
        -f|--force)  FORCE=true; shift ;;
        -h|--help)   usage ;;
        *) err "خيار غير معروف: $1"; usage ;;
    esac
done

# Validate mode
if [[ ! "$MODE" =~ ^(Install|Upgrade|DryRun)$ ]]; then
    err "Mode غير صالح: $MODE (يجب أن يكون Install/Upgrade/DryRun)"
    exit 1
fi

DRY_RUN=false
[[ "$MODE" == "DryRun" ]] && DRY_RUN=true

# ==================== Validation ====================

check_prerequisites() {
    step "التحقق من المتطلبات..."

    # Bash version
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
        warn "Bash 4+ موصى به. الإصدار الحالي: $BASH_VERSION"
    else
        info "Bash $BASH_VERSION"
    fi

    # Source exists
    if [[ ! -d "$SOURCE_PATH" ]]; then
        err "مجلد المصدر غير موجود: $SOURCE_PATH"
        err "تأكد أن النظام محفوظ في المسار المطلوب."
        exit 1
    fi
    info "المصدر: $SOURCE_PATH"

    # Required files
    local required=("CLAUDE.md" ".claude/settings.json" "memory/PROJECT_MAP.md")
    for file in "${required[@]}"; do
        if [[ ! -e "$SOURCE_PATH/$file" ]]; then
            err "ملف أساسي مفقود في المصدر: $file"
            exit 1
        fi
    done
    info "ملفات النظام مكتملة"

    # Target exists
    if [[ ! -d "$TARGET_PATH" ]]; then
        err "مجلد الهدف غير موجود: $TARGET_PATH"
        exit 1
    fi
    info "الهدف: $TARGET_PATH"

    # Claude Code
    if ! command -v claude &> /dev/null; then
        warn "Claude Code CLI غير مثبّت. ثبّته بـ: npm install -g @anthropic-ai/claude-code"
    else
        info "Claude Code متاح"
    fi

    ok "المتطلبات مكتملة"
}

# ==================== Conflict detection ====================

CONFLICT_CLAUDE_MD=false
CONFLICT_PROJECT_MAP=false
CONFLICT_CLAUDE_DIR=false
CONFLICT_HAS_DATA=false

detect_conflicts() {
    step "فحص الـ Conflicts..."

    if [[ -f "$TARGET_PATH/CLAUDE.md" ]]; then
        CONFLICT_CLAUDE_MD=true
        local size=$(du -k "$TARGET_PATH/CLAUDE.md" | cut -f1)
        info "CLAUDE.md موجود مسبقاً (${size} KB)"
    fi

    if [[ -f "$TARGET_PATH/memory/PROJECT_MAP.md" ]]; then
        CONFLICT_PROJECT_MAP=true
        # Check for actual session data
        if grep -qE '^### Session [0-9]+' "$TARGET_PATH/memory/PROJECT_MAP.md" 2>/dev/null; then
            CONFLICT_HAS_DATA=true
            info "PROJECT_MAP.md يحتوي بيانات فعلية — سيُحمى"
        fi
    fi

    if [[ -d "$TARGET_PATH/.claude" ]]; then
        CONFLICT_CLAUDE_DIR=true
        local count=$(find "$TARGET_PATH/.claude" -type f | wc -l | tr -d ' ')
        info ".claude/ موجود ($count ملف)"
    fi
}

resolve_install_mode() {
    [[ "$DRY_RUN" == true ]] && return

    if [[ "$MODE" == "Install" ]] && [[ "$CONFLICT_CLAUDE_MD" == true || "$CONFLICT_CLAUDE_DIR" == true ]] && [[ "$FORCE" != true ]]; then
        echo ""
        warn "النظام مثبّت سابقاً في هذا المشروع."
        echo ""
        echo -e "${YELLOW}خياراتك:${RESET}"
        echo -e "${GRAY}  1. أعد تشغيل بـ -m Upgrade للتحديث (يحفظ بياناتك)${RESET}"
        echo -e "${GRAY}  2. أعد تشغيل بـ -f للاستبدال (خطر)${RESET}"
        echo -e "${GRAY}  3. احذف الملفات يدوياً${RESET}"
        echo ""
        err "العملية أُلغيت"
        exit 1
    fi
}

# ==================== Copy operations ====================

copy_with_protection() {
    local src="$1"
    local dst="$2"
    local protect="${3:-false}"

    local rel="${dst#$TARGET_PATH/}"

    if [[ "$protect" == true && -f "$dst" ]]; then
        info "تخطي (محمي): $rel"
        ((SKIPPED++)) || true
        return
    fi

    # Ensure parent dir
    local parent
    parent="$(dirname "$dst")"
    if [[ ! -d "$parent" ]]; then
        [[ "$DRY_RUN" != true ]] && mkdir -p "$parent"
    fi

    local action="Created"
    [[ -f "$dst" ]] && action="Updated"

    if [[ "$DRY_RUN" != true ]]; then
        cp -f "$src" "$dst"
    fi

    info "$action: $rel"
    if [[ "$action" == "Created" ]]; then ((CREATED++)) || true; else ((UPDATED++)) || true; fi
}

install_files() {
    step "نسخ ملفات النظام..."

    # 1. CLAUDE.md
    local protect_claude=false
    [[ "$MODE" == "Upgrade" && "$CONFLICT_CLAUDE_MD" == true ]] && protect_claude=true
    copy_with_protection "$SOURCE_PATH/CLAUDE.md" "$TARGET_PATH/CLAUDE.md" "$protect_claude"

    # 2. .claude/ — always refresh
    while IFS= read -r -d '' file; do
        local rel="${file#$SOURCE_PATH/.claude/}"
        copy_with_protection "$file" "$TARGET_PATH/.claude/$rel" "false"
    done < <(find "$SOURCE_PATH/.claude" -type f -print0)

    # 3. PROJECT_MAP — protect if has data
    copy_with_protection \
        "$SOURCE_PATH/memory/PROJECT_MAP.md" \
        "$TARGET_PATH/memory/PROJECT_MAP.md" \
        "$CONFLICT_HAS_DATA"
}

# ==================== Permissions ====================

set_hook_permissions() {
    step "ضبط صلاحيات Hooks..."

    if [[ "$DRY_RUN" == true ]]; then
        info "(DryRun) سيتم chmod +x على .claude/hooks/*.sh"
        return
    fi

    local hooks_dir="$TARGET_PATH/.claude/hooks"
    if [[ ! -d "$hooks_dir" ]]; then
        warn "مجلد hooks غير موجود — تخطي"
        return
    fi

    chmod +x "$hooks_dir"/*.sh 2>/dev/null || true
    info "تم تطبيق chmod +x على hooks"
}

# ==================== Gitignore ====================

update_gitignore() {
    step "تحديث .gitignore..."

    if [[ ! -d "$TARGET_PATH/.git" ]]; then
        info "ليس Git repo — تخطي"
        return
    fi

    local gi="$TARGET_PATH/.gitignore"
    local marker=".claude/.session-edits.log"

    if [[ -f "$gi" ]] && grep -qF "$marker" "$gi"; then
        info ".gitignore يحتوي الإدخالات"
        return
    fi

    if [[ "$DRY_RUN" != true ]]; then
        {
            [[ -f "$gi" ]] && echo ""
            echo "# Principal Engineer System — internal tracking"
            echo "$marker"
        } >> "$gi"
    fi
    info "أُضيفت إدخالات النظام لـ .gitignore"
}

# ==================== Summary ====================

print_summary() {
    local project_name
    project_name="$(basename "$TARGET_PATH")"

    echo ""
    echo -e "${GRAY}───────────────────────────────────────────────────────────${RESET}"
    echo -e "ملخص العملية"
    echo -e "${GRAY}───────────────────────────────────────────────────────────${RESET}"
    echo -e "  ملفات جديدة:  ${GREEN}${CREATED}${RESET}"
    echo -e "  ملفات مُحدّثة: ${CYAN}${UPDATED}${RESET}"
    echo -e "  ملفات محمية:  ${YELLOW}${SKIPPED}${RESET}"

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}تنبيهات:${RESET}"
        for w in "${WARNINGS[@]}"; do
            echo -e "${YELLOW}  • $w${RESET}"
        done
    fi

    echo ""
    echo -e "${YELLOW}خطوات بعد التثبيت:${RESET}"
    echo -e "${GRAY}  1. عدّل CLAUDE.md ليصف '$project_name'${RESET}"
    echo -e "${GRAY}  2. افتح: ${CYAN}claude${RESET}"
    echo -e "${GRAY}  3. تحقق: ${CYAN}/agents${RESET}"
    echo -e "${GRAY}  4. ابدأ: ${CYAN}/plan <مهمتك>${RESET}"

    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo -e "${MAGENTA}═══ DRY RUN — لم يُكتب أي ملف ═══${RESET}"
    else
        echo ""
        ok "اكتمل التثبيت في: $TARGET_PATH"
    fi
    echo ""
}

# ==================== Main ====================

banner

echo -e "${GRAY}الوضع: ${RESET}$MODE"
echo ""

check_prerequisites
echo ""

detect_conflicts
echo ""

resolve_install_mode

install_files
echo ""

set_hook_permissions
echo ""

update_gitignore
echo ""

print_summary

exit 0
