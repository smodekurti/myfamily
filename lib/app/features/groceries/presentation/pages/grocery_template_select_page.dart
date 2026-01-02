import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/grocery_template_model.dart';
import 'grocery_list_page.dart'; // Import to access groceryTemplatesProvider

class GroceryTemplateSelectPage extends ConsumerWidget {
  const GroceryTemplateSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final templates = currentFamily != null
        ? ref.watch(groceryTemplatesProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryTemplateModel>[]);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Template'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: templates.when(
            data: (templateList) {
              if (templateList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: ResponsiveHelper.padding(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: ResponsiveHelper.iconSize(60),
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                        Text(
                          'No templates available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(8)),
                        Text(
                          'Create a template first to use it here',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: ResponsiveHelper.padding(all: 16),
                itemCount: templateList.length,
                itemBuilder: (context, index) {
                  final template = templateList[index];
                  return _buildTemplateCard(context, template);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading templates: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, GroceryTemplateModel template) {
    // Map template name to icon and color
    IconData icon;
    Color iconColor;
    
    if (template.name.toLowerCase().contains('weekly') || 
        template.name.toLowerCase().contains('grocery')) {
      icon = Icons.shopping_bag;
      iconColor = Theme.of(context).colorScheme.primary; // Teal
    } else if (template.name.toLowerCase().contains('pantry')) {
      icon = Icons.kitchen;
      iconColor = Colors.orange;
    } else {
      icon = Icons.shopping_cart;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: ResponsiveHelper.padding(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: ListTile(
        contentPadding: ResponsiveHelper.padding(all: 16),
        leading: Container(
          width: ResponsiveHelper.w(48),
          height: ResponsiveHelper.h(48),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: ResponsiveHelper.borderRadius(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: ResponsiveHelper.iconSize(24),
          ),
        ),
        title: Text(
          template.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: () {
          // Return the template ID
          context.pop(template.id);
        },
      ),
    );
  }
}

