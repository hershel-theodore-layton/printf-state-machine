/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{Str, Vec};

function codegen(Factory $factory, string $template)[]: Entities {
  $template = $template |> Str\slice($$, Str\search($$, 'function') as nonnull);

  $codegen = $factory->toCodegen();
  $type_assertion_generator = $factory->getTypeAssertionGenerator();
  $casts = $type_assertion_generator->generateCasts();

  $impl = $codegen->generateRepacker()
    |> Str\replace($template, '    // @@magic(switch)', $$);

  $interfaces = $codegen->generateInterfaces();

  return Vec\filter(vec[$interfaces, $impl, $casts])
    |> Str\join($$, "\n\n")
    |> entities($$);
}
