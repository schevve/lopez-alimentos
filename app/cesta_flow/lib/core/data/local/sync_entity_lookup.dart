import '../../../objectbox.g.dart';
import 'model/basket_model.dart';
import 'model/customer_model.dart';
import 'model/installment_model.dart';
import 'model/payment_model.dart';
import 'model/sale_basket_model.dart';
import 'model/sale_model.dart';

Customer? findCustomerByUuid(Store db, String uuid) {
  if (uuid.isEmpty) return null;
  final query = db.box<Customer>().query(Customer_.uuid.equals(uuid)).build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}

Sale? findSaleByUuid(Store db, String uuid) {
  if (uuid.isEmpty) return null;
  final query = db.box<Sale>().query(Sale_.uuid.equals(uuid)).build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}

Basket? findBasketByUuid(Store db, String uuid) {
  if (uuid.isEmpty) return null;
  final query = db.box<Basket>().query(Basket_.uuid.equals(uuid)).build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}

Installment? findInstallmentByUuid(Store db, String uuid) {
  if (uuid.isEmpty) return null;
  final query = db.box<Installment>().query(Installment_.uuid.equals(uuid)).build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}

Payment? findPaymentByUuid(Store db, String uuid) {
  if (uuid.isEmpty) return null;
  final query = db.box<Payment>().query(Payment_.uuid.equals(uuid)).build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}

SaleBasket? findSaleBasketByUuids(
  Store db, {
  required String saleUuid,
  required String basketUuid,
}) {
  if (saleUuid.isEmpty || basketUuid.isEmpty) return null;
  final query = db
      .box<SaleBasket>()
      .query(
        SaleBasket_.saleUuid
            .equals(saleUuid)
            .and(SaleBasket_.basketUuid.equals(basketUuid)),
      )
      .build();
  try {
    return query.findFirst();
  } finally {
    query.close();
  }
}
