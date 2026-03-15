import 'package:flutter_test/flutter_test.dart';
import 'package:putaway_app/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:putaway_app/features/dashboard/data/datasources/task_remote_data_source.dart';
import 'package:putaway_app/features/dashboard/data/repositories/task_repository_impl.dart';
import 'package:putaway_app/features/dashboard/domain/entities/adjustment_task_entities.dart';
import 'package:putaway_app/features/dashboard/domain/entities/ai_alert_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/exception_entity.dart';
import 'package:putaway_app/features/dashboard/domain/entities/task_entity.dart';

void main() {
  test('parses unified putaway tasks as receive while keeping worker task type', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'id': 'putaway-uuid-1',
              'task_type': 'putaway',
              'title': 'Widget Green',
              'subtitle': 'Z02-BLK-C01-L01-P01',
              'status': 'pending',
              'priority': 'high',
              'detail': {
                'item_id': 777,
                'product_name': 'Widget Green',
                'product_barcode': 'PUT-777',
                'quantity': 2,
                'to_location': 'Z02-BLK-C01-L01-P01',
                'location_id': 'loc-uuid-z02',
                'product_image': 'http://img.qeu.app/products/widget-green.jpg',
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z02');
    final task = tasks.single;

    expect(task.id, lessThan(0));
    expect(task.remoteTaskId, 'putaway-uuid-1');
    expect(task.apiTaskType, 'putaway');
    expect(task.type, TaskType.receive);
    expect(task.itemId, 777);
    expect(task.itemName, 'Widget Green');
    expect(task.itemBarcode, 'PUT-777');
    expect(task.itemImageUrl, 'https://img.qeu.app/products/widget-green.jpg');
    expect(task.toLocation, 'Z02-BLK-C01-L01-P01');
    expect(task.toLocationId, 'loc-uuid-z02');
    expect(task.priority, TaskPriority.high);
    expect(task.status, TaskStatus.pending);
  });

  test('parses unified tasks when quantity is only present at the root level', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'id': 'putaway-root-qty-1',
              'task_type': 'putaway',
              'title': 'Root Quantity Widget',
              'subtitle': 'Z02-BLK-C01-L01-P01',
              'status': 'pending',
              'quantity': 9,
              'detail': {
                'item_id': 778,
                'product_name': 'Root Quantity Widget',
                'product_barcode': 'PUT-778',
                'to_location': 'Z02-BLK-C01-L01-P01',
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z02');
    final task = tasks.single;

    expect(task.itemName, 'Root Quantity Widget');
    expect(task.quantity, 9);
  });

  test('uses product_name when parsing task item name from my-tasks response', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'taskId': 1001,
              'product_name': 'Widget Blue',
              'to_location': 'Z01',
              'item_id': 501,
              'receipt_number': 'ABC-1',
              'quantity': 5,
              'status': 'pending',
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z01');
    final task = tasks.single;

    expect(task.id, 1001);
    expect(task.itemId, 501);
    expect(task.itemName, 'Widget Blue');
    expect(task.itemBarcode, 'ABC-1');
    expect(task.toLocation, 'Z01');
    expect(task.status, TaskStatus.pending);
  });

  test('maps legacy putaway tasks to receive and normalizes product image urls', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'taskId': 1002,
              'task_type': 'putaway',
              'to_location': 'Z02',
              'item_id': 777,
              'quantity': 2,
              'status': 'assigned',
              'product': {
                'product_name': 'Widget Green',
                'product_image': 'http://img.qeu.app/products/widget-green.jpg',
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z02');
    final task = tasks.single;

    expect(task.type, TaskType.receive);
    expect(task.itemImageUrl, 'https://img.qeu.app/products/widget-green.jpg');
    expect(task.status, TaskStatus.pending);
  });

  test('prefers product_barcode over legacy barcode fields when parsing tasks', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'taskId': 1003,
              'task_type': 'putaway',
              'to_location': 'Z03-BLK-C01-L01-P01',
              'item_id': 888,
              'quantity': 1,
              'status': 'assigned',
              'receipt_number': 'LEGACY-RECEIPT',
              'barcode': 'LEGACY-BARCODE',
              'product_barcode': 'API-PRODUCT-BARCODE',
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z03');
    final task = tasks.single;

    expect(task.type, TaskType.receive);
    expect(task.itemBarcode, 'API-PRODUCT-BARCODE');
  });

  test('claims a cached pending task even if a later my-tasks fetch does not include it', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource.sequence([
      const {
        'tasks': [
          {
            'id': 'putaway-uuid-1004',
            'task_type': 'putaway',
            'title': 'Cache Me',
            'subtitle': 'Z04-BLK-C01-L01-P01',
            'status': 'pending',
            'detail': {
              'item_id': 999,
              'product_name': 'Cache Me',
              'product_barcode': 'CACHE-999',
              'quantity': 3,
              'to_location': 'Z04-BLK-C01-L01-P01',
            },
          },
        ],
      },
      const {'tasks': []},
    ]);
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final tasks = await repository.getTasksForZone('Z04');
    expect(tasks.single.status, TaskStatus.pending);
    expect(tasks.single.assignedTo, isNull);
    expect(tasks.single.remoteTaskId, 'putaway-uuid-1004');

    final claimed = await repository.claimTask(
      taskId: tasks.single.id,
      workerId: 'worker-42',
    );

    expect(claimed.remoteTaskId, 'putaway-uuid-1004');
    expect(claimed.apiTaskType, 'putaway');
    expect(claimed.assignedTo, 'worker-42');
    expect(claimed.status, TaskStatus.inProgress);
    expect(remoteDataSource.startedTaskId, 'putaway-uuid-1004');
    expect(remoteDataSource.startedTaskType, 'putaway');
  });

  test('reuses the same local id for repeated refreshes when remote tasks omit taskId', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource.sequence([
        const {
          'tasks': [
            {
              'task_type': 'putaway',
              'to_location': 'Z05-BLK-C01-L01-P01',
              'from_location': 'INBOUND',
              'item_id': 7001,
              'product_name': 'No Id Task',
              'product_barcode': 'NO-ID-123',
              'quantity': 4,
              'status': 'pending',
            },
          ],
        },
        const {
          'tasks': [
            {
              'task_type': 'putaway',
              'to_location': 'Z05-BLK-C01-L01-P01',
              'from_location': 'INBOUND',
              'item_id': 7001,
              'product_name': 'No Id Task',
              'product_barcode': 'NO-ID-123',
              'quantity': 4,
              'status': 'pending',
            },
          ],
        },
      ]),
    );

    final firstLoad = await repository.getTasksForZone('Z05');
    final secondLoad = await repository.getTasksForZone('Z05');

    expect(firstLoad, hasLength(1));
    expect(secondLoad, hasLength(1));
    expect(secondLoad.single.id, firstLoad.single.id);
    expect(secondLoad.single.itemBarcode, 'NO-ID-123');
  });

  test('scans unified worker tasks using the remote task id and task type', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'receiving-uuid-1',
            'task_type': 'receiving',
            'title': 'Receipt 1',
            'subtitle': 'Inbound',
            'status': 'pending',
            'detail': {
              'item_id': 501,
              'product_name': 'Widget Blue',
              'product_barcode': 'ABC-1',
              'quantity': 5,
              'from_location': 'Inbound',
              'to_location': 'Z01-BLK-C01-L01-P01',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final task = (await repository.getTasksForZone('Z01')).single;
    final response = await repository.validateTaskLocation(
      taskId: task.id,
      barcode: 'ABC-1',
    );

    expect(response['valid'], true);
    expect(remoteDataSource.scannedTaskId, 'receiving-uuid-1');
    expect(remoteDataSource.scannedTaskType, 'receiving');
    expect(remoteDataSource.scannedBarcode, 'ABC-1');
  });

  test('submits putaway completion with worker task location id payload', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'putaway-uuid-2',
            'task_type': 'putaway',
            'title': 'Move Widget',
            'subtitle': 'Z06-BLK-C01-L01-P01',
            'status': 'started',
            'detail': {
              'item_id': 808,
              'product_name': 'Move Widget',
              'product_barcode': 'MOVE-808',
              'quantity': 7,
              'to_location': 'Z06-BLK-C01-L01-P01',
              'location_id': 'loc-uuid-22',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final task = (await repository.getTasksForZone('Z06')).single;
    expect(task.type, TaskType.receive);
    expect(task.apiTaskType, 'putaway');
    final completed = await repository.completeTask(
      task.id,
      quantity: 4,
    );

    expect(completed.status, TaskStatus.completed);
    expect(remoteDataSource.submittedTaskId, 'putaway-uuid-2');
    expect(remoteDataSource.submittedTaskType, 'putaway');
    expect(remoteDataSource.submittedQuantity, 4);
    expect(remoteDataSource.submittedLocationId, 'loc-uuid-22');
    expect(remoteDataSource.submittedTargetLocationCode, isNull);
    expect(remoteDataSource.completedTaskId, isNull);
  });

  test('completes receiving tasks with the complete endpoint', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'receiving-uuid-2',
            'task_type': 'receiving',
            'title': 'Receipt 2',
            'subtitle': 'Inbound',
            'status': 'started',
            'detail': {
              'item_id': 909,
              'product_name': 'Receive Widget',
              'product_barcode': 'REC-909',
              'quantity': 9,
              'to_location': 'Z07-BLK-C01-L01-P01',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final task = (await repository.getTasksForZone('Z07')).single;
    final completed = await repository.completeTask(task.id);

    expect(completed.status, TaskStatus.completed);
    expect(remoteDataSource.completedTaskId, 'receiving-uuid-2');
    expect(remoteDataSource.completedTaskType, 'receiving');
    expect(remoteDataSource.submittedTaskId, isNull);
  });

  test('parses unified restock tasks with refill barcode and locations', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'id': 'restock-uuid-1',
              'task_type': 'restock',
              'title': 'Refill Widget',
              'subtitle': 'Aisle 3',
              'status': 'pending',
              'detail': {
                'item_id': 333,
                'item_name': 'Refill Widget',
                'item_barcode': 'RESTOCK-333',
                'quantity': 6,
                'bulk_location': 'BULK-01-01',
                'target_location_code': 'SHELF-01-01',
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('');
    final task = tasks.single;

    expect(task.apiTaskType, 'restock');
    expect(task.type, TaskType.refill);
    expect(task.itemBarcode, 'RESTOCK-333');
    expect(task.fromLocation, 'BULK-01-01');
    expect(task.toLocation, 'SHELF-01-01');
  });

  test('keeps mixed worker task types visible when subtitle is not a zone', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'id': 'putaway-queue-1',
              'task_type': 'putaway',
              'title': 'Putaway Widget',
              'subtitle': 'Z01-BLK-C01-L01-P01',
              'status': 'pending',
              'detail': {
                'item_id': 1101,
                'product_name': 'Putaway Widget',
                'product_barcode': 'PUT-1101',
                'quantity': 2,
                'to_location': 'Z01-BLK-C01-L01-P01',
              },
            },
            {
              'id': 'restock-queue-1',
              'task_type': 'restock',
              'title': 'Refill Cereal',
              'subtitle': 'Aisle 3',
              'status': 'pending',
              'detail': {
                'item_id': 1102,
                'item_name': 'Refill Cereal',
                'item_barcode': 'REFILL-1102',
                'quantity': 4,
              },
            },
            {
              'id': 'return-queue-1',
              'task_type': 'return',
              'title': 'Return Tote RT-204',
              'subtitle': 'RT-204',
              'status': 'pending',
              'detail': {
                'item_id': 1103,
                'item_name': 'Return Tote RT-204',
                'item_barcode': 'RETURN-1103',
                'quantity': 1,
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z01');

    expect(tasks, hasLength(3));
    expect(tasks.map((task) => task.type), containsAll(<TaskType>[
      TaskType.receive,
      TaskType.refill,
      TaskType.returnTask,
    ]));
  });

  test('returns only api tasks for the requested zone', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'id': 'putaway-uuid-3',
              'task_type': 'putaway',
              'title': 'Remote Widget',
              'subtitle': 'Z03-BLK-C01-L01-P01',
              'status': 'pending',
              'detail': {
                'item_id': 1200,
                'product_name': 'Remote Widget',
                'product_barcode': 'REMOTE-1200',
                'quantity': 2,
                'to_location': 'Z03-BLK-C01-L01-P01',
              },
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z03');

    expect(tasks, hasLength(1));
    expect(tasks.any((task) => task.itemName == 'Remote Widget'), isTrue);
    expect(tasks.any((task) => task.itemName == 'Return Tote RT-204'), isFalse);
    expect(tasks.any((task) => task.type == TaskType.cycleCount), isFalse);
  });

  test('returns an empty worker queue when the api response is empty', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource(const {'tasks': []});
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final tasks = await repository.getTasksForZone('Z03');

    expect(tasks, isEmpty);
    expect(remoteDataSource.startedTaskId, isNull);
    expect(remoteDataSource.scannedTaskId, isNull);
    expect(remoteDataSource.submittedTaskId, isNull);
    expect(remoteDataSource.completedTaskId, isNull);
  });

  test('save cycle count progress persists for api-backed cycle count tasks', () async {
    final remoteDataSource = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'cycle-uuid-1',
            'task_type': 'cycle_count',
            'title': 'Full Shelf Count - SHELF-03-03',
            'subtitle': 'SHELF-03-03',
            'status': 'pending',
            'detail': {
              'item_id': 9305,
              'product_name': 'Full Shelf Count - SHELF-03-03',
              'quantity': 2,
              'location_code': 'SHELF-03-03',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remoteDataSource,
    );

    final tasks = await repository.getTasksForZone('Z03');
    final cycleTask = tasks.single;

    await repository.saveCycleCountProgress(
      cycleTask.id,
      progress: const <String, Object?>{
        'items': [
          {
            'key': 'SKU-001',
            'itemName': 'Blue Mug',
            'barcode': 'SKU-001',
            'countedQuantity': 5,
            'completed': true,
          },
        ],
        'location': 'SHELF-03-03',
        'locationValidated': true,
      },
    );

    final reloaded = await repository.getTasksForZone('Z03');
    final updated = reloaded.firstWhere((task) => task.id == cycleTask.id);

    expect(updated.cycleCountProgressItems, hasLength(1));
    expect(updated.cycleCountProgressItems.single.key, 'SKU-001');
    expect(updated.cycleCountProgressItems.single.countedQuantity, 5);
    expect(updated.workflowData['cycleCountProgress'], isA<Map>());
    expect(remoteDataSource.completedTaskId, isNull);
  });

  test('parses cycle count products and hides zero quantity items', () async {
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      _FakeTaskRemoteDataSource(
        const {
          'tasks': [
            {
              'task_type': 'cycle_count',
              'id': '019ceab5-b844-72c9-9759-87acf9ba8959',
              'title': 'ADJ-71A5009D',
              'subtitle': 'cycle_count',
              'status': 'draft',
              'priority': 'medium',
              'product_name': 'Primary Product',
              'product_image': 'http://img.qeu.app/products/5000396014822/5000396014822_image.webp',
              'product_barcode': '5000396014822',
              'products': [
                {
                  'product_id': '1802',
                  'name': 'Primary Product',
                  'image': 'http://img.qeu.app/products/5000396014822/5000396014822_image.webp',
                  'barcode': '5000396014822',
                  'quantity': 21,
                },
                {
                  'product_id': '1795',
                  'name': 'Kolon Portable Vacuum Cleaner',
                  'image': 'http://img.qeu.app/products/6285353007744/6285353007744_image.webp',
                  'barcode': '6285353007744',
                  'quantity': 37,
                },
                {
                  'product_id': '154',
                  'name': 'Natural White Vinegar Bottles',
                  'image': 'http://img.qeu.app/products/6281100021018/6281100021018_image.webp',
                  'barcode': '6281100021018',
                  'quantity': 0,
                },
                {
                  'product_id': '1987',
                  'name': 'Danette Vanilla Delight',
                  'image': 'http://img.qeu.app/products/6281022107289/6281022107289_image.webp',
                  'barcode': '6281022107289',
                  'quantity': 0,
                },
              ],
              'item_count': 4,
            },
          ],
        },
      ),
    );

    final tasks = await repository.getTasksForZone('Z09');
    final task = tasks.single;

    expect(task.type, TaskType.cycleCount);
    expect(task.itemBarcode, '5000396014822');
    expect(task.itemImageUrl, 'https://img.qeu.app/products/5000396014822/5000396014822_image.webp');
    expect(task.toLocation, isNull);
    expect(task.zone, isEmpty);
    expect(task.cycleCountItems, hasLength(2));
    expect(
      task.cycleCountItems.map((item) => item.barcode).toList(),
      containsAll(<String>['5000396014822', '6285353007744']),
    );
    expect(
      task.cycleCountItems.any((item) => item.barcode == '6281100021018'),
      isFalse,
    );
    expect(
      task.cycleCountItems.any((item) => item.barcode == '6281022107289'),
      isFalse,
    );
  });

  test('scanAdjustmentLocation uses adjustment endpoint and parses products', () async {
    final remote = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'adjustment-1',
            'task_type': 'adjustment',
            'title': 'Adjustment Task',
            'subtitle': 'Z01-A01',
            'status': 'in_progress',
            'detail': {
              'item_id': 501,
              'product_name': 'Blue Mug',
              'quantity': 1,
              'to_location': 'Z01-A01',
            },
          },
        ],
      },
    )
      ..adjustmentScanResponse = const {
        'locationId': 'loc-77',
        'locationCode': 'Z01-A01',
        'products': [
          {
            'itemId': 'adj-item-1',
            'productId': 'prod-1',
            'productName': 'Blue Mug',
            'productImage': 'https://example.com/blue-mug.png',
            'systemQuantity': 10,
            'counted': false,
          },
        ],
      };
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remote,
    );

    final tasks = await repository.getTasksForZone('Z01');
    final result = await repository.scanAdjustmentLocation(
      taskId: tasks.single.id,
      barcode: 'Z01-A01',
    );

    expect(remote.adjustmentScanTaskId, 'adjustment-1');
    expect(remote.adjustmentScanBarcode, 'Z01-A01');
    expect(result.locationCode, 'Z01-A01');
    expect(
      result.products,
      [
        const AdjustmentTaskProduct(
          adjustmentItemId: 'adj-item-1',
          productId: 'prod-1',
          productName: 'Blue Mug',
          productImage: 'https://example.com/blue-mug.png',
          systemQuantity: 10,
          counted: false,
        ),
      ],
    );
  });

  test('submitAdjustmentCount sends actualQuantity and notes', () async {
    final remote = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'adjustment-2',
            'task_type': 'adjustment',
            'title': 'Adjustment Task',
            'subtitle': 'Z01-A01',
            'status': 'in_progress',
            'detail': {
              'item_id': 501,
              'product_name': 'Blue Mug',
              'quantity': 1,
              'to_location': 'Z01-A01',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remote,
    );

    final tasks = await repository.getTasksForZone('Z01');
    await repository.submitAdjustmentCount(
      taskId: tasks.single.id,
      adjustmentItemId: 'adj-item-2',
      actualQuantity: 7,
      notes: 'damaged box',
    );

    expect(remote.submittedAdjustmentItemId, 'adj-item-2');
    expect(remote.submittedActualQuantity, 7);
    expect(remote.submittedAdjustmentNotes, 'damaged box');
  });

  test('completeTask finishes adjustment tasks through adjustment finish endpoint', () async {
    final remote = _FakeTaskRemoteDataSource(
      const {
        'tasks': [
          {
            'id': 'adjustment-3',
            'task_type': 'adjustment',
            'title': 'Adjustment Task',
            'subtitle': 'Z01-A01',
            'status': 'in_progress',
            'detail': {
              'item_id': 501,
              'product_name': 'Blue Mug',
              'quantity': 1,
              'to_location': 'Z01-A01',
            },
          },
        ],
      },
    );
    final repository = TaskRepositoryImpl(
      _FakeDashboardRemoteDataSource(),
      remote,
    );

    final tasks = await repository.getTasksForZone('Z01');
    await repository.completeTask(tasks.single.id);

    expect(remote.finishedAdjustmentTaskId, 'adjustment-3');
    expect(remote.completedTaskId, isNull);
  });
}

