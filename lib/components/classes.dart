
class Store {
  final String id;
  final String name;
  Store(this.id, this.name);
}

class App {
  final String id;
  final String name;
  final String appType;
  App(this.id, this.name, this.appType);
}

class Invoice {
  final String id;
  final String storeId;
  final String amount;
  final String status;
  final int createdTime;
  final String checkoutLink;
  final Map<String, dynamic> metadata;
  Invoice(
    this.id,
    this.storeId,
    this.amount,
    this.status,
    this.createdTime,
    this.checkoutLink,
    this.metadata);
}