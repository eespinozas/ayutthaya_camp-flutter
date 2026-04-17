// {{FeatureName}} Page (Presentation Layer)
// Main UI screen for {{feature_name}} feature

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/{{feature_name}}_viewmodel.dart';
import '../../../../core/widgets/loading_overlay.dart'; // TODO: Adjust path if needed
import '../../../../core/widgets/error_message.dart'; // TODO: Adjust path if needed

class {{FeatureName}}Page extends StatefulWidget {
  const {{FeatureName}}Page({Key? key}) : super(key: key);

  @override
  State<{{FeatureName}}Page> createState() => _{{FeatureName}}PageState();
}

class _{{FeatureName}}PageState extends State<{{FeatureName}}Page> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final viewModel = context.read<{{FeatureName}}ViewModel>();
    // TODO: Get userId from AuthViewModel or context
    await viewModel.loadAll('USER_ID_HERE');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{FeatureName}}s'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreate{{FeatureName}}Dialog,
          ),
        ],
      ),
      body: Consumer<{{FeatureName}}ViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.{{feature_name}}s.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return ErrorMessage(
              message: viewModel.error!,
              onRetry: _loadData,
            );
          }

          if (viewModel.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              itemCount: viewModel.{{feature_name}}s.length,
              itemBuilder: (context, index) {
                final {{feature_name}} = viewModel.{{feature_name}}s[index];
                return _build{{FeatureName}}Tile({{feature_name}});
              },
            ),
          );
        },
      ),
    );
  }

  Widget _build{{FeatureName}}Tile({{FeatureName}} {{feature_name}}) {
    return ListTile(
      title: Text('{{FeatureName}} ${{{feature_name}}.id}'),
      subtitle: Text('Created: ${{{feature_name}}.createdAt.toString()}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEdit{{FeatureName}}Dialog({{feature_name}}),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete({{feature_name}}.id),
          ),
        ],
      ),
      onTap: () => _showDetails({{feature_name}}),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No {{feature_name}}s yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showCreate{{FeatureName}}Dialog,
            child: const Text('Create First {{FeatureName}}'),
          ),
        ],
      ),
    );
  }

  void _showCreate{{FeatureName}}Dialog() {
    // TODO: Implement create dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create {{FeatureName}}'),
        content: const Text('TODO: Add form fields'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Create {{feature_name}}
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEdit{{FeatureName}}Dialog({{FeatureName}} {{feature_name}}) {
    // TODO: Implement edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit {{FeatureName}}'),
        content: const Text('TODO: Add form fields'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update {{feature_name}}
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDetails({{FeatureName}} {{feature_name}}) {
    // TODO: Navigate to details page or show bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '{{FeatureName}} Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('ID: ${{{feature_name}}.id}'),
            Text('User ID: ${{{feature_name}}.userId}'),
            Text('Created: ${{{feature_name}}.createdAt}'),
            if ({{feature_name}}.updatedAt != null)
              Text('Updated: ${{{feature_name}}.updatedAt}'),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this {{feature_name}}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final viewModel = context.read<{{FeatureName}}ViewModel>();
      final success = await viewModel.delete(id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('{{FeatureName}} deleted successfully')),
        );
      }
    }
  }
}
