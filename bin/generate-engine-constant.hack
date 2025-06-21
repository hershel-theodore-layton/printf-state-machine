/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\_Private\Bin;

use namespace HH\Lib\{File, Str};
use namespace HTL\PrintfStateMachine\_Private;
use type HTL\Pragma\Pragmas;

<<file: Pragmas(vec['PhaLinters', 'fixme:unused_variable'])>>

/**
 * Usage: hhvm bin/generate-engine-constant.hack > src/ENGINE_TEMPLATE.hack
 */
<<__EntryPoint>>
async function generate_template_constant_async()[defaults]: Awaitable<void> {
  $file = File\open_read_only(__FILE__);

  using ($file->closeWhenDisposed(), $file->tryLockx(File\LockType::SHARED)) {
    $contents = await $file->readAllAsync();
  }

  $halt = '__halt_compiler();';

  $halt_compiler_offset =
    Str\search_last($contents, $halt) as nonnull + Str\length($halt);

  echo Str\slice($contents, $halt_compiler_offset)
    |> Str\trim_right($$)
    |> _Private\string_export_pure($$)
    |> Str\format(
      "/** This project is unlicensed. No license has been granted. */\n".
      "namespace HTL\PrintfStateMachine;\n\n".
      "const string ENGINE_TEMPLATE = %s;\n",
      $$,
    );
}

/**
 * This code is dangling here, so it can get typechecked. This code is an
 * uninstantiated macro. `// @@magic(switch)` will be replaced with *your*
 * switch statement, finishing your state machine.
 */
// __halt_compiler();
function engine(
  string $old_format,
  vec<mixed> $old_args,
)[]: (string, vec<mixed>) {
  $new_format = '';
  $new_args = vec[];

  for ($percent = 0, $arg_i = 0, $unseen_part = 0; ; ) {
    $percent = \HH\Lib\Str\search($old_format, '%', $unseen_part);
    $new_format .= \HH\Lib\Str\slice(
      $old_format,
      $unseen_part,
      $percent is nonnull ? $percent - $unseen_part : null,
    );

    if ($percent is null) {
      $consumed_arg_count = \HH\Lib\C\count($old_args);
      invariant(
        $consumed_arg_count === $arg_i,
        'Arguments were not consumed correctly. %d arguments were provided, but %d were consumed',
        $consumed_arg_count,
        $arg_i,
      );
      return tuple($new_format, $new_args);
    }

    if ($old_format[$percent + 1] === '%') {
      $new_format .= '%%';
      $unseen_part = $percent + 2;
      continue;
    }

    $done = false;
    $state = 0;
    for ($char_i = $percent + 1; !$done; ++$char_i) {
      $arg = $old_args[$arg_i] ?? null;
      $char = \ord($old_format[$char_i] ?? '');
      // @@magic(switch)
    }

    $unseen_part = $char_i;
  }
}
