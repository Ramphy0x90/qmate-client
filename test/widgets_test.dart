import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:qmate_client/core/models.dart';
import 'package:qmate_client/features/discover/widgets/request_card.dart';
import 'package:qmate_client/shared/widgets/chip_multi_select.dart';
import 'package:qmate_client/shared/widgets/initials_avatar.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final request = RequestView(
    id: 'r1',
    author: const UserSummary(id: 'u1', username: 'ana', displayName: 'Ana Lee', photoUrl: null, roleTags: []),
    activityType: ActivityType.walk,
    note: 'Evening walk by the river',
    status: RequestStatus.open,
    addons: const ['Hug goodbye'],
    createdAt: DateTime.now(),
  );

  testWidgets('RequestCard shows the request and reports taps via callbacks', (tester) async {
    var accepted = 0, declined = 0, authorTaps = 0;
    await tester.pumpWidget(
      _host(
        RequestCard(
          request: request,
          onAccept: () => accepted++,
          onDecline: () => declined++,
          onAuthorTap: () => authorTaps++,
        ),
      ),
    );

    expect(find.text('Evening walk by the river'), findsOneWidget);
    expect(find.text('Hug goodbye'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Not for me'));
    await tester.tap(find.text('Ana Lee'));
    expect((accepted, declined, authorTaps), (1, 1, 1));
  });

  testWidgets('RequestCard disables actions while busy', (tester) async {
    var accepted = 0;
    await tester.pumpWidget(
      _host(
        RequestCard(request: request, busy: true, onAccept: () => accepted++, onDecline: () {}, onAuthorTap: () {}),
      ),
    );
    await tester.tap(find.text('Accept'), warnIfMissed: false);
    expect(accepted, 0);
  });

  testWidgets('ChipMultiSelect toggles selection', (tester) async {
    Set<String> selected = {'a'};
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(
          ChipMultiSelect<String>(
            options: const ['a', 'b'],
            labelOf: (s) => s.toUpperCase(),
            selected: selected,
            onChanged: (s) => setState(() => selected = s),
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilterChip, 'B'));
    await tester.pump();
    expect(selected, {'a', 'b'});
    await tester.tap(find.widgetWithText(FilterChip, 'A'));
    await tester.pump();
    expect(selected, {'b'});
  });

  testWidgets('InitialsAvatar shows up to two initials', (tester) async {
    await tester.pumpWidget(_host(const InitialsAvatar(name: 'ana maria lee')));
    expect(find.text('AM'), findsOneWidget);
  });
}
