/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH;

final class Factory {

  private function __construct(
    private Group $group,
    private HackType $prefix,
    private TypeAssertionGenerator $typeAssertionGenerator,
  )[] {}

  public static function create(
    HackType $prefix,
    TypeAssertionGenerator $type_assertion_generator,
  )[]: this {
    return new static(Group::create(), $prefix, $type_assertion_generator);
  }

  public function apply((function(this)[_]: this) $func)[ctx $func]: this {
    return $func($this);
  }

  public function getTypeAssertionGenerator()[]: TypeAssertionGenerator {
    return $this->typeAssertionGenerator;
  }

  public function with(
    Handler $handler,
    ?TypeAssertionGenerator $type_assertion_generator = null,
  )[]: this {
    return $this->group->with($handler)
      |> new static(
        $$,
        $this->prefix,
        $type_assertion_generator ?? $this->typeAssertionGenerator,
      );
  }

  public function withRewrite<reify T>(
    string $from_sequence,
    ?string $to_sequence = null,
    ?(function(T)[]: mixed) $value_func = null,
  )[]: this {
    list(
      $type_assertion_expression,
      $value_transform,
      $type_assertion_generator,
    ) = static::functionRefToFunctionInvocation<T>(
      $value_func,
      $this->typeAssertionGenerator,
    );
    return $this->with(
      new SingleArgumentHandler(
        $from_sequence,
        static::transformSequence($from_sequence, $to_sequence),
        $this->typeToText<T>(),
        $type_assertion_expression,
        $value_transform is null
          ? null
          : value_transform($value_transform.'($$)'),
      ),
      $type_assertion_generator,
    );
  }

  public function withRewriteOfNullable<reify T>(
    string $from_sequence,
    ?string $to_sequence = null,
    ?(function(T)[]: mixed) $value_func = null,
  )[]: this {
    list(
      $type_assertion_expression,
      $value_transform,
      $type_assertion_generator,
    ) = static::functionRefToFunctionInvocation<?T>(
      $value_func,
      $this->typeAssertionGenerator,
    );
    return $this->with(
      new SingleArgumentHandler(
        $from_sequence,
        static::transformSequence($from_sequence, $to_sequence),
        $this->typeToText<?T>(),
        $type_assertion_expression,
        $value_transform is null
          ? null
          : value_transform('$$ is null ? null : '.$value_transform.'($$)'),
      ),
      $type_assertion_generator,
    );
  }

  public function withRewriteOfVec<reify T>(
    string $from_sequence,
    ?string $to_sequence = null,
    ?(function(T)[]: mixed) $value_func = null,
  )[]: this {
    list(
      $type_assertion_expression,
      $value_transform,
      $type_assertion_generator,
    ) = static::functionRefToFunctionInvocation<vec<T>>(
      $value_func,
      $this->typeAssertionGenerator,
    );
    return $this->with(
      new SingleArgumentHandler(
        $from_sequence,
        static::transformSequence($from_sequence, $to_sequence),
        $this->typeToText<vec<T>>(),
        $type_assertion_expression,
        $value_transform is null
          ? null
          : value_transform('\HH\Lib\Vec\map($$, '.$value_transform.'<>)'),
      ),
      $type_assertion_generator,
    );
  }

  public function withValueHandler<reify T>(
    string $sequence,
    (function(T)[]: mixed) $value_func,
  )[]: this {
    return $this->withRewrite<T>($sequence, null, $value_func);
  }

  public function toCodegen()[]: Codegen {
    return new Codegen($this->group, $this->prefix);
  }

  private function typeToText<reify T>()[]: HackType {
    return $this->typeAssertionGenerator->getTypename<T>();
  }

  private static function functionRefToFunctionInvocation<reify T>(
    ?(function(nothing)[]: mixed) $value_func,
    TypeAssertionGenerator $type_assertion_generator,
  )[]: (?TypeAssertionExpression, ?string, TypeAssertionGenerator) {
    if ($value_func is null) {
      return tuple(null, null, $type_assertion_generator);
    }

    list($type_assertion_generator, $cast) =
      $type_assertion_generator->forType<T>();

    if (HH\is_fun($value_func)) {
      return '\\'.HH\fun_get_function($value_func)
        |> tuple($cast, $$, $type_assertion_generator);
    }

    invariant(
      HH\is_class_meth($value_func),
      'Could not serialize function reference, please pass func<>, or Cls::func<>',
    );

    return '\\'.
      HH\class_meth_get_class($value_func).
      '::'.
      HH\class_meth_get_method($value_func)
      |> tuple($cast, $$, $type_assertion_generator);
  }

  private static function transformSequence(
    string $from_sequence,
    ?string $to_sequence,
  )[]: SequenceTransform {
    return $to_sequence ?? $from_sequence
      |> _Private\string_export_pure('%'.$$)
      |> sequence_transform($$);
  }
}
