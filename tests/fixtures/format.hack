/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HH;

function format<T>(
  (function(string, vec<mixed>)[]: (string, vec<mixed>)) $engine,
  HH\FormatString<T> $format,
  mixed ...$args
)[]: (string, vec<mixed>) {
  return $engine($format as string, $args);
}
