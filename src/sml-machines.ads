--  State machine with payload-carrying events, named guards and actions, and
--  an extended-state Context.  Guard/Action names are dispatched by the
--  Evaluate/Execute formals, keeping the transition table pure data and the
--  engine inlinable and SPARK-friendly.

generic
   type State is (<>);
   type Event_Kind is (<>);
   type Event (<>) is private;
   type Context is limited private;
   type Guard_Kind is (<>);
   type Action_Kind is (<>);
   with function Kind_Of (E : Event) return Event_Kind;
   with
     function Evaluate
       (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean;
   with procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event);
   --  Structured logging hooks, called with scalars (no message building
   --  in the engine).  Each defaults to a null procedure, so an instance
   --  that wants no logging passes nothing and the calls are eliminated
   --  at every -O level.
   with procedure On_Event (Evt : Event_Kind; From : State) is null;
   with procedure On_Guard (Guard : Guard_Kind; Passed : Boolean) is null;
   with procedure On_Action (Action : Action_Kind; From, To : State) is null;
   with procedure On_Unhandled (Evt : Event_Kind; From : State) is null;
package Sml.Machines with SPARK_Mode is

   type Transition is record
      From   : State;
      On     : Event_Kind;
      Guard  : Guard_Kind;
      Action : Action_Kind;
      To     : State;
   end record;

   type Transition_Table is array (Positive range <>) of Transition;

   type Completeness is (Partial, Total);
   type Unhandled_Policy is (Stay, Raise_Error, Go_To_Default);

   Unhandled_Event  : exception;
   Incomplete_Table : exception;

   --  Discriminated by its table length (Count).  Still indefinite, so every
   --  Machine must be initialised by Make; Count is exposed so a fixed-length
   --  array of them is possible (see Sml.Machines.Regions).
   type Machine (Count : Natural) is private;

   function State_Of (M : Machine) return State;

   --  Ghost views of a Machine's fixed configuration (everything but Current),
   --  so contracts can speak about the table, policy and default.  No run-time
   --  cost -- absent outside proof.
   function Table_Of (M : Machine) return Transition_Table
   with Ghost;
   function Policy_Of (M : Machine) return Unhandled_Policy
   with Ghost;
   function Default_Of (M : Machine) return State
   with Ghost;

   function Matches
     (T : Transition; From : State; K : Event_Kind) return Boolean
   is (T.From = From and then T.On = K);

   function Covers
     (Table : Transition_Table; S : State; K : Event_Kind) return Boolean
   is (for some T of Table => Matches (T, S, K));

   --  True when Table has a transition for every (State, Event_Kind) pair --
   --  the property Make enforces when Complete => Total.
   function Is_Total (Table : Transition_Table) return Boolean
   is (for all S in State =>
         (for all K in Event_Kind => Covers (Table, S, K)));

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine
   with
     Pre  => (if Complete = Total then Is_Total (Table)),
     Post =>
       State_Of (Make'Result) = Initial
       and then Make'Result.Count = Table'Length
       and then Table_Of (Make'Result) = Table
       and then Policy_Of (Make'Result) = On_Unhandled
       and then Default_Of (Make'Result) = Default;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   with Exceptional_Cases => (Unhandled_Event => True);

   --  Lower-level variant: fire the matching transition if its guard
   --  passes and report whether one did.  Applies NO unhandled policy and
   --  never raises, so a caller (a hierarchical or deferred-event layer)
   --  can decide what an unhandled event means -- route it to a parent,
   --  queue it, or drop it.
   procedure Process_Event
     (M       : in out Machine;
      Ctx     : in out Context;
      Evt     : Event;
      Handled : out Boolean)
   with
     Post =>
       Table_Of (M) = Table_Of (M'Old)
       and then Policy_Of (M) = Policy_Of (M'Old)
       and then Default_Of (M) = Default_Of (M'Old)
       and then (if not Handled
                 then State_Of (M) = State_Of (M'Old)
                 else
                   (for some T of Table_Of (M) =>
                      T.From = State_Of (M'Old)
                      and then T.On = Kind_Of (Evt)
                      and then T.To = State_Of (M)));

private

   type Machine (Count : Natural) is record
      Current      : State;
      On_Unhandled : Unhandled_Policy;
      Default      : State;
      Table        : Transition_Table (1 .. Count);
   end record;

   function State_Of (M : Machine) return State
   is (M.Current);

   function Table_Of (M : Machine) return Transition_Table
   is (M.Table);
   function Policy_Of (M : Machine) return Unhandled_Policy
   is (M.On_Unhandled);
   function Default_Of (M : Machine) return State
   is (M.Default);

end Sml.Machines;
