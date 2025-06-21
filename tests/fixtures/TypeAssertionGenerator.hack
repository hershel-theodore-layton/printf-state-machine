/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HH\Lib\Str;
use namespace HTL\{PrintfStateMachine, StaticTypeAssertionCodegen, TypeVisitor};

final class TypeAssertionGenerator
  implements PrintfStateMachine\TypeAssertionGenerator {
  private function __construct(
    private dict<string, PrintfStateMachine\Entities> $functions,
    private TypeVisitor\TypenameVisitor $typeVisitor,
    private dict<string, string> $typeAliasAsserters,
  )[] {}

  public static function create(
    dict<string, string> $type_alias_asserters,
  )[]: this {
    return new static(
      dict[],
      new TypeVisitor\TypenameVisitor(),
      $type_alias_asserters,
    );
  }

  public function forType<reify T>(
  )[]: (this, PrintfStateMachine\TypeAssertionExpression) {
    $body = StaticTypeAssertionCodegen\from_type<T>(
      $this->typeAliasAsserters,
      $m ==> {
        throw new \Exception($m);
      },
      ($x, $y) ==> {
        throw new \Exception(($x ?? '').'::'.$y);
      },
    )
      |> StaticTypeAssertionCodegen\emit_body_for_assertion_function($$);
    $type = TypeVisitor\visit<T, _, _>($this->typeVisitor);
    $name = static::typeNameToFunctionName($type);

    $functions = $this->functions;
    $functions[$name] = static::newFunction($name, $type, $body);
    return tuple(
      new static($functions, $this->typeVisitor, $this->typeAliasAsserters),
      PrintfStateMachine\type_assertion_expression($name.'($$)'),
    );
  }

  public function getTypename<reify T>()[]: PrintfStateMachine\HackType {
    return TypeVisitor\visit<T, _, _>(new TypeVisitor\TypenameVisitor())
      |> PrintfStateMachine\hack_type($$);
  }

  public function generateCasts()[]: PrintfStateMachine\Entities {
    return
      Str\join($this->functions, "\n\n") |> PrintfStateMachine\entities($$);
  }

  private static function typeNameToFunctionName(string $type_name)[]: string {
    return \sha1($type_name) |> Str\slice($$, 16) |> 'cast_generated_'.$$;
  }

  private static function newFunction(
    string $name,
    string $type,
    string $body,
  )[]: PrintfStateMachine\Entities {
    return Str\format(
      'function %s(mixed $htl_untyped_variable)[]: %s { %s }',
      $name,
      $type,
      Str\replace($body, "\n", ''),
    )
      |> PrintfStateMachine\entities($$);
  }
}
