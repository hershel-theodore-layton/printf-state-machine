/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{Str, Vec};
use namespace HTL\PrintfStateMachine;

function codegen(
  PrintfStateMachine\Factory $factory,
  string $template,
)[]: PrintfStateMachine\Entities {
  $template = $template |> Str\slice($$, Str\search($$, 'function') as nonnull);

  $codegen = $factory->toCodegen();
  $type_assertion_generator = $factory->getTypeAssertionGenerator();
  $casts = $type_assertion_generator->generateCasts();

  $impl = $codegen->generateRepacker()
    |> Str\replace($template, '    // @@magic(switch)', $$);

  $interfaces = $codegen->generateInterfaces();

  return Vec\filter(vec[$interfaces, $impl, $casts])
    |> Str\join($$, "\n\n")
    |> PrintfStateMachine\entities($$);
}
