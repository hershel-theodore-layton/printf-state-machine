# Printf State Machine

_Generate HH\\FormatString&lt;T&gt; state machines._

This package uses a code generator to create state machines that process
`HH\FormatString<T>` and the arguments and the accompanying typesafety
interfaces. This is a `--dev` dependency. You don't need this generator in
production to use the state machines.

## Usage

You can chain together your own format string DSL in little to no time.
Start with `PrintfStateMachine\Factory::create()` and chain `->with...` methods.
Once your DSL is ready, invoke
`|> PrintfStateMachine\codegen($$, PrintfStateMachine\ENGINE_TEMPLATE)`. You will
get `Entities`, which are "just code". Put this code somewhere in a namespace
it won''t conflict with any other engines. Then create a typesafe caller.

```HACK
function your_format_function(
  \HH\FormatString<\YourNamespace\YourType> $format,
  mixed ... $args
)[]: (string, vec<mixed>) {
  return \YourNamespace\engine($format, $args);
}
```

This will transform your format and arguments according to the rules you've set
out in your factory.

## Use case

`HH\Lib\SQL\Query` has support for these specifiers:

| Specifier         | Effect                                 |
| ----------------: | :--------------------------------------|
| `%d  %f  %s`      | nullable int, float, and string        |
| `%=d %=f %=s`     | equality for int, float, and string    |
| `%C  %T`          | column and table names                 |
| `%Ld %Lf %Ls %LC` | list of int, float, string, and column |
| `%K`              | `/* comments */`                       |
| `%Q`              | nested Query objects                   |

You may very well want to add a strongly type `%N` for `TableAndColumnName`
to make sure that you never accidentally switch around a column name and a
user supplied value. Short of patching the Hack typechecker, or building a
very difficult to write linter that depends on type information, you'd need
a tool like this. Write a definition for 12 (excluding `%C` and `%T`) specifiers
and add `->withRewrite<TableAndColumnName>('N', 'C')`. The format and args were
typechecked by Hack.

I library will be published with these implementations.
