import 'package:replay/replay.dart';
import 'package:test/test.dart';

import 'option_finder_mock.dart';

class State {}

abstract interface class Option {}

class Option0 implements Option {}

class Option1 implements Option {}

void main() {
  group('ComposableOptionFinder', () {
    final option0FinderMock = OptionFinderMock<Option0, State>();
    final option1FinderMock = OptionFinderMock<Option1, State>();
    late ComposableOptionFinder<Option, State> composableOptionFinder;

    setUp(() {
      option0FinderMock.calls.clear();
      option1FinderMock.calls.clear();

      composableOptionFinder = ComposableOptionFinder({
        Option0: option0FinderMock,
      });
    });

    group('register', () {
      test(
        'when registering another finder for the same option type, throws',
        () {
          expect(
            () => composableOptionFinder.register<Option0>(option0FinderMock),
            throwsA(
              allOf(
                isArgumentError,
                predicate(
                  (ArgumentError e) =>
                      e.message ==
                      "Another value is already registered for 'Option0'",
                ),
              ),
            ),
          );
        },
      );

      test("when registering another finder for a different option type, doesn't throw", () {
        composableOptionFinder.register<Option1>(option1FinderMock);
      });

      test("doesn't modify the map passed to the constructor", () {
        final finderByOptionType = <Type, OptionFinder<Option, State>>{
          Option0: option0FinderMock,
        };

        ComposableOptionFinder(finderByOptionType)
            .register<Option1>(option1FinderMock);

        expect(finderByOptionType.keys, [Option0]);
      });
    });

    group('find', () {
      setUp(() {
        composableOptionFinder.register<Option1>(option1FinderMock);
      });

      test('returns the options returned by all registered finders', () {
        final state = State();
        final expectedOptions0 = [Option0()];
        option0FinderMock.onFind = (_) => expectedOptions0;
        final expectedOptions1 = [Option1(), Option1()];
        option1FinderMock.onFind = (_) => expectedOptions1;

        final options = composableOptionFinder.find(state);

        expect(options, [...expectedOptions0, ...expectedOptions1]);
        expect(option0FinderMock.calls, [state]);
        expect(option1FinderMock.calls, [state]);
      });
    });

    test('given finders registered out of type order, find returns options in registration order', () {
      final finder = ComposableOptionFinder<Option, State>()
        ..register<Option1>(option1FinderMock)
        ..register<Option0>(option0FinderMock);
      final option0 = Option0();
      final option1 = Option1();
      option0FinderMock.onFind = (_) => [option0];
      option1FinderMock.onFind = (_) => [option1];

      expect(finder.find(State()), [option1, option0]);
    });
  });
}
