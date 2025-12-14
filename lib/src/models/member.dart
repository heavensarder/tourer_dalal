class Member {
  final int id;
  final String name;
  final double initialContributionPerRound;
  final double totalPaid;
  final String createdAt; // ISO8601

  Member({
    required this.id,
    required this.name,
    required this.initialContributionPerRound,
    required this.totalPaid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialContributionPerRound': initialContributionPerRound,
      'totalPaid': totalPaid,
      'createdAt': createdAt,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      initialContributionPerRound: map['initialContributionPerRound'],
      totalPaid: map['totalPaid'],
      createdAt: map['createdAt'],
    );
  }
}
