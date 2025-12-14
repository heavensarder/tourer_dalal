class TransactionModel {
  final int id;
  final String type; // 'deposit' | 'expense'
  final int? refId;
  final int? memberId;
  final String title;
  final double amount;
  final String? note;
  final String dateTime; // ISO8601

  TransactionModel({
    required this.id,
    required this.type,
    this.refId,
    this.memberId,
    required this.title,
    required this.amount,
    this.note,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'refId': refId,
      'memberId': memberId,
      'title': title,
      'amount': amount,
      'note': note,
      'dateTime': dateTime,
    };
  }

    factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      refId: map['refId'],
      memberId: map['memberId'],
      title: map['title'],
      amount: map['amount'],
      note: map['note'],
      dateTime: map['dateTime'],
    );
  }
}
