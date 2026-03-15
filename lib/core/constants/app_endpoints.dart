class AppEndpoints {
  AppEndpoints._();

  static const qeuMobileLogin = 'https://api.qeu.app/v1/inventory/login';
  static const login = qeuMobileLogin;
  static const refresh = '/auth/refresh';

  static const receiveItems = '/inventory/receive';
  static const moveItems = '/inventory/move';
  static const itemsByLocation = '/inventory/locations';
  static const cycleCount = '/inventory/cycle-count';
  static const items = '/inventory/items';
  static const workerTasks = '/mobile/v1/worker/tasks';
  static String workerTaskDetail(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId';
  static String workerTaskStart(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/start';
  static String workerTaskScan(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/scan';
  static String workerTaskSubmit(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/submit';
  static String workerTaskProgress(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/progress';
  static String workerTaskComplete(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/complete';
  static String workerTaskSkip(String taskId) =>
      '/mobile/v1/worker/tasks/$taskId/skip';
  static String adjustmentScanLocation(String adjustmentId) =>
      '/mobile/v1/adjustments/$adjustmentId/scan-location';
  static String adjustmentItemCount(String adjustmentItemId) =>
      '/mobile/v1/adjustment-items/$adjustmentItemId/count';
  static String adjustmentFinish(String adjustmentId) =>
      '/mobile/v1/adjustments/$adjustmentId/finish';
  static String lookupProductByBarcode(String barcode) =>
      'https://api.qeu.app/mobile/v1/products/barcode/${Uri.encodeComponent(barcode)}';
  static String itemStock(String barcode) => '/inventory/items/$barcode/stock';
  static String locationItems(int locationId) => '/inventory/locations/$locationId/items';
}
