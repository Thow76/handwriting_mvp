import 'package:flutter/foundation.dart';

enum LetterCase { lowercase, uppercase }

enum InputMode { finger, stylus }

enum Difficulty { beginner, intermediate, advanced }

enum GuidelineMode { full, baselineOnly }

class AppState extends ChangeNotifier {
  LetterCase _letterCase = LetterCase.lowercase;
  InputMode _inputMode = InputMode.finger;
  Difficulty _difficulty = Difficulty.beginner;
  GuidelineMode _guidelineMode = GuidelineMode.full;

  // Width preset index: 0 = narrowest, 1 = medium, 2 = widest
  int _widthPresetIndex = 1;

  LetterCase get letterCase => _letterCase;
  InputMode get inputMode => _inputMode;
  Difficulty get difficulty => _difficulty;
  GuidelineMode get guidelineMode => _guidelineMode;
  int get widthPresetIndex => _widthPresetIndex;

  // Finger widths: wider to accommodate less precise input
  static const List<double> fingerWidths = [5.0, 7.0, 9.0];
  // Stylus widths: finer for precision input
  static const List<double> stylusWidths = [1.5, 2.5, 3.5];

  double get currentStrokeWidth {
    final presets = _inputMode == InputMode.finger ? fingerWidths : stylusWidths;
    return presets[_widthPresetIndex];
  }

  void setLetterCase(LetterCase value) {
    if (_letterCase == value) return;
    _letterCase = value;
    notifyListeners();
  }

  void setInputMode(InputMode value) {
    if (_inputMode == value) return;
    _inputMode = value;
    notifyListeners();
  }

  void setDifficulty(Difficulty value) {
    if (_difficulty == value) return;
    _difficulty = value;
    notifyListeners();
  }

  void setGuidelineMode(GuidelineMode value) {
    if (_guidelineMode == value) return;
    _guidelineMode = value;
    notifyListeners();
  }

  void setWidthPresetIndex(int index) {
    assert(index >= 0 && index <= 2);
    if (_widthPresetIndex == index) return;
    _widthPresetIndex = index;
    notifyListeners();
  }
}
