enum SyncOperationType { upload, delete }

class PendingSyncOperation {
  final int id;
  final SyncOperationType type;
  final String collection; // matches, athletes, attendance, stats, profiles
  final String documentId; // local DB id as string
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final String? errorMessage;

  const PendingSyncOperation({
    this.id = 0,
    required this.type,
    required this.collection,
    required this.documentId,
    this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.errorMessage,
  }) : createdAt = createdAt ?? DateTime.now();

  PendingSyncOperation copyWith({
    int? id,
    SyncOperationType? type,
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? errorMessage,
  }) =>
      PendingSyncOperation(
        id: id ?? this.id,
        type: type ?? this.type,
        collection: collection ?? this.collection,
        documentId: documentId ?? this.documentId,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'errorMessage': errorMessage,
      };

  factory PendingSyncOperation.fromMap(int id, Map<String, dynamic> map) =>
      PendingSyncOperation(
        id: id,
        type: SyncOperationType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => SyncOperationType.upload,
        ),
        collection: map['collection'] as String? ?? '',
        documentId: map['documentId'] as String? ?? '',
        data: map['data'] as Map<String, dynamic>?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
        retryCount: map['retryCount'] as int? ?? 0,
        errorMessage: map['errorMessage'] as String?,
      );
}
