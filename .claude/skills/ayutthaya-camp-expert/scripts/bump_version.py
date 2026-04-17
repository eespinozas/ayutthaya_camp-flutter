#!/usr/bin/env python3
"""
Bump Version Script for Ayutthaya Camp

Intelligently updates version in pubspec.yaml

Usage:
    python bump_version.py {version}
    python bump_version.py patch
    python bump_version.py minor
    python bump_version.py major

Examples:
    python bump_version.py 1.2.3          # Set exact version
    python bump_version.py patch          # 1.0.0 → 1.0.1
    python bump_version.py minor          # 1.0.0 → 1.1.0
    python bump_version.py major          # 1.0.0 → 2.0.0
"""

import os
import sys
import re
from pathlib import Path


def parse_version(version_str):
    """Parse version string like '1.2.3+45' into (major, minor, patch, build)"""
    match = re.match(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$', version_str)
    if not match:
        return None

    major, minor, patch, build = match.groups()
    return (int(major), int(minor), int(patch), int(build) if build else 1)


def bump_version(current, bump_type):
    """Bump version based on type (major, minor, patch)"""
    major, minor, patch, build = current

    if bump_type == 'major':
        return (major + 1, 0, 0, 1)
    elif bump_type == 'minor':
        return (major, minor + 1, 0, 1)
    elif bump_type == 'patch':
        return (major, minor, patch + 1, 1)
    else:
        return None


def format_version(version_tuple):
    """Format version tuple as string"""
    major, minor, patch, build = version_tuple
    return f"{major}.{minor}.{patch}+{build}"


def get_current_version(pubspec_path):
    """Extract current version from pubspec.yaml"""
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()

    match = re.search(r'^version:\s*(.+)$', content, re.MULTILINE)
    if not match:
        return None

    version_str = match.group(1).strip()
    return parse_version(version_str)


def update_pubspec(pubspec_path, new_version_str):
    """Update version in pubspec.yaml"""
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = re.sub(
        r'^version:\s*.+$',
        f'version: {new_version_str}',
        content,
        flags=re.MULTILINE
    )

    with open(pubspec_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return True


def calculate_build_number():
    """Calculate build number from git commits"""
    import subprocess

    try:
        result = subprocess.run(
            ['git', 'rev-list', '--count', 'HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except:
        return None


def main():
    if len(sys.argv) != 2:
        print("Usage: python bump_version.py {version|patch|minor|major}")
        print("\nExamples:")
        print("  python bump_version.py 1.2.3    # Set exact version")
        print("  python bump_version.py patch    # Bump patch version")
        print("  python bump_version.py minor    # Bump minor version")
        print("  python bump_version.py major    # Bump major version")
        sys.exit(1)

    arg = sys.argv[1]

    # Find pubspec.yaml
    current_dir = Path.cwd()
    pubspec_path = None

    for parent in [current_dir] + list(current_dir.parents):
        candidate = parent / 'pubspec.yaml'
        if candidate.exists():
            pubspec_path = candidate
            break

    if not pubspec_path:
        print("❌ Error: pubspec.yaml not found")
        sys.exit(1)

    print(f"📄 Found pubspec.yaml: {pubspec_path}")

    # Get current version
    current = get_current_version(pubspec_path)
    if not current:
        print("❌ Error: Could not parse current version from pubspec.yaml")
        sys.exit(1)

    current_str = format_version(current)
    print(f"📌 Current version: {current_str}")

    # Determine new version
    new_version = None

    if arg in ['major', 'minor', 'patch']:
        # Bump version
        new_version = bump_version(current, arg)
        if not new_version:
            print(f"❌ Error: Invalid bump type: {arg}")
            sys.exit(1)

        print(f"⬆️  Bumping {arg} version")
    else:
        # Parse as explicit version
        parsed = parse_version(arg)
        if not parsed:
            print(f"❌ Error: Invalid version format: {arg}")
            print("   Expected format: X.Y.Z or X.Y.Z+BUILD")
            sys.exit(1)

        new_version = parsed
        print(f"🎯 Setting explicit version")

    # Calculate build number from git if not specified
    major, minor, patch, build = new_version

    if build == 1:
        git_build = calculate_build_number()
        if git_build:
            new_version = (major, minor, patch, git_build)
            print(f"🔢 Auto-calculated build number from git: {git_build}")

    new_version_str = format_version(new_version)

    print(f"\n✨ New version: {new_version_str}")

    # Confirm
    confirm = input("\n⚠️  Update pubspec.yaml? (y/N): ")
    if confirm.lower() != 'y':
        print("❌ Aborted")
        sys.exit(0)

    # Update pubspec.yaml
    if update_pubspec(pubspec_path, new_version_str):
        print(f"✅ Updated pubspec.yaml to version {new_version_str}")

        print("\n📝 Next steps:")
        print(f"1. Review changes: git diff pubspec.yaml")
        print(f"2. Commit: git add pubspec.yaml && git commit -m 'Bump version to {new_version_str}'")
        print(f"3. Tag: git tag -a v{major}.{minor}.{patch} -m 'Release v{major}.{minor}.{patch}'")
        print(f"4. Push: git push origin main && git push origin v{major}.{minor}.{patch}")
    else:
        print("❌ Error: Failed to update pubspec.yaml")
        sys.exit(1)


if __name__ == '__main__':
    main()
