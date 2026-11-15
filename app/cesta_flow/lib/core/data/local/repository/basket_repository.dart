import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../../remote/supabase_sync_query.dart';
import '../db_helper.dart';
import '../model/basket_model.dart';
import '../model/sale_basket_model.dart';
import '../sync_entity_lookup.dart';

class BasketRepository {
  final DatabaseHelper _dbHelper;
  BasketRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerBasket(Basket value) async {
    var isSynced = true;
    try {
      await Supabase.instance.client.from('baskets').insert(value.toRemote());
    } catch (_) {
      isSynced = false;
    }
    final db = await _dbHelper.store;
    final valueAfterSync = value.copyWith(isSynced: isSynced);
    return db.runInTransaction(TxMode.write, () {
      return db.box<Basket>().put(valueAfterSync);
    });
  }

  Future<List<Basket>> getAllBaskets() async {
    final query = (await _dbHelper.store)
        .box<Basket>()
        .query(Basket_.isDeleted.equals(false))
        .order(Basket_.name)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  Future<void> pushUnsyncedBaskets() async {
    await _pushBaskets(await _dbHelper.store);
  }

  Future<void> pushUnsyncedSaleBaskets() async {
    await _pushSaleBaskets(await _dbHelper.store);
  }

  Future<void> pullBasketsSince(DateTime since) async {
    await _pullBaskets(await _dbHelper.store, since);
  }

  Future<void> pullSaleBasketsSince(DateTime since) async {
    await _pullSaleBaskets(await _dbHelper.store, since);
  }

  Future<void> _pushBaskets(Store db) async {
    final query = db.box<Basket>().query(Basket_.isSynced.equals(false)).build();
    List<Basket> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final basket in pending) {
      var synced = false;
      if (basket.uuid.isNotEmpty) {
        try {
          if (basket.isDeleted) {
            synced = await _markRemoteDeleted(basket.uuid);
          } else {
            await Supabase.instance.client
                .from('baskets')
                .upsert(basket.toRemote());
            synced = true;
          }
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<Basket>().put(basket.copyWith(isSynced: true), mode: PutMode.update);
    }
  }

  Future<void> _pushSaleBaskets(Store db) async {
    final query =
        db.box<SaleBasket>().query(SaleBasket_.isSynced.equals(false)).build();
    List<SaleBasket> pending;
    try {
      pending = query.find();
    } finally {
      query.close();
    }
    for (final link in pending) {
      var synced = false;
      if (link.saleUuid.isNotEmpty && link.basketUuid.isNotEmpty) {
        try {
          if (link.isDeleted) {
            synced = await _markRemoteSaleBasketDeleted(
              link.saleUuid,
              link.basketUuid,
            );
          } else {
            await Supabase.instance.client
                .from('sale_baskets')
                .upsert(link.toRemote());
            synced = true;
          }
        } catch (_) {
          synced = false;
        }
      }
      if (!synced) continue;
      db.box<SaleBasket>().put(
        link.copyWith(isSynced: true),
        mode: PutMode.update,
      );
    }
  }

  Future<void> _pullBaskets(Store db, DateTime since) async {
    final rows = await fetchRowsChangedSince('baskets', since);
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = Basket.fromMap(raw);
      final existing = findBasketByUuid(db, remote.uuid);
      final merged = remote.copyWith(id: existing?.id, isSynced: true);
      db.box<Basket>().put(
        merged,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
    }
  }

  Future<void> _pullSaleBaskets(Store db, DateTime since) async {
    final rows = await fetchRowsChangedSince('sale_baskets', since);
    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final remote = SaleBasket.fromMap(raw);
      if (remote.saleUuid.isEmpty || remote.basketUuid.isEmpty) continue;
      final sale = findSaleByUuid(db, remote.saleUuid);
      final basket = findBasketByUuid(db, remote.basketUuid);
      if (sale?.id == null || basket?.id == null) continue;
      final existing = findSaleBasketByUuids(
        db,
        saleUuid: remote.saleUuid,
        basketUuid: remote.basketUuid,
      );
      final merged = remote.copyWith(
        id: existing?.id,
        saleId: sale!.id!,
        basketId: basket!.id!,
        isSynced: true,
      );
      db.box<SaleBasket>().put(
        merged,
        mode: existing == null ? PutMode.put : PutMode.update,
      );
    }
  }

  Future<bool> _markRemoteDeleted(String id) async {
    if (id.isEmpty) return false;
    try {
      await Supabase.instance.client
          .from('baskets')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _markRemoteSaleBasketDeleted(
    String saleUuid,
    String basketUuid,
  ) async {
    if (saleUuid.isEmpty || basketUuid.isEmpty) return false;
    try {
      await Supabase.instance.client
          .from('sale_baskets')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('sale_id', saleUuid)
          .eq('basket_id', basketUuid);
      return true;
    } catch (_) {
      return false;
    }
  }
}
