import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallet_snap/models/category_model.dart';
import 'package:wallet_snap/providers/category_provider.dart';
import '../../data/default_category_icons.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildIconGrid(
      ColorScheme colorScheme,
      String selectedIconName,
      Function(String) onIconSelected,
      ) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: availableIcons.length,
        itemBuilder: (context, index) {
          final iconEntry = availableIcons.entries.elementAt(index);
          final iconName = iconEntry.key;
          final isSelected = iconName == selectedIconName;

          return InkWell(
            onTap: () => onIconSelected(iconName),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                iconEntry.value,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryBottomSheet(CategoryType type) {
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    String tempSelectedIconName = availableIcons.keys.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24, right: 24, top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Add ${type.name.toUpperCase()} Category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              _buildIconGrid(colorScheme, tempSelectedIconName, (newIcon) => setStateSheet(() => tempSelectedIconName = newIcon)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    provider.addCategory(nameController.text.trim(), type, tempSelectedIconName);
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoryProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.outline,
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(provider.expenseCategories, CategoryType.expense, provider, colorScheme),
          _buildCategoryList(provider.incomeCategories, CategoryType.income, provider, colorScheme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryBottomSheet(_tabController.index == 0 ? CategoryType.expense : CategoryType.income),
        label: const Text('Add Category'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, CategoryType type, CategoryProvider provider, ColorScheme colorScheme) {
    if (categories.isEmpty) {
      return Center(child: Text('No categories found.', style: TextStyle(color: colorScheme.outline)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(availableIcons[category.iconName], color: colorScheme.primary, size: 22),
            ),
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              onPressed: () => _confirmDeletion(context, category, provider, colorScheme),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletion(BuildContext context, CategoryModel category, CategoryProvider provider, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: colorScheme.outline))),
          FilledButton(
            onPressed: () {
              provider.deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}