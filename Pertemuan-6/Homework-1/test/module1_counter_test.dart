// test/counter_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_079/counter_controller.dart';

void main() {
  var actual, expected;

  group('Module 1 - CounterController (step & history)', () {
    late CounterController controller;

    setUp(() {
      // (1) setup (arrange, build)
      controller = CounterController();
    });

    // ── TC01 ─────────────────────────────────────────────────────────────────
    test('TC01 - initial value should be 0', () {
      // (2) exercise (act, operate)
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC02 ─────────────────────────────────────────────────────────────────
    test('TC02 - setStep should change step value', () {
      // (2) exercise (act, operate)
      controller.setStep(5);
      actual = controller.step;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC03 ─────────────────────────────────────────────────────────────────
    test('TC03 - setStep should ignore negative value', () {
      // (1) setup (arrange, build)
      controller.setStep(3);

      // (2) exercise (act, operate)
      controller.setStep(-1);
      actual = controller.step;
      expected = 3;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC04 ─────────────────────────────────────────────────────────────────
    test('TC04 - increment should increase counter based on step', () {
      // (1) setup (arrange, build)
      controller.setStep(2);

      // (2) exercise (act, operate)
      controller.increment();
      actual = controller.value;
      expected = 2;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC05 ─────────────────────────────────────────────────────────────────
    test('TC05 - decrement should decrease counter when counter >= step', () {
      // (1) setup (arrange, build)
      controller.setStep(2);
      controller.increment(); // counter = 2

      // (2) exercise (act, operate)
      controller.decrement();
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC06 ─────────────────────────────────────────────────────────────────
    test('TC06 - decrement should not go below zero when counter < step', () {
      // (1) setup (arrange, build)
      controller.setStep(5);
      // counter masih 0

      // (2) exercise (act, operate)
      controller.decrement();
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC07 ─────────────────────────────────────────────────────────────────
    test('TC07 - reset should set counter to zero', () {
      // (1) setup (arrange, build)
      controller.setStep(1);
      controller.increment(); // counter = 1

      // (2) exercise (act, operate)
      controller.reset();
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC08 ─────────────────────────────────────────────────────────────────
    test('TC08 - history should record actions', () {
      // (1) setup (arrange, build)
      controller.setStep(1);

      // (2) exercise (act, operate)
      controller.increment();
      var actual1 = controller.history.isNotEmpty;
      var expected1 = true;
      var actual2 = controller.history.first.contains('menambah');
      var expected2 = true;

      // (3) verify (assert, check)
      expect(actual1, expected1, reason: 'Expected history tidak kosong');
      expect(
        actual2,
        expected2,
        reason: 'Expected history mencatat pesan increment',
      );
    });

    // ── TC09 ─────────────────────────────────────────────────────────────────
    test('TC09 - history should not exceed 5 items', () {
      // (1) setup (arrange, build)
      controller.setStep(1);

      // (2) exercise (act, operate)
      for (int i = 0; i < 6; i++) {
        controller.increment();
      }
      actual = controller.history.length;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // ── TC10 ─────────────────────────────────────────────────────────────────
    test('TC10 - setStep should ignore zero value', () {
      // (1) setup (arrange, build)
      controller.setStep(3);

      // (2) exercise (act, operate)
      controller.setStep(0); // 0 bukan > 0, seharusnya diabaikan
      actual = controller.step;
      expected = 3;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });
  });
}
