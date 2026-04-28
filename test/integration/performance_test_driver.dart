import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      if (data != null) {
        // Iterate through all captured timelines in the response data
        for (final entry in data.entries) {
          final key = entry.key;
          final timelineData = entry.value as Map<String, dynamic>?;

          if (timelineData != null && timelineData.containsKey('traceEvents')) {
            final timeline = driver.Timeline.fromJson(timelineData);
            final summary = driver.TimelineSummary.summarize(timeline);

            // Save the timeline and summary to build/test/
            await summary.writeTimelineToFile(
              key,
              pretty: true,
              includeSummary: true,
            );
          }
        }
      }
    },
  );
}
