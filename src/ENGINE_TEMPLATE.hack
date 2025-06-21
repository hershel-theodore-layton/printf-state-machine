/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

const string ENGINE_TEMPLATE = '
function engine(
  string $old_format,
  vec<mixed> $old_args,
)[]: (string, vec<mixed>) {
  $new_format = \'\';
  $new_args = vec[];

  for ($percent = 0, $arg_i = 0, $unseen_part = 0; ; ) {
    $percent = \\HH\\Lib\\Str\\search($old_format, \'%\', $unseen_part);
    $new_format .= \\HH\\Lib\\Str\\slice(
      $old_format,
      $unseen_part,
      $percent is nonnull ? $percent - $unseen_part : null,
    );

    if ($percent is null) {
      $consumed_arg_count = \\HH\\Lib\\C\\count($old_args);
      invariant(
        $consumed_arg_count === $arg_i,
        \'Arguments were not consumed correctly. %d arguments were provided, but %d were consumed\',
        $consumed_arg_count,
        $arg_i,
      );
      return tuple($new_format, $new_args);
    }

    if ($old_format[$percent + 1] === \'%\') {
      $new_format .= \'%%\';
      $unseen_part = $percent + 2;
      continue;
    }

    $done = false;
    $state = 0;
    for ($char_i = $percent + 1; !$done; ++$char_i) {
      $arg = $old_args[$arg_i] ?? null;
      $char = \\ord($old_format[$char_i] ?? \'\');
      // @@magic(switch)
    }

    $unseen_part = $char_i;
  }
}';
