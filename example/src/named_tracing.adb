--  Batteries-included tracing with Sml.Tracing.  Where hello_world_with_tracing
--  hand-rolls the four On_* hooks, here they come pre-built: instantiate
--  Sml.Tracing with the same enums, give the machine a Name, and pass its
--  procedures into Sml.Machines.  Every processed event prints one line in the
--  table's own layout, tagged with the machine name and each guard's truth, so
--  a trace shows why a transition did or did not fire:
--
--     sml<AUTH>: REFRESHING + E_REFRESH_OK (TOKEN_VALID=True) / PERSIST_SESSION
--                --> AUTHENTICATED
--
--  Output is routed through a Put_Line that honours Trace_Config.Enabled, so
--  like the other example it is live in the debug profile and quiet in release.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Tracing;
with Trace_Config;

procedure Named_Tracing is

   type State is (Refreshing, Authenticated, Failed);
   type Event_Kind is (E_Refresh_Ok, E_Refresh_Fail, E_Expire);

   type Event (Kind : Event_Kind := E_Expire) is record
      case Kind is
         when E_Refresh_Ok =>
            Token_Ok : Boolean;

         when others =>
            null;
      end case;
   end record;

   type Context is null record;
   type Guard_Kind is (Always, Token_Valid);
   type Action_Kind is (Nothing, Persist_Session, Clear_Session);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (Ctx);
   begin
      return
        (case G is
           when Always      => True,
           when Token_Valid =>
             (case Evt.Kind is
                when E_Refresh_Ok => Evt.Token_Ok,
                when others       => False));
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      case A is
         when Nothing         =>
            null;

         when Persist_Session =>
            Put_Line ("action: persist session");

         when Clear_Session   =>
            Put_Line ("action: clear session");
      end case;
   end Execute;

   --  The output sink: honour the profile switch so release stays quiet.
   procedure Emit (Item : String) is
   begin
      if Trace_Config.Enabled then
         Put_Line (Item);
      end if;
   end Emit;

   package Trace is new
     Sml.Tracing
       (State       => State,
        Event_Kind  => Event_Kind,
        Guard_Kind  => Guard_Kind,
        Action_Kind => Action_Kind,
        Name        => "AUTH",
        Always      => Always,
        Nothing     => Nothing,
        Put_Line    => Emit);

   package SM is new
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

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   Refresh_Ok   : constant Ev := (Kind => E_Refresh_Ok);
   Refresh_Fail : constant Ev := (Kind => E_Refresh_Fail);
   Expire       : constant Ev := (Kind => E_Expire);

   --!format off
   Table : constant Transition_Table :=
     [Refreshing    + Refresh_Ok (Token_Valid) / Persist_Session
                                                        >= Authenticated,
      Refreshing    + Refresh_Fail              / Clear_Session
                                                        >= Failed,
      Authenticated + Expire                            >= Refreshing];
   --!format on

   M   : Machine := Make (Table, Initial => Refreshing);
   Ctx : Context;
begin
   --  A valid refresh authenticates; the guard reads True.
   Process_Event (M, Ctx, (Kind => E_Refresh_Ok, Token_Ok => True));
   --  The session expires back to Refreshing.
   Process_Event (M, Ctx, (Kind => E_Expire));
   --  An invalid refresh: the guard reads False, so nothing fires.
   Process_Event (M, Ctx, (Kind => E_Refresh_Ok, Token_Ok => False));
   --  An explicit failure drops to Failed.
   Process_Event (M, Ctx, (Kind => E_Refresh_Fail));
   --  Failed has no outgoing row for Expire: unhandled.
   Process_Event (M, Ctx, (Kind => E_Expire));
end Named_Tracing;
