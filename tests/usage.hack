/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HH\Lib\Str;
use namespace HTL\{HackCompiler, PrintfStateMachine, TestChain};
use type TypeAssertionException;
use function HTL\Expect\{expect, expect_invoked};

<<TestChain\Discover>>
async function usage_async(
  TestChain\Chain $chain,
)[defaults]: Awaitable<TestChain\Chain> {
  $factory = ($prefix, $type_alias_asserters = dict[])[] ==>
    PrintfStateMachine\Factory::create(
      PrintfStateMachine\hack_type($prefix),
      TypeAssertionGenerator::create($type_alias_asserters),
    );

  $write_async = async (PrintfStateMachine\Factory $factory, string $path) ==> {
    $code = "/** printf-state-machine is MIT licensed, see /LICENSE. */\n".
      'namespace HTL\PrintfStateMachine\Tests\\'.
      $path.
      ";\n\n".
      "use type HTL\Pragma\Pragmas;\n".
      "<<file:\n".
      "  Pragmas(\n".
      "    vec['PhaLinters', 'digest:'],\n".
      "    vec['PhaLinters', 'fixme:camel_cased_methods_underscored_functions'],\n".
      "    vec['PhaLinters', 'fixme:unused_variable'],\n".
      "  )>>\n\n".
      PrintfStateMachine\codegen($factory, PrintfStateMachine\ENGINE_TEMPLATE).
      "\n";
    await HackCompiler\write_source_async(
      $code,
      __DIR__.'/codegen/'.$path.'.hack',
    );
  };

  await $write_async($factory('Noop', dict[]), 'Noop');
  await $write_async(
    $factory('MapA2S', dict[])->withRewrite<string>('a', 's'),
    'MapA2S',
  );
  await $write_async(
    $factory('Upper', dict[])->withRewrite<string>('a', 's', Str\uppercase<>),
    'Upper',
  );
  await $write_async(
    $factory('UpperMany', dict[])->withRewriteOfVec<string>(
      'a',
      's',
      Str\uppercase<>,
    ),
    'UpperMany',
  );
  await $write_async(
    $factory('Coalesce', dict[])->withRewriteOfNullable<string>(
      '?s',
      's',
      Str\uppercase<>,
    ),
    'Coalesce',
  );
  await $write_async(
    $factory('AlsoUpper')->withValueHandler<string>('x', Str\uppercase<>),
    'AlsoUpper',
  );
  await $write_async($factory('Custom')->with(new CustomHandler()), 'Custom');
  $value_transforms = $factory('ValueTransforms');
  foreach (
    dict[
      'c' => PrintfStateMachine\value_transform("'constant'"),
      'f' => PrintfStateMachine\value_transform(
        "\\HH\\Lib\\Str\\uppercase('function')",
      ),
      'p' =>
        PrintfStateMachine\value_transform('\\HH\\Lib\\Str\\uppercase($$)'),
      'n' => null,
    ] as $specifier => $transform
  ) {
    $value_transforms = $value_transforms->with(
      new PrintfStateMachine\SingleArgumentHandler(
        $specifier,
        PrintfStateMachine\sequence_transform("'%s'"),
        PrintfStateMachine\hack_type('string'),
        PrintfStateMachine\type_assertion_expression('$$ as string'),
        $transform,
      ),
    );
  }
  await $write_async($value_transforms, 'ValueTransforms');
  await $write_async(
    $factory('ManyPaths')
      ->withRewrite<int>('abc')
      ->withRewrite<bool>('acb')
      ->withRewrite<string>('bac')
      ->withRewrite<float>('bca')
      ->withRewrite<num>('cba')
      ->withRewrite<arraykey>('cab')
      ->withRewriteOfNullable<int>('?abc')
      ->withRewriteOfNullable<bool>('?acb')
      ->withRewriteOfNullable<string>('?bac')
      ->withRewriteOfNullable<float>('?bca')
      ->withRewriteOfNullable<num>('?cba')
      ->withRewriteOfNullable<arraykey>('?cab'),
    'ManyPaths',
  );

  return $chain->group(__FUNCTION__)
    ->testWith2Params(
      'specifier names cannot begin with a percent sign',
      () ==> dict[
        '%' => tuple('%', 'Pass % without the leading `%`.'),
        '%x' => tuple('%x', 'Pass %x without the leading `%`.'),
        '%%x' => tuple('%%x', 'Pass %%x without the leading `%`.'),
      ],
      (string $specifier, string $message) ==> {
        expect_invoked(() ==> $factory('Prefix')->withRewrite<int>($specifier))
          ->toHaveThrown<InvariantException>($message);
      },
    )
    ->test('rename cannot introduce a leading percent sign', () ==> {
      $original = $factory('Prefix')->withRewrite<int>('x');
      expect_invoked(() ==> $original->rename('x', '%x'))
        ->toHaveThrown<InvariantException>('Pass %x without the leading `%`.');
      expect($original->has('x'))->toBeTrue();
      expect($original->has('%x'))->toBeFalse();
    })
    ->test('empty specifier is rejected at registration', () ==> {
      expect_invoked(() ==> $factory('Empty')->withRewrite<int>(''))
        ->toHaveThrown<InvariantException>('Specifier text must not be empty.');
    })
    ->test('empty rename is rejected without changing the original', () ==> {
      $original = $factory('Empty')->withRewrite<int>('x');
      expect_invoked(() ==> $original->rename('x', ''))
        ->toHaveThrown<InvariantException>('Specifier text must not be empty.');
      expect($original->has('x'))->toBeTrue();
      expect($original->has(''))->toBeFalse();
    })
    ->test('a percent sign after the first character is allowed', () ==> {
      expect($factory('Prefix')->withRewrite<int>('x%')->has('x%'))->toBeTrue();
    })
    ->test('ambiguous specifiers', ()[] ==> {
      expect_invoked(
        () ==> $factory('ABA')->withRewrite<int>('ab')->withRewrite<int>('aba'),
      )
        ->toHaveThrown<InvariantException>(
          "Could not add '%aba' because it is ambiguous with '%ab'",
        );
    })
    ->test('replace an existing handler', () ==> {
      $generated = $factory('Prefix')
        ->withRewrite<int>('X', 'd', increment<>)
        ->withRewrite<int>('X', 'd', decrement<>)
        |> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE);

      expect($generated)->toContainSubstring('decrement');
      expect($generated)->toNotContainSubstring('increment');
    })
    ->test('query for a handler', () ==> {
      $with_ab = $factory('Prefix')->withRewrite<int>('ab');
      expect($with_ab->has('ab'))->toBeTrue();
      expect($with_ab->has('a'))->toBeFalse();
      expect($with_ab->has('abc'))->toBeFalse();
    })
    ->test('remove a non existent handler', () ==> {
      expect_invoked(
        () ==> $factory('Prefix')->withRewrite<int>('ab')->without('cd'),
      )->toHaveThrown<InvariantException>(
        'This Group did not have a specifier cd',
      );
    })
    ->test('remove a handler', () ==> {
      $code = $factory('Prefix')
        ->withRewrite<int>('a')
        ->withRewrite<int>('b')
        ->without('a')
        |> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE);

      expect($code)->toNotContainSubstring('format_a');
      expect($code)->toContainSubstring('format_b');
    })
    ->test('remove a handler, if it exists', () ==> {
      $code = $factory('Prefix')
        ->withRewrite<int>('a')
        ->withoutIfExists('a')
        ->withoutIfExists('b')
        |> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE);

      expect($code)->toNotContainSubstring('format_a');
    })
    ->test('rename a handler that does not exist', () ==> {
      expect_invoked(
        () ==> $factory('Prefix')->withRewrite<int>('a')->rename('b', 'a'),
      )->toHaveThrown<InvariantException>(
        'Could not rename handler b, no such handler exists.',
      );
    })
    ->test('rename a handler', () ==> {
      $code = $factory('Prefix')
        ->withRewrite<int>('a')
        ->rename('a', 'b')
        |> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE);

      expect($code)->toNotContainSubstring('format_a');
      expect($code)->toContainSubstring('format_b');
    })
    ->test('rename rejects a longer conflicting specifier', () ==> {
      $original =
        $factory('Prefix')->withRewrite<int>('a')->withRewrite<int>('b');
      expect_invoked(() ==> $original->rename('b', 'ab'))
        ->toHaveThrown<InvariantException>(
          "Could not add '%ab' because it is ambiguous with '%a'",
        );
      expect($original->has('a'))->toBeTrue();
      expect($original->has('b'))->toBeTrue();
      expect($original->has('ab'))->toBeFalse();
    })
    ->test('rename rejects a shorter conflicting specifier', () ==> {
      $original =
        $factory('Prefix')->withRewrite<int>('ab')->withRewrite<int>('c');
      expect_invoked(() ==> $original->rename('c', 'a'))
        ->toHaveThrown<InvariantException>(
          "Could not add '%a' because it is ambiguous with '%ab'",
        );
    })
    ->test('rename does not collide with its old specifier', () ==> {
      $original = $factory('Prefix')->withRewrite<int>('a');
      $longer = $original->rename('a', 'ab');
      expect($longer->has('a'))->toBeFalse();
      expect($longer->has('ab'))->toBeTrue();
      $shorter = $longer->rename('ab', 'a');
      expect($shorter->has('a'))->toBeTrue();
      expect($shorter->has('ab'))->toBeFalse();
      expect($shorter->rename('a', 'a')->has('a'))->toBeTrue();
    })
    ->test('rename can replace an existing handler', () ==> {
      $generated = $factory('Prefix')
        ->withRewrite<int>('a', 'd', increment<>)
        ->withRewrite<int>('b', 'd', decrement<>)
        ->rename('a', 'b')
        |> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE);
      expect($generated)->toContainSubstring('increment');
      expect($generated)->toNotContainSubstring('decrement');
      expect($generated)->toNotContainSubstring('format_a');
    })
    ->test('noop', ()[] ==> {
      list($format, $_) = format<Noop\Noop>(Noop\engine<>, '');
      expect($format)->toEqual('');
    })
    ->test('double percent is ignored', ()[] ==> {
      list($format, $_) = format<Noop\Noop>(Noop\engine<>, 'A %% B');
      expect($format)->toEqual('A %% B');
    })
    ->testWith2Params(
      'truncated specifiers identify their starting position',
      () ==> dict[
        'bare percent' => tuple('%', 0),
        'after text' => tuple('text %', 5),
        'one character prefix' => tuple('%a', 0),
        'two character prefix' => tuple('text %ab', 5),
        'after escaped percent' => tuple('%%%', 2),
      ],
      (string $format, int $start) ==> {
        expect_invoked(() ==> ManyPaths\engine($format, vec[]))
          ->toHaveThrown<InvariantException>(
            Str\format('Incomplete specifier starting at %d', $start),
          );
      },
    )
    ->test('NUL remains an unexpected byte', () ==> {
      expect_invoked(() ==> ManyPaths\engine("%ab\0", vec[]))
        ->toHaveThrown<InvariantException>('Unexpected 0x0 at 3');
    })
    ->test('escaped percent at end is valid', () ==> {
      expect(Noop\engine('%%', vec[]))->toEqual(tuple('%%', vec[]));
    })
    ->test('unknown specifier', ()[] ==> {
      expect_invoked(() ==> Noop\engine('%x', vec[]))
        ->toHaveThrown<InvariantException>('Unexpected 0x78 at 1');
    })
    ->test('too many arguments are passed -> exception', ()[] ==> {
      expect_invoked(() ==> Noop\engine('', vec[123]))
        ->toHaveThrown<InvariantException>(
          'Arguments were not consumed correctly. '.
          '1 arguments were provided, but 0 were consumed',
        );
    })
    ->test('too few arguments are passed -> exception', () ==> {
      expect_invoked(() ==> MapA2S\engine('%a', vec[]))
        ->toHaveThrown<InvariantException>(
          'Arguments were not consumed correctly. '.
          '0 arguments were provided, but 1 were consumed',
        );
    })
    ->test('simple rewrite of the format string', ()[] ==> {
      list($format, $args) =
        format<MapA2S\MapA2S>(MapA2S\engine<>, 'A %a B', 'text');
      expect($format)->toEqual('A %s B');
      expect($args)->toEqual(vec['text']);
    })
    ->test('no whitespace between specifiers', ()[] ==> {
      list($format, $_) =
        format<MapA2S\MapA2S>(MapA2S\engine<>, 'A %%%a%a%% B', 'text', 'txt');
      expect($format)->toEqual('A %%%s%s%% B');
    })
    ->test('no transformation set, runtime type unchecked', ()[] ==> {
      list($_, $args) = MapA2S\engine('%a', vec[123]);
      expect($args)->toEqual(vec[123]);
    })
    ->test('transformation set, runtime type checked', ()[] ==> {
      expect_invoked(() ==> Upper\engine('%a', vec[123]))
        ->toHaveThrown<TypeAssertionException>('Expected string, got int');
    })
    ->test('transformation is invoked on arguments', ()[] ==> {
      list($_, $args) = format<Upper\Upper>(Upper\engine<>, '%a', 'text');
      expect($args)->toEqual(vec['TEXT']);
    })
    ->test('with value handler is just sugar for with rewrite', ()[] ==> {
      list($format, $args) =
        format<AlsoUpper\AlsoUpper>(AlsoUpper\engine<>, 'A %x B', 'text');
      expect($format)->toEqual('A %x B');
      expect($args)->toEqual(vec['TEXT']);
    })
    ->test('vec based operations', ()[] ==> {
      list($_, $args) = format<UpperMany\UpperMany>(
        UpperMany\engine<>,
        '%a %a',
        vec['ab', 'cd'],
        vec[],
      );
      expect($args)->toEqual(vec[vec['AB', 'CD'], vec[]]);
    })
    ->test('null based operations', ()[] ==> {
      list($_, $args) = format<Coalesce\Coalesce>(
        Coalesce\engine<>,
        '%?s %?s',
        'nonnull',
        null,
      );
      expect($args)->toEqual(vec['NONNULL', null]);
    })
    ->test('custom case block', ()[] ==> {
      list($format, $args) =
        format<Custom\Custom>(Custom\engine<>, 'A %DE B', 123);
      expect($format)->toEqual('A %custom B');
      expect($args)->toEqual(vec['transformed(123)']);
    })
    ->test('direct value transforms accept independent expressions', ()[] ==> {
      list($format, $args) = format<ValueTransforms\ValueTransforms>(
        ValueTransforms\engine<>,
        '%c %f %p %n',
        'ignored constant input',
        'ignored function input',
        'pipe',
        'unchanged',
      );
      expect($format)->toEqual('%s %s %s %s');
      expect($args)->toEqual(vec['constant', 'FUNCTION', 'PIPE', 'unchanged']);
    })
    ->test('many paths to exercise the typechecker', ()[] ==> {
      format<ManyPaths\ManyPaths>(
        ManyPaths\engine<>,
        '%abc %acb %bac %bca %cab %cba %?abc %?acb %?bac %?bca %?cab %?cba',
        1,
        true,
        'string',
        1.1,
        1,
        1,
        null,
        null,
        null,
        null,
        null,
        null,
      );
    })
  //
  ;
}
