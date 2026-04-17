#!/usr/bin/env python3
"""
Scaffold Feature Script for Ayutthaya Camp

Generates a complete Clean Architecture feature structure from templates.

Usage:
    python scaffold_feature.py {feature_name}

Example:
    python scaffold_feature.py notifications

This creates:
    lib/features/notifications/
    ├── data/
    │   ├── dto/
    │   │   └── notification_dto.dart
    │   └── repositories/
    │       └── notification_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── notification.dart
    │   └── repositories/
    │       └── notification_repository.dart
    └── presentation/
        ├── pages/
        │   └── notification_page.dart
        ├── viewmodels/
        │   └── notification_viewmodel.dart
        └── widgets/
            └── .gitkeep
"""

import os
import sys
import re
from pathlib import Path


def to_pascal_case(snake_str):
    """Convert snake_case to PascalCase"""
    return ''.join(word.capitalize() for word in snake_str.split('_'))


def to_upper_case(snake_str):
    """Convert snake_case to UPPER_CASE"""
    return snake_str.upper()


def replace_placeholders(content, feature_name):
    """Replace template placeholders with actual values"""
    pascal_case = to_pascal_case(feature_name)
    upper_case = to_upper_case(feature_name)

    replacements = {
        '{{FeatureName}}': pascal_case,
        '{{feature_name}}': feature_name,
        '{{FEATURE_NAME}}': upper_case,
    }

    for placeholder, value in replacements.items():
        content = content.replace(placeholder, value)

    return content


def create_directory_structure(base_path, feature_name):
    """Create the feature directory structure"""
    directories = [
        f"{base_path}/data/dto",
        f"{base_path}/data/repositories",
        f"{base_path}/domain/entities",
        f"{base_path}/domain/repositories",
        f"{base_path}/presentation/pages",
        f"{base_path}/presentation/viewmodels",
        f"{base_path}/presentation/widgets",
    ]

    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"✅ Created: {directory}")

    # Create .gitkeep in widgets folder
    widgets_path = f"{base_path}/presentation/widgets/.gitkeep"
    Path(widgets_path).touch()


def copy_and_process_template(template_path, target_path, feature_name):
    """Copy template file and replace placeholders"""
    try:
        with open(template_path, 'r', encoding='utf-8') as f:
            content = f.read()

        processed_content = replace_placeholders(content, feature_name)

        with open(target_path, 'w', encoding='utf-8') as f:
            f.write(processed_content)

        print(f"✅ Generated: {target_path}")
        return True
    except FileNotFoundError:
        print(f"⚠️  Template not found: {template_path}")
        return False


def scaffold_feature(feature_name):
    """Main scaffolding logic"""
    # Validate feature name
    if not re.match(r'^[a-z_]+$', feature_name):
        print("❌ Error: Feature name must be lowercase snake_case (e.g., 'notifications')")
        return False

    # Find project root (contains lib/ and pubspec.yaml)
    current_dir = Path.cwd()
    project_root = None

    for parent in [current_dir] + list(current_dir.parents):
        if (parent / 'lib').exists() and (parent / 'pubspec.yaml').exists():
            project_root = parent
            break

    if not project_root:
        print("❌ Error: Not in a Flutter project (lib/ and pubspec.yaml not found)")
        return False

    print(f"📁 Project root: {project_root}")

    # Feature paths
    feature_base = project_root / 'lib' / 'features' / feature_name
    skill_root = project_root / '.claude' / 'skills' / 'ayutthaya-camp-expert'
    templates_root = skill_root / 'templates' / 'feature'

    # Check if feature already exists
    if feature_base.exists():
        print(f"⚠️  Warning: Feature '{feature_name}' already exists at {feature_base}")
        confirm = input("Continue and overwrite? (y/N): ")
        if confirm.lower() != 'y':
            print("❌ Aborted")
            return False

    print(f"\n🚀 Scaffolding feature: {feature_name}")
    print(f"📂 Target: {feature_base}\n")

    # Create directory structure
    create_directory_structure(feature_base, feature_name)

    print("\n📝 Generating files from templates...\n")

    # Template mappings: (template_file, target_file)
    pascal_case = to_pascal_case(feature_name)

    templates = [
        # Domain layer
        (templates_root / 'domain' / 'entity_template.dart',
         feature_base / 'domain' / 'entities' / f'{feature_name}.dart'),

        (templates_root / 'domain' / 'repository_template.dart',
         feature_base / 'domain' / 'repositories' / f'{feature_name}_repository.dart'),

        # Data layer
        (templates_root / 'data' / 'dto_template.dart',
         feature_base / 'data' / 'dto' / f'{feature_name}_dto.dart'),

        (templates_root / 'data' / 'repository_impl_template.dart',
         feature_base / 'data' / 'repositories' / f'{feature_name}_repository_impl.dart'),

        # Presentation layer
        (templates_root / 'presentation' / 'viewmodels' / 'viewmodel_template.dart',
         feature_base / 'presentation' / 'viewmodels' / f'{feature_name}_viewmodel.dart'),

        (templates_root / 'presentation' / 'pages' / 'page_template.dart',
         feature_base / 'presentation' / 'pages' / f'{feature_name}_page.dart'),
    ]

    success_count = 0
    for template_path, target_path in templates:
        if copy_and_process_template(str(template_path), str(target_path), feature_name):
            success_count += 1

    print(f"\n✅ Successfully generated {success_count}/{len(templates)} files")

    # Generate Firestore rules snippet
    print("\n📋 Generating Firestore rules snippet...\n")
    rules_template = skill_root / 'templates' / 'firebase-rules-snippet.rules'
    rules_output = feature_base / 'firestore_rules_snippet.txt'

    if copy_and_process_template(str(rules_template), str(rules_output), feature_name):
        print(f"\n💡 Add the rules from {rules_output} to your firestore.rules file")

    # Next steps
    print(f"\n🎉 Feature '{feature_name}' scaffolded successfully!")
    print("\n📝 Next steps:\n")
    print(f"1. Review generated files in lib/features/{feature_name}/")
    print(f"2. Implement TODO items in each file")
    print(f"3. Add {pascal_case}ViewModel to lib/app/app.dart providers")
    print(f"4. Add navigation route for {pascal_case}Page")
    print(f"5. Update firestore.rules with snippet from firestore_rules_snippet.txt")
    print(f"6. Run: flutter analyze")
    print(f"7. Run: flutter test")

    return True


def main():
    if len(sys.argv) != 2:
        print("Usage: python scaffold_feature.py {feature_name}")
        print("Example: python scaffold_feature.py notifications")
        sys.exit(1)

    feature_name = sys.argv[1]

    success = scaffold_feature(feature_name)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
