pragma Ada_2022;

--  A concrete Sml.Machines.Bundled instance so gnatprove verifies the layer:
--  Process_Event is proved free of run-time errors (and propagates only
--  Unhandled_Event), and Make's Post (State_Of (Make'Result) = Initial) holds.
--  Run exercises Make + State_Of on the bundled object.

with Sml.Machines;
with Sml.Machines.Bundled;

package Bundled_Proof
  with SPARK_Mode
is

   type State is (Locked, Unlocked);
   type Event_Kind is (E_Coin, E_Push);

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

   package B is new SM.Bundled;

   function Run return State
   with Post => Run'Result = Locked;

end Bundled_Proof;
