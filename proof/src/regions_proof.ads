--  A concrete Sml.Machines.Regions instance so gnatprove verifies the broadcast
--  layer: Broadcast and All_In are proved free of run-time errors, and
--  Broadcast is proved to propagate only Unhandled_Event.  (As elsewhere, a
--  proof function does not call Broadcast, since it could raise by design.)

with Machine_Scaffold;
with Sml.Machines.Regions;

package Regions_Proof
  with SPARK_Mode
is

   type State is (Off, On);
   type Event_Kind is (E_Toggle);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   package Reg is new SM.Regions (Count => 2);

   --  An empty region set is vacuously all-Off; exercises All_In without
   --  constructing a machine (whose discriminant check is not the point here).
   function Run return Boolean
   with Post => Run'Result;

end Regions_Proof;
