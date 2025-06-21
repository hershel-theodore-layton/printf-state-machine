/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use type HTL\Pragma\Pragmas;
<<file:
  Pragmas(
    vec['PhaLinters', 'fixme:camel_cased_methods_underscored_functions'],
  )>>

interface RequireAnE {
  public function format_upcase_e(int $int)[]: string;
}
