/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{C, Str, Vec};

/**
 * The template must be a function fragment beginning with `function engine(`,
 * with exactly one standalone `// @@magic(switch)` line. No file preamble is
 * accepted. Leading/trailing whitespace and marker indentation are ignored.
 */
function codegen(Factory $factory, string $template)[]: Entities {
  $template = Str\trim($template);
  invariant(
    Str\starts_with($template, 'function engine('),
    'Engine template must begin with function engine(, without a file preamble.',
  );
  $lines = Str\split($template, "\n");
  $markers =
    Vec\filter($lines, $line ==> Str\trim($line) === '// @@magic(switch)');
  invariant(
    C\count($markers) === 1,
    'Engine template must contain exactly one standalone // @@magic(switch) line.',
  );

  $codegen = $factory->toCodegen();
  $type_assertion_generator = $factory->getTypeAssertionGenerator();
  $casts = $type_assertion_generator->generateCasts();

  $repacker = $codegen->generateRepacker();
  $impl = Vec\map(
    $lines,
    $line ==> Str\trim($line) === '// @@magic(switch)' ? $repacker : $line,
  )
    |> Str\join($$, "\n");

  $interfaces = $codegen->generateInterfaces();

  return Vec\filter(vec[$interfaces, $impl, $casts])
    |> Str\join($$, "\n\n")
    |> entities($$);
}
