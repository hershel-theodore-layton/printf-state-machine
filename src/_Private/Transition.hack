/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\_Private;

use namespace HH\Lib\Str;
use namespace HTL\PrintfStateMachine;
use function ord;

final class Transition {
  private string $prefix;
  private int $lastChar;

  public function __construct(
    private string $specifierText,
    private ?PrintfStateMachine\ArgumentList $arg,
    private PrintfStateMachine\HackType $returnType,
    private ?PrintfStateMachine\Handler $handler,
  )[] {
    $this->prefix =
      Str\slice($specifierText, 0, Str\length($specifierText) - 1);
    $this->lastChar = ord($specifierText[Str\length($specifierText) - 1]);
  }

  public function getArg()[]: ?PrintfStateMachine\ArgumentList {
    return $this->arg;
  }

  public function getHandler()[]: ?PrintfStateMachine\Handler {
    return $this->handler;
  }

  public function getLastChar()[]: int {
    return $this->lastChar;
  }

  public function getPrefix()[]: string {
    return $this->prefix;
  }

  public function getReturnType()[]: PrintfStateMachine\HackType {
    return $this->returnType;
  }

  public function getSpecifierText()[]: string {
    return $this->specifierText;
  }
}