class _FakeTaskRemoteDataSource implements TaskRemoteDataSource {
  _FakeTaskRemoteDataSource(this._response) : _responses = null;
  _FakeTaskRemoteDataSource.sequence(List<Map<String, dynamic>> responses)
      : _response = const {},
        _responses = List<Map<String, dynamic>>.from(responses);

  final Map<String, dynamic> _response;
  final List<Map<String, dynamic>>? _responses;
  String? startedTaskId;
  String? startedTaskType;
  String? scannedTaskId;
  String? scannedTaskType;
  String? scannedBarcode;
  String? adjustmentScanTaskId;
  String? adjustmentScanBarcode;
  String? submittedTaskId;
  String? submittedTaskType;
  int? submittedQuantity;
  String? submittedLocationId;
  String? submittedTargetLocationCode;
  String? submittedAdjustmentItemId;
  int? submittedActualQuantity;
  String? submittedAdjustmentNotes;
  String? finishedAdjustmentTaskId;
  String? completedTaskId;
  String? completedTaskType;
  Map<String, dynamic> adjustmentScanResponse = const {
    'locationId': 'loc-1',
    'locationCode': 'LOC-01',
    'products': [],
  };

  @override
  Future<Map<String, dynamic>> fetchMyTasks({
    String? taskType,
    String? cursor,
    int limit = 100,
  }) async {
    if (_responses case final responses?) {
      if (responses.isEmpty) return const {'tasks': []};
      return responses.removeAt(0);
    }
    return _response;
  }

