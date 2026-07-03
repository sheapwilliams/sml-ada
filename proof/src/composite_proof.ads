--  A concrete Sml.Machines.Composite instance so gnatprove verifies the
--  child-first dispatch free of run-time errors (propagating only the parent's
--  Unhandled_Event).  The child here is a trivial "never handles" stand-in --
--  enough to analyse Process's body; real delegation is exercised by the tests.

with Machine_Scaffold;
with Sml.Machines.Composite;

package Composite_Proof
  with SPARK_Mode
is

   type State is (Off, On);
   type Event_Kind is (E_Power);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   procedure No_Child
     (Ctx : in out Context; Evt : Event; Handled : out Boolean);

   package Comp is new SM.Composite (Process_Child => No_Child);

   function Run return State
   with Post => Run'Result = Off;

end Composite_Proof;
