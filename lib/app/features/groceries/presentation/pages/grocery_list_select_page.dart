import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/grocery_template_model.dart';
import 'grocery_list_page.dart'; // Import to access standaloneGroceryListsProvider

class GroceryListSelectPage extends ConsumerWidget {
  const GroceryListSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final lists = currentFamily != null
        ? ref.watch(standaloneGroceryListsProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryListModel>[]);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Shopping List'),
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: lists.when(
            data: (listList) {
              if (listList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: ResponsiveHelper.padding(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: ResponsiveHelper.iconSize(60),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                        Text(
                          'No shopping lists available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(8)),
                        Text(
                          'Create a shopping list first to use it here',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                itemCount: listList.length,
                itemBuilder: (context, index) {
                  final list = listList[index];
                  return _buildListCard(context, list);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading lists: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, GroceryListModel list) {
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: ResponsiveHelper.borderRadius(12),
          ),
          child: Icon(
            Icons.shopping_cart,
            color: Theme.of(context).colorScheme.primary,
            size: ResponsiveHelper.iconSize(24),
          ),
        ),
        title: Text(
          list.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: () {
          // Return the list ID
          context.pop(list.id);
        },
      ),
    );
  }
}

