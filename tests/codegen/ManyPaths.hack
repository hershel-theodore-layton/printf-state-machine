/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine\Tests\ManyPaths;

use type HTL\Pragma\Pragmas;
<<file:
  Pragmas(
    vec['PhaLinters', 'fixme:camel_cased_methods_underscored_functions'],
    vec['PhaLinters', 'fixme:unused_variable'],
  )>>

interface ManyPaths {
  public function format_0x25()[]: string;
  public function format_0x3f()[]: ManyPathsWithQuestion;
  public function format_a()[]: ManyPathsWithLowerA;
  public function format_b()[]: ManyPathsWithLowerB;
  public function format_c()[]: ManyPathsWithLowerC;
}

interface ManyPathsWithQuestion {
  public function format_a()[]: ManyPathsWithQuestionWithLowerA;
  public function format_b()[]: ManyPathsWithQuestionWithLowerB;
  public function format_c()[]: ManyPathsWithQuestionWithLowerC;
}

interface ManyPathsWithQuestionWithLowerA {
  public function format_b()[]: ManyPathsWithQuestionWithLowerAWithLowerB;
  public function format_c()[]: ManyPathsWithQuestionWithLowerAWithLowerC;
}

interface ManyPathsWithQuestionWithLowerAWithLowerB {
  public function format_c(?int $_)[]: string;
}

interface ManyPathsWithQuestionWithLowerAWithLowerC {
  public function format_b(?bool $_)[]: string;
}

interface ManyPathsWithQuestionWithLowerB {
  public function format_a()[]: ManyPathsWithQuestionWithLowerBWithLowerA;
  public function format_c()[]: ManyPathsWithQuestionWithLowerBWithLowerC;
}

interface ManyPathsWithQuestionWithLowerBWithLowerA {
  public function format_c(?string $_)[]: string;
}

interface ManyPathsWithQuestionWithLowerBWithLowerC {
  public function format_a(?float $_)[]: string;
}

interface ManyPathsWithQuestionWithLowerC {
  public function format_a()[]: ManyPathsWithQuestionWithLowerCWithLowerA;
  public function format_b()[]: ManyPathsWithQuestionWithLowerCWithLowerB;
}

interface ManyPathsWithQuestionWithLowerCWithLowerA {
  public function format_b(?arraykey $_)[]: string;
}

interface ManyPathsWithQuestionWithLowerCWithLowerB {
  public function format_a(?num $_)[]: string;
}

interface ManyPathsWithLowerA {
  public function format_b()[]: ManyPathsWithLowerAWithLowerB;
  public function format_c()[]: ManyPathsWithLowerAWithLowerC;
}

interface ManyPathsWithLowerAWithLowerB {
  public function format_c(int $_)[]: string;
}

interface ManyPathsWithLowerAWithLowerC {
  public function format_b(bool $_)[]: string;
}

interface ManyPathsWithLowerB {
  public function format_a()[]: ManyPathsWithLowerBWithLowerA;
  public function format_c()[]: ManyPathsWithLowerBWithLowerC;
}

interface ManyPathsWithLowerBWithLowerA {
  public function format_c(string $_)[]: string;
}

interface ManyPathsWithLowerBWithLowerC {
  public function format_a(float $_)[]: string;
}

interface ManyPathsWithLowerC {
  public function format_a()[]: ManyPathsWithLowerCWithLowerA;
  public function format_b()[]: ManyPathsWithLowerCWithLowerB;
}

interface ManyPathsWithLowerCWithLowerA {
  public function format_b(arraykey $_)[]: string;
}

interface ManyPathsWithLowerCWithLowerB {
  public function format_a(num $_)[]: string;
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
            case 0x3f: // '?' -> ManyPathsWithQuestion
              $state = 2;
              break;
            case 0x61: // 'a' -> ManyPathsWithLowerA
              $state = 3;
              break;
            case 0x62: // 'b' -> ManyPathsWithLowerB
              $state = 4;
              break;
            case 0x63: // 'c' -> ManyPathsWithLowerC
              $state = 5;
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
            case 0x61: // '?a' -> ManyPathsWithQuestionWithLowerA
              $state = 6;
              break;
            case 0x62: // '?b' -> ManyPathsWithQuestionWithLowerB
              $state = 7;
              break;
            case 0x63: // '?c' -> ManyPathsWithQuestionWithLowerC
              $state = 8;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 3:
          switch ($char) {
            case 0x62: // 'ab' -> ManyPathsWithLowerAWithLowerB
              $state = 15;
              break;
            case 0x63: // 'ac' -> ManyPathsWithLowerAWithLowerC
              $state = 16;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 4:
          switch ($char) {
            case 0x61: // 'ba' -> ManyPathsWithLowerBWithLowerA
              $state = 17;
              break;
            case 0x63: // 'bc' -> ManyPathsWithLowerBWithLowerC
              $state = 18;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 5:
          switch ($char) {
            case 0x61: // 'ca' -> ManyPathsWithLowerCWithLowerA
              $state = 19;
              break;
            case 0x62: // 'cb' -> ManyPathsWithLowerCWithLowerB
              $state = 20;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 6:
          switch ($char) {
            case 0x62: // '?ab' -> ManyPathsWithQuestionWithLowerAWithLowerB
              $state = 9;
              break;
            case 0x63: // '?ac' -> ManyPathsWithQuestionWithLowerAWithLowerC
              $state = 10;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 7:
          switch ($char) {
            case 0x61: // '?ba' -> ManyPathsWithQuestionWithLowerBWithLowerA
              $state = 11;
              break;
            case 0x63: // '?bc' -> ManyPathsWithQuestionWithLowerBWithLowerC
              $state = 12;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 8:
          switch ($char) {
            case 0x61: // '?ca' -> ManyPathsWithQuestionWithLowerCWithLowerA
              $state = 13;
              break;
            case 0x62: // '?cb' -> ManyPathsWithQuestionWithLowerCWithLowerB
              $state = 14;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 9:
          switch ($char) {
            case 0x63: // '?abc'
              $new_format .= '%?abc';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 10:
          switch ($char) {
            case 0x62: // '?acb'
              $new_format .= '%?acb';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 11:
          switch ($char) {
            case 0x63: // '?bac'
              $new_format .= '%?bac';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 12:
          switch ($char) {
            case 0x61: // '?bca'
              $new_format .= '%?bca';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 13:
          switch ($char) {
            case 0x62: // '?cab'
              $new_format .= '%?cab';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 14:
          switch ($char) {
            case 0x61: // '?cba'
              $new_format .= '%?cba';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 15:
          switch ($char) {
            case 0x63: // 'abc'
              $new_format .= '%abc';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 16:
          switch ($char) {
            case 0x62: // 'acb'
              $new_format .= '%acb';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 17:
          switch ($char) {
            case 0x63: // 'bac'
              $new_format .= '%bac';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 18:
          switch ($char) {
            case 0x61: // 'bca'
              $new_format .= '%bca';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 19:
          switch ($char) {
            case 0x62: // 'cab'
              $new_format .= '%cab';
              $new_args[] = $arg;
              ++$arg_i;
              $done = true;
              break;
            default:
              invariant_violation('Unexpected 0x%x at %d', $char, $char_i);
          }
          break;

        case 20:
          switch ($char) {
            case 0x61: // 'cba'
              $new_format .= '%cba';
              $new_args[] = $arg;
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
