/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests\Coalesce;

use type HTL\Pragma\Pragmas;
<<file:
  Pragmas(
    vec['PhaLinters', 'fixme:camel_cased_methods_underscored_functions'],
    vec['PhaLinters', 'fixme:unused_variable'],
  )>>

interface Coalesce {
  public function format_0x25()[]: string;
  public function format_0x3f()[]: CoalesceWithQuestion;
}

interface CoalesceWithQuestion {
  public function format_s(?string $_)[]: string;
}

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
      switch ($state) {
        case 0:
          switch ($char) {
            case 0x25: // '%' -> string
              $state = 1;
              break;
            case 0x3f: // '?' -> CoalesceWithQuestion
              $state = 2;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 1:
          switch ($char) {

            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 2:
          switch ($char) {
            case 0x73: // '?s'
              $arg = $arg |> cast_generated_dcd6916a0daf20dbd3dc4622($$);
              $new_format .= '%s';
              $new_args[] = $arg |> $$ is null ? null : \HH\Lib\Str\uppercase($$);
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;
        default:
          invariant_violation('unreachable');
      }
    }

    $unseen_part = $char_i;
  }
}

function cast_generated_dcd6916a0daf20dbd3dc4622(mixed $htl_untyped_variable)[]: ?string { return $htl_untyped_variable as ?string; }
