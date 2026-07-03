--  A concrete Sml.Machines.Deferring instance so gnatprove verifies the queue:
--  Post and the internal drain are proved free of run-time errors (and Post
--  propagates only Deferral_Overflow).  Run only exercises Make.

with Machine_Scaffold;
with Sml.Machines.Deferring;

package Deferring_Proof
  with SPARK_Mode
is

   type State is (Stopped, Playing, Paused);
   type Event_Kind is (E_Play, E_Pause, E_Stop);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   function Deferred (S : State; E : Event_Kind) return Boolean
   is (S = Stopped and then E = E_Pause);

   package Def is new SM.Deferring (Deferred => Deferred, Rebuild => Rebuild);

   function Run return State
   with Post => Run'Result = Stopped;

end Deferring_Proof;
