--  A ready-made structured tracer for Sml.Machines.  Instead of hand-rolling
--  the four On_* logging hooks, instantiate this with the same enums and pass
--  its procedures straight into a Sml.Machines instance.  Each processed event
--  becomes one line, named by the machine and written in the table's own DSL
--  layout, with each guard tagged True/False so a trace shows *why* a
--  transition did or did not fire:
--
--     sml<AUTH>: REFRESHING + E_REFRESH_OK (TOKEN_VALID=True) / PERSIST
--                --> AUTHENTICATED
--     sml<AUTH>: REFRESHING + E_REFRESH_OK (TOKEN_VALID=False)
--                -- blocked by guard (no transition)
--     sml<AUTH>: AUTHENTICATED + E_LOGOUT -- unhandled (no transition)
--
--  As with Operators, the trivial Always guard and Nothing action are named so
--  they can be omitted from the line as noise.  Output goes through the
--  Put_Line formal (Ada.Text_IO.Put_Line by default); pass a capturing
--  procedure to redirect it -- to a file, a ring buffer, or a test.
--
--     package Trace is new Sml.Tracing
--       (State, Event_Kind, Guard_Kind, Action_Kind,
--        Name => "AUTH", Always => Always, Nothing => Nothing);
--     package SM is new Sml.Machines
--       (..., On_Event => Trace.On_Event, On_Guard => Trace.On_Guard,
--        On_Action => Trace.On_Action, On_Unhandled => Trace.On_Unhandled);
--
--  A composed line spans two hooks (the event from On_Event, the endpoints
--  from On_Action), so the instance holds the in-progress line between them.
--  That state makes one instance good for one machine driven from one task at
--  a time -- the usual run-to-completion model.  It is a bounded buffer (the
--  Trace_State abstraction, no heap), keeping the tracer inside SPARK: a
--  guard note that would overflow Notes_Capacity is dropped from the line,
--  though a blocked guard still reports as blocked, never as unhandled.  The
--  hooks are proved free of run-time errors via the instance in Tracing_Proof.

with Ada.Text_IO;

generic
   type State is (<>);
   type Event_Kind is (<>);
   type Guard_Kind is (<>);
   type Action_Kind is (<>);
   Name : String := "";
   --  The trivial guard/action (as in Operators); each is omitted from the
   --  traced line so only meaningful guards and actions show.
   Always : Guard_Kind;
   Nothing : Action_Kind;
   --  Room for one line's guard notes; a note that would not fit is dropped.
   Notes_Capacity : Positive := 128;
   with procedure Put_Line (Item : String) is Ada.Text_IO.Put_Line;
package Sml.Tracing with
    SPARK_Mode,
    Abstract_State => Trace_State,
    Initializes    => Trace_State
is

   procedure On_Event (Evt : Event_Kind; From : State);
   procedure On_Guard (Guard : Guard_Kind; Passed : Boolean);
   procedure On_Action (Action : Action_Kind; From, To : State);
   procedure On_Unhandled (Evt : Event_Kind; From : State);

end Sml.Tracing;
