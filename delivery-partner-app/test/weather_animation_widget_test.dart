import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/weather_provider.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/weather_animation_widget.dart';

/// Provider stub so the widget can be driven without hitting the weather API.
class FakeWeatherProvider extends WeatherProvider {
  FakeWeatherProvider(this._raining);

  bool _raining;

  @override
  bool get isRaining => _raining;

  void setRaining(bool value) {
    _raining = value;
    notifyListeners();
  }
}

Widget _wrap(FakeWeatherProvider provider) {
  return ChangeNotifierProvider<WeatherProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Scaffold(body: WeatherAnimationWidget()),
    ),
  );
}

void main() {
  testWidgets('hides the rain icon when it is not raining',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(FakeWeatherProvider(false)));

    expect(find.byType(Image), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('shows the rain gif when it is raining',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(FakeWeatherProvider(true)));

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppImages.rains);
  });

  testWidgets('reacts when rain status flips at runtime',
      (WidgetTester tester) async {
    final provider = FakeWeatherProvider(false);
    await tester.pumpWidget(_wrap(provider));
    expect(find.byType(Image), findsNothing);

    provider.setRaining(true);
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    provider.setRaining(false);
    await tester.pump();
    expect(find.byType(Image), findsNothing);
  });
}
