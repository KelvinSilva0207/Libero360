/// Módulo de Estadísticas Play-by-Play
/// 
/// Flujo completo:
/// 1. Seleccionar jugador
/// 2. Registrar acción
/// 3. Guardar en Isar
/// 4. UI se actualiza automáticamente
/// 5. Mostrar estadísticas

// ==================== DATA ====================
// Models
export 'data/models/models.dart';

// Database
export 'data/local_db/database_service.dart';
export 'data/local_db/stats_stream_service.dart';

// Repositories
export 'data/repositories/match_repository.dart';
export 'data/repositories/stat_event_repository.dart';

// ==================== DOMAIN ====================
// Services
export 'domain/services/stats_calculator.dart';
export 'domain/services/mvp_calculator.dart';

// ==================== PRESENTATION ====================
// ViewModels
export 'presentation/viewmodels/play_by_play_viewmodel.dart';

// Screens
export 'presentation/views/play_by_play_screen.dart';

// Widgets
export 'presentation/widgets/stat_recorder_widget.dart';
export 'presentation/widgets/live_stats_widget.dart';
