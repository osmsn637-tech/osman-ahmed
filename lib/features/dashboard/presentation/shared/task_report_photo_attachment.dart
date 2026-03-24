import 'dart:typed_data';

class TaskReportPhotoAttachment {
  const TaskReportPhotoAttachment({
    required this.path,
    required this.bytes,
  });

  final String path;
  final Uint8List bytes;
}
