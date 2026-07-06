--  Bundle a Machine with its Context so events carry just the event -- the
--  Boost.SML style, where the extended state is bound to the machine instead
--  of threaded through every call.  Opt-in: the core engine keeps Context
--  external (which is what lets Composite and Regions share one Context across
--  machines); this layer is for a single, self-contained machine that owns its
--  own Context.
--
--     package B is new SM.Bundled;
--     Obj : B.Instance := B.Make (Table, Initial => Idle);
--     B.Process_Event (Obj, (Kind => Go));   --  no Context argument
--     ... Obj.Ctx ...                         --  the extended state, in place

generic
package Sml.Machines.Bundled with SPARK_Mode is

   --  A Machine and its Context in one object.  Both components stay visible,
   --  so the Context (the extended state) is directly readable and writable,
   --  as it is when passed explicitly.  Limited exactly when Context is.
   type Instance (Count : Natural) is record
      M   : Machine (Count);
      Ctx : Context;
   end record;

   function State_Of (Self : Instance) return State
   is (State_Of (Self.M));

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Instance
   with
     Pre  => (if Complete = Total then Is_Total (Table)),
     Post => State_Of (Make'Result) = Initial;

   --  Deliver Evt to the bundled machine against its own Context.
   procedure Process_Event (Self : in out Instance; Evt : Event)
   with Exceptional_Cases => (Unhandled_Event => True);

   --  Reporting overload: apply no unhandled policy, report whether a
   --  transition fired (mirrors the engine's lower-level Process_Event).
   procedure Process_Event
     (Self : in out Instance; Evt : Event; Handled : out Boolean);

end Sml.Machines.Bundled;
