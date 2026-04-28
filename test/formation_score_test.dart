import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/formation_score.dart';

void main() {
  group('StrokeObservation', () {
    test('stores all fields correctly', () {
      const obs = StrokeObservation(
        strokeIndex: 0,
        expected: 'top',
        observed: 'bottomRight',
        score: 0.0,
        note: 'Started at the bottom-right; should start at the top.',
      );

      expect(obs.strokeIndex, 0);
      expect(obs.expected, 'top');
      expect(obs.observed, 'bottomRight');
      expect(obs.score, 0.0);
      expect(obs.note, 'Started at the bottom-right; should start at the top.');
    });

    test('accepts a waypoint sequence string in expected and observed', () {
      const obs = StrokeObservation(
        strokeIndex: 1,
        expected: 'top → bottomLeft → top',
        observed: 'top → bottom → top',
        score: 0.5,
        note: 'Second waypoint was slightly off.',
      );

      expect(obs.expected, 'top → bottomLeft → top');
      expect(obs.observed, 'top → bottom → top');
      expect(obs.score, 0.5);
    });

    test('is const-constructible', () {
      const obs = StrokeObservation(
        strokeIndex: 2,
        expected: 'leftToRight',
        observed: 'leftToRight',
        score: 1.0,
        note: 'Correct direction.',
      );

      expect(obs.strokeIndex, 2);
      expect(obs.score, 1.0);
    });
  });

  group('FormationScore', () {
    test('stores all fields correctly', () {
      const obs = StrokeObservation(
        strokeIndex: 0,
        expected: 'top',
        observed: 'top',
        score: 1.0,
        note: 'Started in the top region — correct.',
      );

      const result = FormationScore(
        overallScore: 1.0,
        observations: [obs],
        summary: 'All strokes started in the right place.',
      );

      expect(result.overallScore, 1.0);
      expect(result.observations, [obs]);
      expect(result.summary, 'All strokes started in the right place.');
    });

    test('accepts an empty observations list', () {
      const result = FormationScore(
        overallScore: 0.0,
        observations: [],
        summary: 'No strokes were examined.',
      );

      expect(result.observations, isEmpty);
      expect(result.overallScore, 0.0);
    });

    test('accepts multiple observations', () {
      const obs0 = StrokeObservation(
        strokeIndex: 0,
        expected: 'top',
        observed: 'top',
        score: 1.0,
        note: 'Correct.',
      );
      const obs1 = StrokeObservation(
        strokeIndex: 1,
        expected: 'top',
        observed: 'middle',
        score: 0.0,
        note: 'Started too low.',
      );

      const result = FormationScore(
        overallScore: 0.5,
        observations: [obs0, obs1],
        summary: 'One stroke started correctly, one did not.',
      );

      expect(result.observations.length, 2);
      expect(result.observations[0].strokeIndex, 0);
      expect(result.observations[1].strokeIndex, 1);
      expect(result.overallScore, 0.5);
    });

    test('is const-constructible', () {
      const result = FormationScore(
        overallScore: 0.75,
        observations: [],
        summary: 'Most strokes were correct.',
      );

      expect(result.overallScore, 0.75);
    });
  });
}
