/** printf-state-machine is MIT licensed, see /LICENSE. */
namespace HTL\PrintfStateMachine;

/**
 * You could implement this on top of type-visitor and
 * static-type-assertion-code-generator, but you don't "have" to.
 * This type is interfaced out, so that the base package does not depend on
 * these libraries.
 */
interface TypeAssertionGenerator {
  public function forType<reify T>()[]: (this, TypeAssertionExpression);
  public function getTypename<reify T>()[]: HackType;
  public function generateCasts()[]: Entities;
}
