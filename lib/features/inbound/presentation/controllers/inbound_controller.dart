import 'package:flutter/foundation.dart';

import '../../domain/entities/inbound_entities.dart';
import '../../domain/repositories/inbound_repository.dart';

class InboundController extends ChangeNotifier {
  InboundController(this._repository) {
    loadDocuments();
  }

  final InboundRepository _repository;

  List<InboundDocument> _documents = [];
  bool _isLoading = false;

  List<InboundDocument> get documents => _documents;
  List<InboundDocument> get pendingDocuments => _documents.where((d) => d.isPending).toList();
  List<InboundDocument> get inProgressDocuments => _documents.where((d) => d.isInProgress).toList();
  List<InboundDocument> get completedDocuments => _documents.where((d) => d.isCompleted).toList();
  bool get isLoading => _isLoading;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _repository.getInboundDocuments();
    } catch (e) {
      // Handle error
      debugPrint('Error loading inbound documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInboundDocument(CreateInboundParams params) async {
    try {
      final document = await _repository.createInboundDocument(params);
      _documents.add(document);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating inbound document: $e');
      rethrow;
    }
  }

  Future<void> startInboundDocument(int inboundId) async {
    try {
      final updated = await _repository.startInboundDocument(inboundId);
      final index = _documents.indexWhere((d) => d.id == inboundId);
      if (index != -1) {
        _documents[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting inbound document: $e');
      rethrow;
    }
  }

  Future<void> receiveInboundItem(ReceiveInboundItemParams params) async {
    try {
      final updated = await _repository.receiveInboundItem(params);
      final index = _documents.indexWhere((d) => d.id == params.inboundId);
      if (index != -1) {
        _documents[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error receiving inbound item: $e');
      rethrow;
    }
  }

  Future<void> completeInboundDocument(int inboundId) async {
    try {
      final updated = await _repository.completeInboundDocument(inboundId);
      final index = _documents.indexWhere((d) => d.id == inboundId);
      if (index != -1) {
        _documents[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error completing inbound document: $e');
      rethrow;
    }
  }
}
