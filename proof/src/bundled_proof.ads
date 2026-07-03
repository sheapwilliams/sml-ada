--  A concrete Sml.Machines.Bundled instance so gnatprove verifies the layer:
--  Process_Event is proved free of run-time errors (and propagates only
--  Unhandled_Event), and Make's Post (State_Of (Make'Result) = Initial) holds.
--  Run exercises Make + State_Of on the bundled object.

with Proof_Scaffold;
with Sml.Machines.Bundled;

package Bundled_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

   package Scaffold is new Proof_Scaffold (State, Event_Kind);
   use Scaffold;

   package B is new SM.Bundled;

   function Run return State
   with Post => Run'Result = Locked;

end Bundled_Proof;
