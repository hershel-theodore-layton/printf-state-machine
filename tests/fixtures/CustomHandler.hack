/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HTL\PrintfStateMachine;

final class CustomHandler implements PrintfStateMachine\Handler {
  public function getArgumentTypeText()[]: ?PrintfStateMachine\HackType {
    return null;
  }

  public function getCaseBlock()[]: PrintfStateMachine\CaseBlock {
    return <<<'HACK'
invariant($old_format[$char_i + 1] === 'E', 'expected an E');
$new_args[] = 'transformed(' . $arg as int . ')';
++$arg_i;
++$char_i;
$new_format .= '%custom';
$done = true;
break;
HACK
      |> PrintfStateMachine\case_block($$);
  }

  public function getHandCraftedInterfaceName()[]: PrintfStateMachine\HackType {
    return PrintfStateMachine\hack_type('\\'.RequireAnE::class);
  }

  public function getSpecifierText()[]: string {
    return 'D';
  }
}
