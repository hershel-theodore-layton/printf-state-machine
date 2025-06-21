/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests;

use namespace HH\Lib\{File, Str};
use namespace HTL\{PrintfStateMachine, TestChain};
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
      "    vec['PhaLinters', 'fixme:camel_cased_methods_underscored_functions'],\n".
      "    vec['PhaLinters', 'fixme:unused_variable'],\n".
      "  )>>\n\n".
      PrintfStateMachine\codegen($factory, PrintfStateMachine\ENGINE_TEMPLATE).
      "\n";
    $file = File\open_write_only(
      __DIR__.'/codegen/'.$path.'.hack',
      File\WriteMode::TRUNCATE,
    );
    using $file->closeWhenDisposed();
    using $file->tryLockx(File\LockType::EXCLUSIVE);
    await $file->writeAllAsync($code);
  };

  await $write_async($factory('Noop', dict[]), 'Noop');
  await $write_async(
    $factory('MapA2S', dict[])->withRewrite<string>('a', 's'),
    'MapA2S',
  );
  await $write_async(
    $factory('Reverse', dict[])->withRewrite<string>('a', 's', Str\reverse<>),
    'Reverse',
  );
  await $write_async(
    $factory('ReverseMany', dict[])->withRewriteOfVec<string>(
      'a',
      's',
      Str\reverse<>,
    ),
    'ReverseMany',
  );
  await $write_async(
    $factory('Coalesce', dict[])->withRewriteOfNullable<string>(
      '?s',
      's',
      Str\reverse<>,
    ),
    'Coalesce',
  );
  await $write_async(
    $factory('AlsoReverse')->withValueHandler<string>('x', Str\reverse<>),
    'AlsoReverse',
  );
  await $write_async($factory('Custom')->with(new CustomHandler()), 'Custom');
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
    ->test('ambiguous specifiers', ()[] ==> {
      expect_invoked(
        () ==> $factory('ABA')->withRewrite<int>('ab')->withRewrite<int>('aba'),
      )
        ->toHaveThrown<InvariantException>(
          "Could not add '%aba' because it is ambiguous with '%ab'",
        );
    })
    ->test('noop', ()[] ==> {
      list($format, $_) = format<Noop\Noop>(Noop\engine<>, '');
      expect($format)->toEqual('');
    })
    ->test('double percent is ignored', ()[] ==> {
      list($format, $_) = format<Noop\Noop>(Noop\engine<>, 'A %% B');
      expect($format)->toEqual('A %% B');
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
      expect_invoked(() ==> Reverse\engine('%a', vec[123]))
        ->toHaveThrown<\TypeAssertionException>('Expected string, got int');
    })
    ->test('transformation is invoked on arguments', ()[] ==> {
      list($_, $args) = format<Reverse\Reverse>(Reverse\engine<>, '%a', 'text');
      expect($args)->toEqual(vec['txet']);
    })
    ->test('with value handler is just sugar for with rewrite', ()[] ==> {
      list($format, $args) =
        format<AlsoReverse\AlsoReverse>(AlsoReverse\engine<>, 'A %x B', 'text');
      expect($format)->toEqual('A %x B');
      expect($args)->toEqual(vec['txet']);
    })
    ->test('vec based operations', ()[] ==> {
      list($_, $args) = format<ReverseMany\ReverseMany>(
        ReverseMany\engine<>,
        '%a %a',
        vec['ab', 'cd'],
        vec[],
      );
      expect($args)->toEqual(vec[vec['ba', 'dc'], vec[]]);
    })
    ->test('null based operations', ()[] ==> {
      list($_, $args) = format<Coalesce\Coalesce>(
        Coalesce\engine<>,
        '%?s %?s',
        'nonnull',
        null,
      );
      expect($args)->toEqual(vec['llunnon', null]);
    })
    ->test('custom case block', ()[] ==> {
      list($format, $args) =
        format<Custom\Custom>(Custom\engine<>, 'A %DE B', 123);
      expect($format)->toEqual('A %custom B');
      expect($args)->toEqual(vec['transformed(123)']);
    })
    ->test('many paths to excercise the typechecker', ()[] ==> {
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
