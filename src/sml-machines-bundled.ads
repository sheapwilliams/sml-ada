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
     Post =>
       State_Of (Make'Result) = Initial
       and then Table_Of (Make'Result.M) = Table
       and then Policy_Of (Make'Result.M) = On_Unhandled
       and then Default_Of (Make'Result.M) = Default;

   --  Deliver Evt to the bundled machine against its own Context.  The fixed
   --  configuration (table, policy, default) is preserved.  Like the other
   --  propagating layers, the precise raise trigger is inexpressible here (it
   --  forwards to the engine's 3-arg Process_Event; see the Reactive note), so
   --  the Exceptional_Cases stays => True.
   procedure Process_Event (Self : in out Instance; Evt : Event)
   with
     Post              =>
       Table_Of (Self.M) = Table_Of (Self.M'Old)
       and then Policy_Of (Self.M) = Policy_Of (Self.M'Old)
       and then Default_Of (Self.M) = Default_Of (Self.M'Old),
     Exceptional_Cases => (Unhandled_Event => True);

   --  Reporting overload: apply no unhandled policy, report whether a
   --  transition fired (mirrors the engine's lower-level Process_Event).
   --  Never raises: on Handled the new state is the target of a table
   --  transition out of the old state on this event, else it is unchanged.
   procedure Process_Event
     (Self : in out Instance; Evt : Event; Handled : out Boolean)
   with
     Post =>
       Table_Of (Self.M) = Table_Of (Self.M'Old)
       and then Policy_Of (Self.M) = Policy_Of (Self.M'Old)
       and then Default_Of (Self.M) = Default_Of (Self.M'Old)
       and then (if not Handled
                 then State_Of (Self.M) = State_Of (Self.M'Old)
                 else
                   (for some T of Table_Of (Self.M) =>
                      T.From = State_Of (Self.M'Old)
                      and then T.On = Kind_Of (Evt)
                      and then T.To = State_Of (Self.M)));

end Sml.Machines.Bundled;
