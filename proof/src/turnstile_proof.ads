--  A concrete instance so gnatprove has something to verify (it does not
--  analyse uninstantiated generics).  It instantiates the engine (via
--  Machine_Scaffold) and its operators for a turnstile and proves the engine is
--  free of run-time errors, plus that Make establishes the initial state (its
--  Post chains through to Run's result).

with Machine_Scaffold;
with Sml.Machines.Operators;

package Turnstile_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);

   function Run return State
   with Post => Run'Result = Locked;

   --  Push is unhandled in Locked, so the Stay policy leaves the turnstile put.
   function Push_In_Locked return State
   with Post => Push_In_Locked'Result = Locked;

   --  An *exact* result, provable via the 4-arg Process_Event's Handled-
   --  completeness: Coin is enabled in Locked (Always holds), so it must be
   --  handled, and the one matching row goes to Unlocked.
   function Coin_In_Locked return State
   with Post => Coin_In_Locked'Result = Unlocked;

end Turnstile_Proof;
