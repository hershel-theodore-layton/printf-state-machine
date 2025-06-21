/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{Str, Vec};

function indent(string $code, int $levels = 1)[]: Code {
  $indent_with = Str\repeat('  ', $levels);
  return Str\split($code, "\n")
    |> Vec\map($$, $x ==> $x === '' ? '' : $indent_with.$x)
    |> Str\join($$, "\n")
    |> code($$);
}
