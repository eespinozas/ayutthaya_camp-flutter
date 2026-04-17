#!/bin/bash

# ========================================
# Versioning Script for Flutter App
# ========================================
# This script manages version numbers for the Flutter app
# Usage:
#   ./scripts/versioning.sh bump <major|minor|patch>
#   ./scripts/versioning.sh set <version>
#   ./scripts/versioning.sh get
#   ./scripts/versioning.sh code
# ========================================

set -e

PUBSPEC_FILE="pubspec.yaml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# ========================================
# FUNCTIONS
# ========================================

get_current_version() {
    grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | cut -d'+' -f1
}

get_current_build_number() {
    grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | cut -d'+' -f2
}

get_version_code_from_git() {
    git rev-list --count HEAD 2>/dev/null || echo "1"
}

set_version() {
    local version=$1
    local build_number=$2

    if [ -z "$build_number" ]; then
        build_number=$(get_version_code_from_git)
    fi

    # Validate version format (X.Y.Z)
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Invalid version format. Expected: X.Y.Z (e.g., 1.2.3)"
        exit 1
    fi

    # Update pubspec.yaml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version:.*/version: ${version}+${build_number}/" "$PUBSPEC_FILE"
    else
        # Linux
        sed -i "s/^version:.*/version: ${version}+${build_number}/" "$PUBSPEC_FILE"
    fi

    echo "✅ Version updated to ${version}+${build_number}"
    echo "   - Version Name: ${version}"
    echo "   - Version Code: ${build_number}"
}

bump_version() {
    local bump_type=$1
    local current_version
    current_version=$(get_current_version)

    IFS='.' read -r major minor patch <<< "$current_version"

    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo "❌ Invalid bump type. Use: major, minor, or patch"
            exit 1
            ;;
    esac

    new_version="${major}.${minor}.${patch}"
    build_number=$(get_version_code_from_git)

    set_version "$new_version" "$build_number"
}

create_git_tag() {
    local version=$1
    local tag="v${version}"

    if git rev-parse "$tag" >/dev/null 2>&1; then
        echo "⚠️  Tag $tag already exists"
        exit 1
    fi

    git tag -a "$tag" -m "Release $tag"
    echo "✅ Created tag: $tag"
    echo "   Run 'git push origin $tag' to push the tag"
}

show_current_info() {
    local version
    local build_number
    local git_commit
    local git_commits

    version=$(get_current_version)
    build_number=$(get_current_build_number)
    git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    git_commits=$(get_version_code_from_git)

    echo "📱 Current Version Information"
    echo "────────────────────────────────"
    echo "Version Name:    ${version}"
    echo "Build Number:    ${build_number}"
    echo "Git Commit:      ${git_commit}"
    echo "Git Commits:     ${git_commits}"
    echo "────────────────────────────────"
}

# ========================================
# MAIN
# ========================================

case "${1:-}" in
    bump)
        bump_version "${2:-patch}"
        show_current_info
        echo ""
        echo "💡 To create a git tag, run:"
        echo "   git tag -a v$(get_current_version) -m 'Release v$(get_current_version)'"
        echo "   git push origin v$(get_current_version)"
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo "❌ Please provide a version number"
            echo "Usage: $0 set <version> [build_number]"
            exit 1
        fi
        set_version "$2" "${3:-}"
        show_current_info
        ;;
    get)
        get_current_version
        ;;
    code)
        get_version_code_from_git
        ;;
    info)
        show_current_info
        ;;
    tag)
        version=$(get_current_version)
        create_git_tag "$version"
        ;;
    *)
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  bump <major|minor|patch>   Bump version and auto-calculate build number"
        echo "  set <version> [build]      Set specific version and build number"
        echo "  get                        Get current version name"
        echo "  code                       Get version code from git commit count"
        echo "  info                       Show current version information"
        echo "  tag                        Create git tag for current version"
        echo ""
        echo "Examples:"
        echo "  $0 bump patch              # 1.0.0 -> 1.0.1"
        echo "  $0 bump minor              # 1.0.1 -> 1.1.0"
        echo "  $0 bump major              # 1.1.0 -> 2.0.0"
        echo "  $0 set 2.5.0               # Set to 2.5.0 with auto build number"
        echo "  $0 set 2.5.0 100           # Set to 2.5.0+100"
        echo "  $0 info                    # Show current version info"
        exit 1
        ;;
esac
