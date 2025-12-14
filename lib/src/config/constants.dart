class Routes {
  static const String dashboard = '/';
  static const String members = '/members';
  static const String addMember = '/members/add';
  static const String memberDetail = '/members/detail';
  static const String batchAdd = '/members/batch_add';
  static const String addExpense = '/expense/add';
  static const String transactions = '/transactions';
  static const String pdfReport = '/report/pdf';
  static const String settings = '/settings';
  static const String splash = '/splash'; // New route
}

class AppSettingsKeys {
  static const String currencySymbol = 'currencySymbol';
  static const String lowBalanceThreshold = 'lowBalanceThreshold';
  static const String allowDeletingTransactions = 'allowDeletingTransactions';
  static const String isFirstRun = 'isFirstRun'; // New key
}
