/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

interface Handler {
  public function getArgumentTypeText()[]: ?HackType;
  public function getCaseBlock()[]: CaseBlock;
  public function getHandCraftedInterfaceName()[]: ?HackType;
  public function getSpecifierText()[]: string;
}
