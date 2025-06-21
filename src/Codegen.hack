/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{C, Dict, Str, Vec};

final class Codegen {
  private vec<Handler> $handlers;

  public function __construct(
    private Group $group,
    private HackType $prefix,
  )[] {
    $this->handlers =
      Vec\sort_by($this->group->getHandlers(), $h ==> $h->getSpecifierText());
  }

  public function generateRepacker()[]: Code {
    return static::extractInterfaceMethods($this->prefix, $this->handlers)
      |> Vec\flatten($$)
      |> static::generateSwitchStatement($$);
  }

  public function generateInterfaces()[]: Entities {
    return static::extractInterfaceMethods($this->prefix, $this->handlers)
      |> Vec\map_with_key($$, static::generateInterface<>)
      |> Str\join($$, "\n\n")
      |> entities($$);
  }

  private static function extractInterfaceMethods(
    HackType $prefix,
    vec<Handler> $handlers,
  )[]: dict<HackType, dict<MethodName, _Private\Transition>> {
    $interfaces = dict[$prefix => dict[]];

    $transform_methods = dict[
      $prefix => dict[
        method_name('format_0x25') =>
          new _Private\Transition('%', null, hack_type('string'), null),
      ],
    ];

    foreach ($handlers as $h) {
      $name = $prefix;
      $specifier_text = $h->getSpecifierText();

      for ($i = 0; $i < Str\length($specifier_text) - 1; ++$i) {
        $char = $specifier_text[$i];

        $old_name = $name;
        $name = hack_type($name.'With'._Private\text_transform($char));

        $transform_methods[$old_name] ??= dict[];
        $transform_methods[$old_name][_Private\to_method_name($char)] =
          new _Private\Transition(
            Str\slice($specifier_text, 0, $i + 1),
            null,
            $name,
            null,
          );

        $interfaces[$name] ??= dict[];
      }

      $argument_type_text = $h->getArgumentTypeText();
      $return_type = $h->getHandCraftedInterfaceName() ?? hack_type('string');

      $interfaces[$name][
        $h->getSpecifierText()
        |> $$[Str\length($$) - 1]
        |> _Private\to_method_name($$)
      ] = new _Private\Transition(
        $specifier_text,
        $argument_type_text is nonnull ? $argument_type_text.' $_' : ''
          |> argument_list($$),
        $return_type,
        $h,
      );
    }

    foreach ($transform_methods as $name => $methods) {
      $interfaces[$name] ??= dict[];
      $interfaces[$name] = Dict\merge($interfaces[$name], $methods);
    }

    return $interfaces;
  }

  private static function generateInterface(
    string $name,
    dict<MethodName, _Private\Transition> $methods,
  )[]: Code {
    return Str\format(
      "interface %s {\n%s\n}",
      $name,
      Vec\map_with_key(
        $methods,
        ($name, $trans) ==> Str\format(
          'public function %s(%s)[]: %s;',
          $name,
          $trans->getArg() ?? '',
          $trans->getReturnType(),
        )
          |> indent($$),
      )
        |> Str\join($$, "\n"),
    )
      |> code($$);
  }

  private static function generateSwitchStatement(
    vec<_Private\Transition> $transitions,
  )[]: Code {
    $switches = vec[vec[]];
    $prefixes = dict['' => 0];

    foreach ($transitions as $trans) {
      $prefix = $trans->getPrefix();
      $specifier_text = $trans->getSpecifierText();
      $handler = $trans->getHandler();

      if ($handler is null) {
        $prefixes[$specifier_text] = C\count($switches);
        $switches[] = vec[];
        $switches[$prefixes[$prefix]][] = Str\format(
          "case 0x%x: // %s -> %s\n". //
          "  %s\n".
          '  break;',
          $trans->getLastChar(),
          _Private\string_export_pure($trans->getSpecifierText()),
          $trans->getReturnType(),
          Str\format('$state = %d;', $prefixes[$specifier_text]),
        )
          |> indent($$);
      } else {
        $switches[$prefixes[$prefix]][] = Str\format(
          "case 0x%x: // %s\n%s",
          $trans->getLastChar(),
          _Private\string_export_pure($trans->getSpecifierText()),
          $handler->getCaseBlock() |> indent($$),
        )
          |> indent($$);
      }
    }

    $default =
      "default:\n  invariant_violation('Unexpected 0x%x at %d', \$char, \$char_i);"
      |> indent($$);

    return Vec\map(
      $switches,
      $s ==>
        Str\format("switch (\$char) {\n%s\n%s\n}", Str\join($s, "\n"), $default)
        |> indent($$),
    )
      |> Vec\map_with_key(
        $$,
        ($state, $block) ==>
          Str\format("case %d:\n%s\n  break;", $state, $block)
          |> indent($$),
      )
      |> Str\join($$, "\n\n")
      |> indent($$)
      |> Str\format(
        "switch (\$state) {\n%s\n    %s}",
        $$,
        "default:\n      invariant_violation('unreachable');\n  ",
      )
      |> indent($$, 2);
  }
}
