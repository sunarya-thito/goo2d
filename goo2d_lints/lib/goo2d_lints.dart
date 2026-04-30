import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/doc_rules.dart';

PluginBase createPlugin() => _Goo2dLinter();

class _Goo2dLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const Goo2dDocSummary(),
        const Goo2dDocDepth(),
        const Goo2dDocExample(),
        const Goo2dDocParams(),
        const Goo2dDocNoPlaceholders(),
        const Goo2dDocGenerics(),
        const Goo2dDocLinks(),
        const Goo2dDocNoGetterParams(),
        const Goo2dDocPublicSetter(),
        const Goo2dDocNoOverrideDocs(),
      ];
}
