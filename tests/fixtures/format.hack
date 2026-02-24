/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HH;
use namespace HTL\HH4Shim;

function format<T>(
  (function(string, vec<mixed>)[]: (string, vec<mixed>)) $engine,
  HH\FormatString<T> $format,
  mixed ...$args
)[]: (string, vec<mixed>) {
  return $engine(HH4Shim\to_mixed($format) as string, vec($args));
}
