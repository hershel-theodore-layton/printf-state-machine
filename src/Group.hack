/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{C, Str};

final class Group {
  private function __construct(private vec<Handler> $handlers)[] {}

  public static function create()[]: this {
    return new static(vec[]);
  }

  public function getHandlers()[]: vec<Handler> {
    return $this->handlers;
  }

  public function with(Handler $handler)[]: this {
    $handlers = $this->handlers;
    $new_prefix = $handler->getSpecifierText();

    $collision = C\find(
      $handlers,
      $h ==> $h->getSpecifierText()
        |> Str\starts_with($$, $new_prefix) || Str\starts_with($new_prefix, $$),
    );

    invariant(
      $collision is null,
      "Could not add '%%%s' because it is ambiguous with '%%%s'",
      $new_prefix,
      $collision->getSpecifierText(),
    );

    $handlers[] = $handler;
    return new static($handlers);
  }
}
