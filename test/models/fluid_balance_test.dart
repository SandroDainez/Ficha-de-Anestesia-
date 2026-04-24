import 'package:anestesia_app/models/fluid_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates positive fluid balance with decimal parsing', () {
    const balance = FluidBalance(
      crystalloids: '1000,5',
      colloids: '250',
      blood: '250',
      diuresis: '400',
      bleeding: '100',
      spongeCount: '1',
      otherLosses: '50',
    );

    expect(balance.totalBalance, 850.5);
    expect(balance.formattedBalance, '+850.5 mL');
  });

  test('reports completeness only when all fields are filled', () {
    const incomplete = FluidBalance.empty();
    const complete = FluidBalance(
      crystalloids: '1000',
      colloids: '0',
      blood: '0',
      diuresis: '500',
      bleeding: '100',
      spongeCount: '',
      otherLosses: '',
    );

    expect(incomplete.isComplete, isFalse);
    expect(complete.isComplete, isTrue);
  });

  test(
    'includes partial blood loss and other encoded losses in total balance',
    () {
      const balance = FluidBalance(
        crystalloids: '1000',
        colloids: '0',
        blood: '0',
        diuresis: '300',
        bleeding: '200',
        spongeCount: '1',
        otherLosses: '50',
        bloodLossEntries: ['Perda parcial|100'],
        otherLossEntries: ['Perdas insensíveis|50 mL/h|100'],
      );

      expect(balance.totalBalance, 150);
      expect(balance.formattedBalance, '+150 mL');
    },
  );
}
