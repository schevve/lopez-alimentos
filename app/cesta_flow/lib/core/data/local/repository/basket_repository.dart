import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../objectbox.g.dart';
import '../../remote/active_supabase_client.dart';
import '../../remote/supabase_sync_query.dart';
import '../db_helper.dart';
import '../model/basket_model.dart';
import '../model/sale_basket_model.dart';
import '../remote_deletion.dart';
import '../sync_timestamps.dart';
import '../sync_entity_lookup.dart';

class BasketRepository {
  final DatabaseHelper _dbHelper;
  BasketRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<int> registerBasket(Basket value) async {
    final db = await _dbHelper.store;
    final pending = value.copyWith(
      updatedAt: SyncTimestamps.forCreate(value.createdAt, value.updatedAt),
      isSynced: false,
    );
    final id = db.runInTransaction(TxMode.write, () {
      return db.box<Basket>().put(pending);
    });
    final saved = pending.copyWith(id: id);
    final client = activeSupabaseClient();
    if (client == null) return id;
    await client.from('baskets').insert(saved.toRemote());
    db.box<Basket>().put(saved.copyWith(isSynced: true), mode: PutMode.update);
    return id;
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

  Future<Basket?> getBasketById(int id) async {
    final basket = (await _dbHelper.store).box<Basket>().get(id);
    if (basket == null || basket.isDeleted) return null;
    return basket;
  }

  Future<int> updateBasket(Basket value) async {
    if (value.id == null || value.id == 0) {
      throw ArgumentError('ID obrigatório para atualizar.');
    }
    final db = await _dbHelper.store;
    final pending = value.copyWith(
      updatedAt: SyncTimestamps.forUpdate(),
      isSynced: false,
    );
    final updated = db.runInTransaction(TxMode.write, () {
      if (db.box<Basket>().get(pending.id!) == null) return 0;
      db.box<Basket>().put(pending, mode: PutMode.update);
      return 1;
    });
    if (updated == 0) return 0;
    final client = activeSupabaseClient();
    if (client == null) return 1;
    await client.from('baskets').upsert(pending.toRemote());
    db.box<Basket>().put(
      pending.copyWith(isSynced: true),
      mode: PutMode.update,
    );
    return 1;
  }

  /// `1` removida, `0` não encontrada, `-1` vinculada a vendas.
  Future<int> deleteBasket(int id) async {
    final db = await _dbHelper.store;
    final basket = db.box<Basket>().get(id);
    if (basket == null || basket.isDeleted) return 0;

    final links = db
        .box<SaleBasket>()
        .query(
          SaleBasket_.basketId
              .equals(id)
              .and(SaleBasket_.isDeleted.equals(false)),
        )
        .build();
    try {
      if (links.find().isNotEmpty) return -1;
    } finally {
      links.close();
    }

    final now = DateTime.now();
    final marked = db.runInTransaction(TxMode.write, () {
      final current = db.box<Basket>().get(id);
      if (current == null || current.isDeleted) return 0;
      db.box<Basket>().put(
        current.copyWith(isDeleted: true, isSynced: false, updatedAt: now),
        mode: PutMode.update,
      );
      return 1;
    });
    if (marked == 0) return 0;
    final client = activeSupabaseClient();
    final deleted = db.box<Basket>().get(id);
    if (client == null || deleted == null || deleted.uuid.isEmpty) return 1;
    await client
        .from('baskets')
        .update(remoteDeletionStamp(now))
        .eq('id', deleted.uuid);
    db.box<Basket>().put(
      deleted.copyWith(isSynced: true),
      mode: PutMode.update,
    );
    return 1;
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
          .update(remoteDeletionStamp(DateTime.now()))
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
          .update(remoteDeletionStamp(DateTime.now()))
          .eq('sale_id', saleUuid)
          .eq('basket_id', basketUuid);
      return true;
    } catch (_) {
      return false;
    }
  }
}
