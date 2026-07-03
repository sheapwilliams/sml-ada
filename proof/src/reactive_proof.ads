--  A concrete Sml.Machines.Reactive instance so gnatprove verifies the
--  run-to-completion loop free of run-time errors (and propagating only
--  Unhandled_Event).  Run only exercises Make, as elsewhere.

with Machine_Scaffold;
with Sml.Machines.Reactive;

package Reactive_Proof
  with SPARK_Mode
is

   type State is (Idle, Dialing, Connected);
   type Event_Kind is (E_Dial, E_Connect);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   function Has_Entry_Event (S : State) return Boolean
   is (S = Dialing);

   --  Only Dialing has an entry event (see Has_Entry_Event); the other arms
   --  are never consulted, so their value is a placeholder.
   function Entry_Event (S : State) return Event
   is ((Kind => (if S = Dialing then E_Connect else E_Dial)));

   package RC is new
     SM.Reactive
       (Has_Entry_Event => Has_Entry_Event,
        Entry_Event     => Entry_Event);

   function Run return State
   with Post => Run'Result = Idle;

end Reactive_Proof;
