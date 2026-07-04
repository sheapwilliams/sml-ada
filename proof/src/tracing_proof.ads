--  A concrete Sml.Tracing instance, wired into its own engine instance, so
--  gnatprove verifies the tracer: the four hooks are proved free of run-time
--  errors (the bounded note buffer's arithmetic in particular), and the
--  engine instance stays proved with stateful hooks attached -- the composed
--  shape a traced machine actually runs.  Run only anchors Make's Post, as
--  elsewhere.

with Machine_Scaffold;
with Sml.Machines;
with Sml.Tracing;

package Tracing_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

   package Scaffold is new Machine_Scaffold (State, Event_Kind);
   use Scaffold;

   --  The sink counts lines (saturating) rather than printing: the proof is
   --  about the hooks, not the text, but a null sink would leave the emitting
   --  hooks with no effect at all, which gnatprove rightly flags.
   Lines : Natural := 0;

   procedure Count (Item : String);

   package Trace is new
     Sml.Tracing
       (State       => State,
        Event_Kind  => Event_Kind,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Name        => "PROOF",
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Count);

   --  The scaffold's kit in a direct Sml.Machines instantiation, as its SM
   --  instance has no hooks.
   package TSM is new
     Sml.Machines
       (State        => State,
        Event_Kind   => Event_Kind,
        Event        => Event,
        Context      => Context,
        Guard_Kind   => Guard_Kind,
        Action_Kind  => Action_Kind,
        Kind_Of      => Kind_Of,
        Evaluate     => Evaluate,
        Execute      => Execute,
        On_Event     => Trace.On_Event,
        On_Guard     => Trace.On_Guard,
        On_Action    => Trace.On_Action,
        On_Unhandled => Trace.On_Unhandled);

   function Run return State
   with Post => Run'Result = Locked;

end Tracing_Proof;
