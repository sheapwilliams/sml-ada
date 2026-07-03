--  The declarations every proof package would otherwise repeat: a record
--  Event wrapping its kind, an empty Context, single-literal Always/Nothing
--  guard and action sets with their trivial Evaluate/Execute, and the
--  Sml.Machines instance over them.  A proof package instantiates this with
--  its State/Event_Kind enums and adds only the layer under proof.

with Sml.Machines;

generic
   type State is (<>);
   type Event_Kind is (<>);
package Proof_Scaffold with SPARK_Mode is

   type Event is record
      Kind : Event_Kind;
   end record;

   type Context is null record;
   type Guard_Kind is (Always);
   type Action_Kind is (Nothing);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;

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

end Proof_Scaffold;
