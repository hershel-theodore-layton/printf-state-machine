/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{Str, Vec};

final class SingleArgumentHandler implements Handler {
  public function __construct(
    private string $specifierText,
    private SequenceTransform $sequenceTransform,
    private HackType $typeName,
    private ?TypeAssertionExpression $typeAssertionExpression,
    private ?ValueTransform $valueTransform,
  )[] {}

  public function getArgumentTypeText()[]: HackType {
    return $this->typeName;
  }

  public function getCaseBlock()[]: CaseBlock {
    return vec[
      $this->typeAssertionExpression is nonnull
        ? Str\format('$arg = $arg |> %s;', $this->typeAssertionExpression)
        : null,
      Str\format(
        '$new_format .= %s%s;',
        Str\contains($this->sequenceTransform, '$$') ? '$arg |> ' : '',
        $this->sequenceTransform,
      ),
      Str\format(
        '$new_args[] = %s%s;',
        Str\contains($this->valueTransform ?? '', '$$') ? '$arg |> ' : '$arg',
        $this->valueTransform ?? '',
      ),
      '++$arg_i;',
      '$done = true;',
      'break;',
    ]
      |> Vec\filter_nulls($$)
      |> Str\join($$, "\n")
      |> case_block($$);
  }

  public function getHandCraftedInterfaceName()[]: null {
    return null;
  }

  public function getSpecifierText()[]: string {
    return $this->specifierText;
  }
}
