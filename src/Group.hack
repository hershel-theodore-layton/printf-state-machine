/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

use namespace HH\Lib\{C, Str};

final class Group {
  private function __construct(private dict<string, Handler> $handlers)[] {}

  public static function create()[]: this {
    return new static(dict[]);
  }

  public function getHandlers()[]: vec<Handler> {
    return vec($this->handlers);
  }

  public function has(string $specifier_text)[]: bool {
    return C\contains_key($this->handlers, $specifier_text);
  }

  public function with(Handler $handler)[]: this {
    $handlers = $this->handlers;
    $new_prefix = $handler->getSpecifierText();

    if (C\contains_key($handlers, $handler->getSpecifierText())) {
      $handlers[$handler->getSpecifierText()] = $handler;
      return new static($handlers);
    }

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

    $handlers[$handler->getSpecifierText()] = $handler;
    return new static($handlers);
  }

  public function rename(string $from, string $to)[]: this {
    $handlers = $this->handlers;

    $handler = $handlers[$from] ?? null;
    invariant(
      $handler is nonnull,
      'Could not rename handler %s, no such handler exists.',
      $from,
    );

    unset($handlers[$from]);
    $handlers[$to] = $handler->withSpecifierText($to);

    return new static($handlers);
  }

  public function without(string $specifier_text)[]: this {
    invariant(
      $this->has($specifier_text),
      'This Group did not have a specifier %s',
      $specifier_text,
    );

    $handlers = $this->handlers;
    unset($handlers[$specifier_text]);
    return new static($handlers);
  }
}
