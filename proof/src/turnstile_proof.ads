--  A concrete instance so gnatprove has something to verify (it does not
--  analyse uninstantiated generics).  It instantiates the engine (via
--  Proof_Scaffold) and its operators for a turnstile and proves the engine is
--  free of run-time errors, plus that Make establishes the initial state (its
--  Post chains through to Run's result).

with Proof_Scaffold;
with Sml.Machines.Operators;

package Turnstile_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

   package Scaffold is new Proof_Scaffold (State, Event_Kind);
   use Scaffold;

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);

   function Run return State
   with Post => Run'Result = Locked;

end Turnstile_Proof;
