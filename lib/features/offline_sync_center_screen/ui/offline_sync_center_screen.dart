import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';
import 'package:odoo_mobile_app/features/offline_sync_center_screen/logic/cubits/sync_center_cubit.dart';

class OfflineSyncCenterScreen extends StatefulWidget {
  const OfflineSyncCenterScreen({super.key});

  @override
  State<OfflineSyncCenterScreen> createState() => _OfflineSyncCenterScreenState();
}

class _OfflineSyncCenterScreenState extends State<OfflineSyncCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SyncCenterCubit>().loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SQLite Offline Queue"),
        actions: [
          IconButton(
            tooltip: "Sync All Queued Items",
            icon: const Icon(Icons.sync),
            onPressed: () => context.read<SyncCenterCubit>().forceSyncAll(),
          ),
        ],
      ),
      body: BlocConsumer<SyncCenterCubit, SyncCenterState>(
        listener: (context, state) {
          if (state is SyncCenterActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is SyncCenterLoading) return const ShimmerCardSkeleton();
          final drafts = state is SyncCenterLoaded
              ? state.drafts
              : (state is SyncCenterActionSuccess ? state.drafts : []);

          if (drafts.isEmpty) {
            return const Center(child: Text("All SQLite offline records are synced!"));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (_, i) {
              final d = drafts[i];
              final isPo = d['action_type'] == 'purchase_order';
              return SoftShadowCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    isPo ? Icons.shopping_bag : Icons.receipt_long,
                    color: isPo ? Colors.deepPurple : Colors.orange,
                  ),
                  title: Text("${isPo ? 'PO' : 'SO'} Draft #${d['id']}"),
                  subtitle: Text("Partner: ${d['partner_name']} • Items: ${(d['order_lines'] as List).length}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => context.read<SyncCenterCubit>().removeDraft(d['id'].toString()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
