/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\Project_Hm3ki0DCmQ4l\GeneratedTestChain;

use namespace HTL\TestChain;
use type HTL\Pragma\Pragmas;

<<file: Pragmas(vec['PhaLinters', 'digest:669450f8fadc1ca5ebc0'])>>

async function tests_async(
  TestChain\ChainController<\HTL\TestChain\Chain> $controller,
)[defaults]: Awaitable<TestChain\ChainController<\HTL\TestChain\Chain>> {
  return $controller
    ->addTestGroupAsync(\HTL\PrintfStateMachine\Tests\usage_async<>);
}
