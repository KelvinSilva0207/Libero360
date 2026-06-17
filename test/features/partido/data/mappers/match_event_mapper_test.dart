import 'package:flutter_test/flutter_test.dart';
import 'package:libero360/features/partido/data/match_event.dart';
import 'package:libero360/features/partido/data/mappers/match_event_mapper.dart';
import 'package:libero360/features/estadisticas/data/models/stat_event.dart';

void main() {
  group('MatchEvent → StatEvent', () {
    test('winnerPoint mapea a ataque + positivo', () {
      final matchEvent = MatchEvent.create(
        athleteId: 1,
        matchId: 10,
        setNumero: 2,
        eventType: EventType.winnerPoint,
        tipoPartido: 'amistoso',
        rotacion: 3,
      );

      final stat = MatchEventMapper.toStatEvent(matchEvent);

      expect(stat.tipoAccion, TipoAccion.ataque);
      expect(stat.resultado, ResultadoAccion.positivo);
      expect(stat.playerId, 1);
      expect(stat.matchId, 10);
      expect(stat.setNumero, 2);
      expect(stat.puntoLocal, 0);
      expect(stat.puntoVisitante, 0);
      expect(stat.esEquipoLocal, false);
      expect(stat.zona, ZonaCancha.ninguna);
    });

    test('regularPoint mapea a ataque + positivo', () {
      final matchEvent = MatchEvent.create(
        athleteId: 2,
        matchId: 10,
        setNumero: 1,
        eventType: EventType.regularPoint,
        tipoPartido: 'amistoso',
      );

      final stat = MatchEventMapper.toStatEvent(matchEvent);

      expect(stat.tipoAccion, TipoAccion.ataque);
      expect(stat.resultado, ResultadoAccion.positivo);
      expect(stat.playerId, 2);
    });

    test('error mapea a errorContrario + negativo', () {
      final matchEvent = MatchEvent.create(
        athleteId: 3,
        matchId: 10,
        setNumero: 3,
        eventType: EventType.error,
        tipoPartido: 'competitivo',
      );

      final stat = MatchEventMapper.toStatEvent(matchEvent);

      expect(stat.tipoAccion, TipoAccion.errorContrario);
      expect(stat.resultado, ResultadoAccion.negativo);
    });

    test('descripcion se genera desde tipoPartido y label', () {
      final matchEvent = MatchEvent.create(
        athleteId: 1,
        matchId: 10,
        setNumero: 1,
        eventType: EventType.regularPoint,
        tipoPartido: 'amistoso',
      );

      final stat = MatchEventMapper.toStatEvent(matchEvent);

      expect(stat.descripcion, contains('amistoso'));
      expect(stat.descripcion, contains('regular'));
    });
  });

  group('StatEvent → MatchEvent', () {
    test('positivo mapea a winnerPoint', () {
      final stat = StatEvent.create(
        tipoAccion: TipoAccion.ataque,
        resultado: ResultadoAccion.positivo,
        setNumero: 2,
        puntoLocal: 15,
        puntoVisitante: 10,
        esEquipoLocal: true,
        zona: ZonaCancha.ataque,
        playerId: 5,
        matchId: 20,
      );

      final matchEvent = MatchEventMapper.toMatchEvent(stat);

      expect(matchEvent.eventType, EventType.winnerPoint);
      expect(matchEvent.athleteId, 5);
      expect(matchEvent.matchId, 20);
      expect(matchEvent.setNumero, 2);
      expect(matchEvent.tipoPartido, '');
      expect(matchEvent.rotacion, 0);
    });

    test('negativo mapea a error', () {
      final stat = StatEvent.create(
        tipoAccion: TipoAccion.saque,
        resultado: ResultadoAccion.negativo,
        setNumero: 1,
        puntoLocal: 0,
        puntoVisitante: 0,
        esEquipoLocal: false,
        zona: ZonaCancha.saque,
        playerId: 7,
        matchId: 20,
      );

      final matchEvent = MatchEventMapper.toMatchEvent(stat);

      expect(matchEvent.eventType, EventType.error);
    });

    test('neutral mapea a regularPoint', () {
      final stat = StatEvent.create(
        tipoAccion: TipoAccion.defensa,
        resultado: ResultadoAccion.neutral,
        setNumero: 1,
        puntoLocal: 0,
        puntoVisitante: 0,
        esEquipoLocal: true,
        zona: ZonaCancha.defensa,
        playerId: 9,
        matchId: 20,
      );

      final matchEvent = MatchEventMapper.toMatchEvent(stat);

      expect(matchEvent.eventType, EventType.regularPoint);
    });
  });

  group('Redondeo — conversión no destructiva de ids', () {
    test('ida y vuelta conserva athleteId, matchId, setNumero', () {
      final original = MatchEvent.create(
        athleteId: 42,
        matchId: 99,
        setNumero: 3,
        eventType: EventType.regularPoint,
        tipoPartido: 'final',
        rotacion: 5,
      );

      final stat = MatchEventMapper.toStatEvent(original);
      final roundtrip = MatchEventMapper.toMatchEvent(stat);

      expect(roundtrip.athleteId, original.athleteId);
      expect(roundtrip.matchId, original.matchId);
      expect(roundtrip.setNumero, original.setNumero);
    });

    test('ida y vuelta conserva playerId, matchId, setNumero', () {
      final original = StatEvent.create(
        tipoAccion: TipoAccion.bloqueo,
        resultado: ResultadoAccion.positivo,
        setNumero: 2,
        puntoLocal: 10,
        puntoVisitante: 8,
        esEquipoLocal: true,
        zona: ZonaCancha.red,
        playerId: 15,
        matchId: 30,
      );

      final matchEvent = MatchEventMapper.toMatchEvent(original);
      final roundtrip = MatchEventMapper.toStatEvent(matchEvent);

      expect(roundtrip.playerId, original.playerId);
      expect(roundtrip.matchId, original.matchId);
      expect(roundtrip.setNumero, original.setNumero);
    });
  });
}
