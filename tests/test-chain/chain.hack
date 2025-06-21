/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\Project_Hm3ki0DCmQ4l\GeneratedTestChain;

use namespace HTL\TestChain;

async function tests_async(
  TestChain\ChainController<\HTL\TestChain\Chain> $controller
)[defaults]: Awaitable<TestChain\ChainController<\HTL\TestChain\Chain>> {
  return $controller
    ->addTestGroupAsync(\HTL\PrintfStateMachine\Tests\usage_async<>);
}
