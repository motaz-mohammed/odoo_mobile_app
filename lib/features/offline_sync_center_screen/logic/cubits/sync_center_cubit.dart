import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';

abstract class SyncCenterState {}

class SyncCenterInitial extends SyncCenterState {}

class SyncCenterLoading extends SyncCenterState {}

class SyncCenterLoaded extends SyncCenterState {
  final List<Map<String, dynamic>> drafts;
  SyncCenterLoaded(this.drafts);
}

class SyncCenterActionSuccess extends SyncCenterState {
  final String message;
  final List<Map<String, dynamic>> drafts;
  SyncCenterActionSuccess(this.message, this.drafts);
}

class SyncCenterCubit extends Cubit<SyncCenterState> {
  final OdooRepository repository;

  SyncCenterCubit(this.repository) : super(SyncCenterInitial());

  Future<void> loadDrafts() async {
    emit(SyncCenterLoading());
    try {
      final drafts = await repository.getPendingOfflineDrafts();
      emit(SyncCenterLoaded(drafts));
    } catch (_) {
      emit(SyncCenterLoaded(const []));
    }
  }

  Future<void> forceSyncAll() async {
    emit(SyncCenterLoading());
    try {
      final int syncedCount = await repository.synchronizeOfflineQueue();
      final updatedDrafts = await repository.getPendingOfflineDrafts();
      emit(
        SyncCenterActionSuccess(
          "Successfully synchronized $syncedCount offline records to Odoo!",
          updatedDrafts,
        ),
      );
    } catch (e) {
      final currentDrafts = await repository.getPendingOfflineDrafts();
      emit(SyncCenterActionSuccess(e.toString().replaceAll("Exception: ", ""), currentDrafts));
    }
  }

  Future<void> syncMasterDatabase({bool forceFull = false}) async {
    emit(SyncCenterLoading());
    try {
      final counts = await repository.syncMasterDataToSqlite(forceFull: forceFull);
      final drafts = await repository.getPendingOfflineDrafts();
      emit(
        SyncCenterActionSuccess(
          "SQLite Updated: ${counts['customers']} Customers, ${counts['vendors']} Vendors, ${counts['products']} Products.",
          drafts,
        ),
      );
    } catch (e) {
      final drafts = await repository.getPendingOfflineDrafts();
      emit(SyncCenterActionSuccess(e.toString().replaceAll("Exception: ", ""), drafts));
    }
  }

  Future<void> removeDraft(String id) async {
    emit(SyncCenterLoading());
    try {
      await repository.deleteOfflineDraft(id);
      final updatedDrafts = await repository.getPendingOfflineDrafts();
      emit(SyncCenterActionSuccess("Offline draft discarded.", updatedDrafts));
    } catch (_) {
      final currentDrafts = await repository.getPendingOfflineDrafts();
      emit(SyncCenterActionSuccess("Failed to delete draft.", currentDrafts));
    }
  }
}
