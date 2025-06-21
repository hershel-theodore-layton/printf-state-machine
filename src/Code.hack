/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

/** @see `HTL\PrintfStateMachine\code` */
newtype Code as string = string;

/** @see `HTL\PrintfStateMachine\argument_list` */
newtype ArgumentList as Code = Code;

/** @see `HTL\PrintfStateMachine\case_block` */
newtype CaseBlock as Code = Code;

/** @see `HTL\PrintfStateMachine\entities` */
newtype Entities as Code = Code;

/** @see `HTL\PrintfStateMachine\hack_type` */
newtype HackType as Code = Code;

/** @see `HTL\PrintfStateMachine\method_name` */
newtype MethodName as Code = Code;

/** @see `HTL\PrintfStateMachine\sequence_transform` */
newtype SequenceTransform as Code = Code;

/** @see `HTL\PrintfStateMachine\type_assertion_expression` */
newtype TypeAssertionExpression as Code = Code;

/** @see `HTL\PrintfStateMachine\value_transform` */
newtype ValueTransform as Code = Code;

/**
 * Some indiscriminate code block. This tagged type indicates a code-snippet.
 */
function code(string $string)[]: Code {
  return $string;
}

/**
 * The parameter list of a function (without the parens).
 * For this function, it would be `string $string`, not `(string $string)`.
 */
function argument_list(string $string)[]: ArgumentList {
  return $string;
}

/**
 * One or more statements used when generating code for a case block.
 * Generating this block has limited backwards compatibility guarantees.
 *
 * ## ABI
 *
 * The words `mutable` means: may be reassigned and modified. Readonly means the
 * inverse. This is not Hack's concept of `readonly` objects.
 *
 * The following variables are in scope:
 *  - `$old_format readonly string`, the original, unmodified `Pack->getFormat()`
 *  - `$old_args readonly vec<mixed>`, the original, unmodified `Pack->getArguments()`
 *  - `$new_format mutable string`, the partially constructed format used for
 *    constructing the return value `Pack { $new_format, $new_args }`.
 *  - `$new_args mutable vec<mixed>`, the partially constructed arguments used
 *    for constructed the return value `Pack { $new_format, $new_args }`.
 *  - `$percent readonly int`, the index of the `%` sign in `$old_format` of the
 *    specifier you are processing right now.
 *  - `$arg_i mutable int`, the index into the `$old_args` vec that points at
 *    the argument you are currently processing (if any).
 *  - `$unseen_part private readonly int`, do not use.
 *  - `$done mutable bool`, is false when entering your case.
 *  - `$state private readonly int`, do not use.
 *  - `$char_i mutable int`, the index into the `$old_format` string pointing
 *    to the character currently being consumed.
 *  - `$arg mutable mixed`, the argument being processed, or `null` if the are
 *    no arguments are left.
 *  - `$char mutable uint8`, the value `\ord($old_format[$char_i] ?? '')`.
 *
 * ## Behavior
 * 
 * When your case block is entered, you may process either zero or one arguments.
 * You can find your argument in `$arg`. If you have consumed your argument, you
 * must advance `$arg_i` by one (`++$arg_i;`). You may append any number of
 * arguments to the `$new_args` vec (including zero). You must emit the exact
 * amount of specifiers that matches the amount of arguments pushed to `$new_format`.
 * You may process any number of additional characters from the `$old_format`
 * string (including zero). If you consume `n` additional characters, you must
 * advance `$char_i` by `n` (`$char_i += n;`). You must end your case block by
 * setting `$done` to true and a `break;` statement.
 */
function case_block(string $string)[]: CaseBlock {
  return $string;
}

/**
 * Zero or more classish, const, function, or type entities.
 */
function entities(string $string)[]: Entities {
  return $string;
}

/**
 * A typename in Hack that uses fully qualified names.
 * Examples include `vec<int>`, `dict<string, ?\YourNamespace\SomeType>`. 
 */
function hack_type(string $string)[]: HackType {
  return $string;
}

/**
 * An internal type, that holds a `format_xyzzy` method name.
 */
function method_name(string $string)[]: MethodName {
  return $string;
}

/**
 * A segment of code that is the RHS of a `|>` pipe expression.
 * The type of the `$$` variable is the type of the argument to the format method.
 * The value resulting from this expression replaces the specifier (including the `%`)
 * from the old format string.
 */
function sequence_transform(string $string)[]: SequenceTransform {
  return $string;
}

/**
 * A segment of code that is the RHS of a `|>` pipe expression.
 * The type of the `$$` variable is mixed. The value resulting from this expression
 * must be of the type of the argument of the format method.
 */
function type_assertion_expression(string $string)[]: TypeAssertionExpression {
  return $string;
}

/**
 * A segment of code that is the RHS of a `|>` pipe expression.
 * The type of the `$$` variable is the type of the argument to the format method.
 * The value resulting from this expression is pushed into the new_args array.
 */
function value_transform(string $string)[]: ValueTransform {
  return $string;
}