  @override
  Future<Map<String, dynamic>> startTask({
    required String taskId,
    required String taskType,
  }) async {
    startedTaskId = taskId;
    startedTaskType = taskType;
    return {'ok': true};
  }

  @override
  Future<void> skipTask({
    required String taskId,
    required String taskType,
    String? reason,
  }) async {
    throw UnsupportedError('skipTask is not implemented in fake');
  }

  @override
  Future<Map<String, dynamic>> submitTask({
    required String taskId,
    required String taskType,
    int? quantity,
    required String locationId,
    String? targetLocationCode,
  }) async {
    submittedTaskId = taskId;
    submittedTaskType = taskType;
    submittedQuantity = quantity;
    submittedLocationId = locationId;
    submittedTargetLocationCode = targetLocationCode;
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> getTaskDetail({
    required String taskId,
    required String taskType,
  }) async {
    throw UnsupportedError('getTaskDetail is not implemented in fake');
  }

  @override
  Future<Map<String, dynamic>> scanTask({
    required String taskId,
    required String taskType,
    required String barcode,
  }) async {
    scannedTaskId = taskId;
    scannedTaskType = taskType;
    scannedBarcode = barcode;
    return {'valid': true};
  }

  @override
  Future<Map<String, dynamic>> scanAdjustmentLocation({
    required String adjustmentId,
    required String barcode,
  }) async {
    adjustmentScanTaskId = adjustmentId;
    adjustmentScanBarcode = barcode;
    return adjustmentScanResponse;
  }

  @override
  Future<void> submitAdjustmentCount({
    required String adjustmentItemId,
    required int actualQuantity,
    String? notes,
  }) async {
    submittedAdjustmentItemId = adjustmentItemId;
    submittedActualQuantity = actualQuantity;
    submittedAdjustmentNotes = notes;
  }

  @override
  Future<void> finishAdjustment({
    required String adjustmentId,
  }) async {
    finishedAdjustmentTaskId = adjustmentId;
  }

  @override
  Future<Map<String, dynamic>> completeTask({
    required String taskId,
    required String taskType,
  }) async {
    completedTaskId = taskId;
    completedTaskType = taskType;
    return {'ok': true};
  }
}

class _FakeDashboardRemoteDataSource implements DashboardRemoteDataSource {
  @override
  Future<DashboardSummaryEntity> fetchSummary() {
    throw UnsupportedError('fetchSummary is not implemented in fake');
  }

  @override
  Future<List<ExceptionEntity>> fetchExceptions() {
    throw UnsupportedError('fetchExceptions is not implemented in fake');
  }

  @override
  Future<List<AiAlertEntity>> fetchAiAlerts() {
    throw UnsupportedError('fetchAiAlerts is not implemented in fake');
  }

  @override
  Future<void> resolveException({required int id, required String action}) async {
    throw UnsupportedError('resolveException is not implemented in fake');
  }
}
