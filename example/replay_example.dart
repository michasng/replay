import 'package:replay/replay.dart';

class BankState {
  final Map<String, int> balanceByAccountName;

  const BankState({this.balanceByAccountName = const {}});

  @override
  String toString() {
    return '$BankState(balanceByAccount: $balanceByAccountName)';
  }
}

abstract interface class BankEvent {}

class BalanceSetEvent implements BankEvent {
  final String accountName;
  final int balance;

  const BalanceSetEvent({required this.accountName, required this.balance});

  @override
  String toString() {
    return '$BalanceSetEvent(accountName: $accountName, balance: $balance)';
  }
}

class BalanceUnsetEvent implements BankEvent {
  final String accountName;

  const BalanceUnsetEvent({required this.accountName});

  @override
  String toString() {
    return '$BalanceUnsetEvent(accountName: $accountName)';
  }
}

class BalanceSetEventReducer
    implements EventReducer<BalanceSetEvent, BankState> {
  @override
  BankState reduce(BalanceSetEvent event, BankState state) {
    return BankState(
      balanceByAccountName: {
        ...state.balanceByAccountName,
        event.accountName: event.balance,
      },
    );
  }
}

class BalanceUnsetEventReducer
    implements EventReducer<BalanceUnsetEvent, BankState> {
  @override
  BankState reduce(BalanceUnsetEvent event, BankState state) {
    return BankState(
      balanceByAccountName: {
        for (final MapEntry(key: accountName, value: balance)
            in state.balanceByAccountName.entries)
          if (accountName != event.accountName) accountName: balance,
      },
    );
  }
}

abstract interface class BankCommand {}

class OpenAccountCommand implements BankCommand {
  final String accountName;
  final int initialBalance;

  const OpenAccountCommand({
    required this.accountName,
    required this.initialBalance,
  });

  @override
  String toString() {
    return '$OpenAccountCommand(accountName: $accountName, initialBalance: $initialBalance)';
  }
}

class CloseAccountCommand implements BankCommand {
  final String accountName;

  const CloseAccountCommand({required this.accountName});

  @override
  String toString() {
    return '$CloseAccountCommand(accountName: $accountName)';
  }
}

class TransferMoneyCommand implements BankCommand {
  final String sourceAccountName;
  final String targetAccountName;
  final int amount;

  const TransferMoneyCommand({
    required this.sourceAccountName,
    required this.targetAccountName,
    required this.amount,
  });

  @override
  String toString() {
    return '$TransferMoneyCommand(sourceAccountName: $sourceAccountName, targetAccountName: $targetAccountName, amount: $amount)';
  }
}

class OpenAccountCommandDecider
    implements CommandDecider<OpenAccountCommand, BankEvent, BankState> {
  @override
  Iterable<BankEvent> decide(
    OpenAccountCommand command,
    BankState state,
  ) sync* {
    if (state.balanceByAccountName.containsKey(command.accountName)) {
      throw Exception("Account '${command.accountName}' already exists.");
    }
    if (command.initialBalance < 0) {
      throw Exception('Balance must not be negative.');
    }

    yield BalanceSetEvent(
      accountName: command.accountName,
      balance: command.initialBalance,
    );
  }
}

class CloseAccountCommandDecider
    implements CommandDecider<CloseAccountCommand, BankEvent, BankState> {
  @override
  Iterable<BankEvent> decide(
    CloseAccountCommand command,
    BankState state,
  ) sync* {
    if (!state.balanceByAccountName.containsKey(command.accountName)) {
      throw Exception("Account '${command.accountName}' doesn't exist.");
    }

    yield BalanceUnsetEvent(accountName: command.accountName);
  }
}

class TransferMoneyCommandDecider
    implements CommandDecider<TransferMoneyCommand, BankEvent, BankState> {
  @override
  Iterable<BankEvent> decide(
    TransferMoneyCommand command,
    BankState state,
  ) sync* {
    final sourceBalance = state.balanceByAccountName[command.sourceAccountName];
    if (sourceBalance == null) {
      throw Exception(
        "Source account '${command.sourceAccountName}' doesn't exist.",
      );
    }
    if (sourceBalance < command.amount) {
      throw Exception(
        "Balance of account '${command.sourceAccountName}' is insufficient.",
      );
    }

    final targetBalance = state.balanceByAccountName[command.targetAccountName];
    if (targetBalance == null) {
      throw Exception(
        "Target account '${command.targetAccountName}' doesn't exist.",
      );
    }

    yield BalanceSetEvent(
      accountName: command.sourceAccountName,
      balance: sourceBalance - command.amount,
    );
    yield BalanceSetEvent(
      accountName: command.targetAccountName,
      balance: targetBalance + command.amount,
    );
  }
}

void main() {
  final aggregate = Aggregate<BankCommand, BankEvent, BankState>(
    initialState: BankState(balanceByAccountName: {}),
    commandDecider: ComposableCommandDecider({
      OpenAccountCommand: OpenAccountCommandDecider(),
      CloseAccountCommand: CloseAccountCommandDecider(),
      TransferMoneyCommand: TransferMoneyCommandDecider(),
    }),
    eventReducer: ComposableEventReducer({
      BalanceSetEvent: BalanceSetEventReducer(),
      BalanceUnsetEvent: BalanceUnsetEventReducer(),
    }),
    eventStore: InMemoryEventStore([
      BalanceSetEvent(accountName: 'Foo', balance: 1000),
    ]),
    replayStoredEvents: true,
    onEventReduced: (event, _, _) => print('Reduced $event'),
  );
  print('Initial state: ${aggregate.currentState}');

  final commands = [
    OpenAccountCommand(accountName: 'Faa', initialBalance: -500),
    OpenAccountCommand(accountName: 'Bar', initialBalance: 500),
    TransferMoneyCommand(
      sourceAccountName: 'Bar',
      targetAccountName: 'Foo',
      amount: 100,
    ),
    TransferMoneyCommand(
      sourceAccountName: 'Bar',
      targetAccountName: 'Foo',
      amount: 500,
    ),
    TransferMoneyCommand(
      sourceAccountName: 'Foo',
      targetAccountName: 'Bar',
      amount: 500,
    ),
    CloseAccountCommand(accountName: 'Foo'),
  ];

  for (final command in commands) {
    print('Trying to process command: $command');
    try {
      final state = aggregate.process(command);
      print('Updated state: $state');
    } catch (e) {
      print('Validation failed with $e');
    }
  }
}
