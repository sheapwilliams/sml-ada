with AUnit.Assertions;      use AUnit.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Sml.Machines;
with Sml.Tracing;

package body Sml_Tracing_Tests is

   use AUnit.Test_Cases.Registration;

   --  A tiny auth handshake: REFRESHING waits for a refresh result.  A valid
   --  token authenticates (guarded, with an action); an explicit failure event
   --  drops to FAILED (trivial guard/action).  Enough shape to exercise a
   --  taken transition, a guard-blocked one, and an unhandled one.
   type St is (Refreshing, Authenticated, Failed);
   type Ev is (E_Refresh_Ok, E_Refresh_Fail);

   type Evt_T is record
      Kind  : Ev;
      Valid : Boolean := True;
   end record;

   type Ctx_T is null record;
   type G is (Always, Token_Valid);
   type A is (Nothing, Persist);

   function Kind_Of (E : Evt_T) return Ev
   is (E.Kind);

   function Evaluate (Guard : G; C : Ctx_T; E : Evt_T) return Boolean is
      pragma Unreferenced (C);
   begin
      return
        (case Guard is
           when Always      => True,
           when Token_Valid => E.Valid);
   end Evaluate;

   procedure Execute (Act : A; C : in out Ctx_T; E : Evt_T) is null;

   --  Capture the tracer's output instead of printing it, so a test can
   --  assert on the exact lines produced.
   Log : Unbounded_String;

   procedure Capture (Item : String) is
   begin
      Append (Log, Item & ASCII.LF);
   end Capture;

   function Logged (Line : String) return Boolean
   is (Index (Log, Line) > 0);

   package Trace is new
     Sml.Tracing
       (State       => St,
        Event_Kind  => Ev,
        Guard_Kind  => G,
        Action_Kind => A,
        Name        => "AUTH",
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Capture);

   --  A second tracer with room for no note at all, pinning the bounded
   --  buffer's saturation: the note text is dropped, the diagnosis is not.
   package Tiny is new
     Sml.Tracing
       (State          => St,
        Event_Kind     => Ev,
        Guard_Kind     => G,
        Action_Kind    => A,
        Name           => "TINY",
        Always         => Always,
        Nothing        => Nothing,
        Notes_Capacity => 4,
        Put_Line       => Capture);

   package SM is new
     Sml.Machines
       (State        => St,
        Event_Kind   => Ev,
        Event        => Evt_T,
        Context      => Ctx_T,
        Guard_Kind   => G,
        Action_Kind  => A,
        Kind_Of      => Kind_Of,
        Evaluate     => Evaluate,
        Execute      => Execute,
        On_Event     => Trace.On_Event,
        On_Guard     => Trace.On_Guard,
        On_Action    => Trace.On_Action,
        On_Unhandled => Trace.On_Unhandled);
   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Refreshing, E_Refresh_Ok,   Token_Valid, Persist, Authenticated),
      (Refreshing, E_Refresh_Fail, Always,      Nothing, Failed)];
   --!format on

   procedure Test_Taken_Transition
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Refreshing);
      C : Ctx_T;
   begin
      Log := Null_Unbounded_String;
      Process_Event (M, C, (Kind => E_Refresh_Ok, Valid => True));
      Assert
        (Logged
           ("sml<AUTH>: REFRESHING + E_REFRESH_OK (TOKEN_VALID=True)"
            & " / PERSIST --> AUTHENTICATED"),
         "taken transition names the machine, the guard truth and the"
         & " action in table layout -- got: "
         & To_String (Log));
   end Test_Taken_Transition;

   procedure Test_Trivial_Guard_And_Action_Suppressed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Refreshing);
      C : Ctx_T;
   begin
      Log := Null_Unbounded_String;
      Process_Event (M, C, (Kind => E_Refresh_Fail, Valid => True));
      Assert
        (Logged ("sml<AUTH>: REFRESHING + E_REFRESH_FAIL --> FAILED"),
         "the Always guard and Nothing action are omitted as noise -- got: "
         & To_String (Log));
   end Test_Trivial_Guard_And_Action_Suppressed;

   procedure Test_Guard_Blocked (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Refreshing);
      C : Ctx_T;
   begin
      Log := Null_Unbounded_String;
      Process_Event (M, C, (Kind => E_Refresh_Ok, Valid => False));
      Assert
        (Logged
           ("sml<AUTH>: REFRESHING + E_REFRESH_OK (TOKEN_VALID=False)"
            & " -- blocked by guard (no transition)"),
         "a failed guard shows why nothing fired -- got: " & To_String (Log));
      Assert (State_Of (M) = Refreshing, "and the machine did not move");
   end Test_Guard_Blocked;

   procedure Test_Unhandled (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      M : Machine := Make (Table, Initial => Authenticated);
      C : Ctx_T;
   begin
      Log := Null_Unbounded_String;
      Process_Event (M, C, (Kind => E_Refresh_Ok, Valid => True));
      Assert
        (Logged
           ("sml<AUTH>: AUTHENTICATED + E_REFRESH_OK"
            & " -- unhandled (no transition)"),
         "no matching row traces as unhandled -- got: " & To_String (Log));
   end Test_Unhandled;

   procedure Test_Note_Overflow_Dropped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Log := Null_Unbounded_String;
      --  Drive the hooks directly, in the order the engine calls them for a
      --  guard-blocked event.
      Tiny.On_Event (E_Refresh_Ok, Refreshing);
      Tiny.On_Guard (Token_Valid, False);
      Tiny.On_Unhandled (E_Refresh_Ok, Refreshing);
      Assert
        (Logged
           ("sml<TINY>: REFRESHING + E_REFRESH_OK"
            & " -- blocked by guard (no transition)"),
         "an over-capacity note is dropped, the blocked wording kept"
         & " -- got: "
         & To_String (Log));
      Assert
        (not Logged ("TOKEN_VALID"),
         "the dropped note leaves no partial text");
   end Test_Note_Overflow_Dropped;

   procedure Test_Multiple_Guard_Notes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Log := Null_Unbounded_String;
      Trace.On_Event (E_Refresh_Ok, Refreshing);
      Trace.On_Guard (Token_Valid, False);
      Trace.On_Guard (Token_Valid, False);
      Trace.On_Unhandled (E_Refresh_Ok, Refreshing);
      Assert
        (Logged
           ("sml<AUTH>: REFRESHING + E_REFRESH_OK"
            & " (TOKEN_VALID=False) (TOKEN_VALID=False)"
            & " -- blocked by guard (no transition)"),
         "each failing guard's verdict lands in the one line -- got: "
         & To_String (Log));
   end Test_Multiple_Guard_Notes;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Taken_Transition'Access,
         "Taken transition: named, table-layout line with guard truth");
      Register_Routine
        (T,
         Test_Trivial_Guard_And_Action_Suppressed'Access,
         "Always guard and Nothing action are suppressed");
      Register_Routine
        (T,
         Test_Guard_Blocked'Access,
         "Guard-blocked event traces the false guard and no move");
      Register_Routine
        (T, Test_Unhandled'Access, "Unhandled event traces as no transition");
      Register_Routine
        (T,
         Test_Note_Overflow_Dropped'Access,
         "A note past Notes_Capacity is dropped; blocked wording kept");
      Register_Routine
        (T,
         Test_Multiple_Guard_Notes'Access,
         "Multiple guard verdicts accumulate in one line");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Tracing (named DSL-layout trace)");
   end Name;

end Sml_Tracing_Tests;
