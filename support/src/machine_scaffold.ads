--  The trivial fixture kit shared by the unit tests and the SPARK proof
--  harnesses: a record Event wrapping its kind, an empty Context,
--  single-literal Always/Nothing guard and action sets with their trivial
--  Evaluate/Execute, and the Sml.Machines instance over them.  Instantiate
--  with the State/Event_Kind enums and add only the layer-specific parts.

with Sml.Machines;

generic
   type State is (<>);
   type Event_Kind is (<>);
package Machine_Scaffold with SPARK_Mode is

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   --  For Deferring instantiations: the kind is the whole event here, so
   --  rebuilding one from the other is exact.
   function Rebuild (E : Event_Kind) return Event
   is ((Kind => E));

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   with Post => Evaluate'Result;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event)
   is null;

   package SM is new
     Sml.Machines
       (State       => State,
        Event_Kind  => Event_Kind,
        Event       => Event,
        Context     => Context,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Kind_Of     => Kind_Of,
        Evaluate    => Evaluate,
        Execute     => Execute);

   --  The state a freshly made machine reports -- its Initial, by Make's Post.
   --  Lets each proof harness' Run collapse to a one-line pure function that
   --  anchors that Post (the whole point of those Run functions).
   function Started (Table : SM.Transition_Table; Initial : State) return State
   is (SM.State_Of (SM.Make (Table, Initial)));

end Machine_Scaffold;
