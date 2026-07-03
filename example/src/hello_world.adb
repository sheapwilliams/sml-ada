--  A TCP-teardown machine (Boost.SML's hello_world) built with the opt-in
--  operators (Sml.Machines.Operators) so each row reads close to Boost.SML:
--  From + Event (Guard) / Action >= To.
--
--  Read this top-to-bottom as a recipe for building your own machine.  For the
--  same machine with structured logging wired in, see hello_world_with_tracing.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;

procedure Hello_World is

   --  Event_Kind literals are prefixed E_* so the event "names" below
   --  (Release, Ack, ...), which are the operator wrappers, don't collide.
   type State is (Established, Fin_Wait_1, Fin_Wait_2, Timed_Wait, Closed);
   type Event_Kind is (E_Release, E_Ack, E_Fin, E_Timeout);

   type Event (Kind : Event_Kind := E_Timeout) is record
      case Kind is
         when E_Ack =>
            Ack_Valid : Boolean;

         when E_Fin =>
            Id        : Integer;
            Fin_Valid : Boolean;

         when others =>
            null;
      end case;
   end record;

   type Context is null record;
   type Guard_Kind is (Always, Is_Valid);
   type Action_Kind is (Nothing, Send_Fin, Send_Ack);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (Ctx);
   begin
      return
        (case G is
           when Always   => True,
           when Is_Valid =>
             (case Evt.Kind is
                when E_Ack  => Evt.Ack_Valid,
                when E_Fin  => Evt.Fin_Valid,
                when others => False));
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
      pragma Unreferenced (Ctx, Evt);
   begin
      case A is
         when Nothing  =>
            null;

         when Send_Fin =>
            Put_Line ("send: fin");

         when Send_Ack =>
            Put_Line ("send: ack");
      end case;
   end Execute;

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

   --  Opt in to the operators, naming the "always" guard and "do nothing"
   --  action used by rows that omit them.
   package Op is new SM.Operators (Always => Always, Nothing => Nothing);
   use SM, Op;

   Release : constant Ev := (Kind => E_Release);
   Ack     : constant Ev := (Kind => E_Ack);
   Fin     : constant Ev := (Kind => E_Fin);
   Timeout : constant Ev := (Kind => E_Timeout);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --  (initial state is given to Make, like SML's *; a state with no outgoing
   --  row is terminal, like SML's X).  A plain array aggregate of Transitions.
   --!format off
   Table : constant Transition_Table :=
     [Established + Release            / Send_Fin >= Fin_Wait_1,
      Fin_Wait_1  + Ack     (Is_Valid)            >= Fin_Wait_2,
      Fin_Wait_2  + Fin     (Is_Valid) / Send_Ack >= Timed_Wait,
      Timed_Wait  + Timeout                       >= Closed];
   --!format on

   M   : Machine := Make (Table, Initial => Established);
   Ctx : Context := (null record);
begin
   Put_Line ("start: " & State_Of (M)'Image);
   Process_Event (M, Ctx, (Kind => E_Release));
   Process_Event (M, Ctx, (Kind => E_Ack, Ack_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Fin, Id => 42, Fin_Valid => True));
   Process_Event (M, Ctx, (Kind => E_Timeout));
   Put_Line ("final: " & State_Of (M)'Image);
end Hello_World;
