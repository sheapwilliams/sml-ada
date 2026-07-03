pragma Ada_2022;

--  Demonstrates Sml.Machines.Bundled: a vending machine that OWNS its extended
--  state.  With the core engine you thread a Context through every
--  Process_Event call (see hello_world); Bundled binds the Context to the
--  machine instead -- Boost.SML's model -- so Process_Event takes just the
--  event, and the running balance lives in Obj.Ctx, read and written in place.

with Ada.Text_IO; use Ada.Text_IO;

with Sml.Machines;
with Sml.Machines.Operators;
with Sml.Machines.Bundled;

procedure Bundled_Context is

   type State is (Idle, Dispensing);
   --  E_-prefixed so the operator wrappers below can be Insert/Buy/Take.
   type Event_Kind is (E_Insert, E_Buy, E_Take);

   --  Inserting coins carries how many cents; the other events carry nothing.
   type Event (Kind : Event_Kind := E_Take) is record
      case Kind is
         when E_Insert =>
            Amount : Natural;

         when others =>
            null;
      end case;
   end record;

   Price : constant Natural := 75;

   --  Extended state: cents banked so far.  This is what Bundled binds to the
   --  machine, instead of it being passed to every call.
   type Context is record
      Balance : Natural := 0;
   end record;

   type Guard_Kind is (Always, Enough);
   type Action_Kind is (Nothing, Add_Coin, Vend);

   function Kind_Of (E : Event) return Event_Kind
   is (E.Kind);

   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (Evt);
   begin
      return
        (case G is
           when Always => True,
           when Enough => Ctx.Balance >= Price);
   end Evaluate;

   procedure Execute (A : Action_Kind; Ctx : in out Context; Evt : Event) is
   begin
      case A is
         when Nothing  =>
            null;

         when Add_Coin =>
            Ctx.Balance := Ctx.Balance + Evt.Amount;

         when Vend     =>
            Ctx.Balance := Ctx.Balance - Price;   --  guarded by Enough
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

   package Op is new SM.Operators (Always => Always, Nothing => Nothing);

   --  Bundle a Machine with its Context; Process_Event then takes just the
   --  event and Make hands back a self-contained Instance.
   package B is new SM.Bundled;

   use SM, Op;

   Insert : constant Ev := (Kind => E_Insert);
   Buy    : constant Ev := (Kind => E_Buy);
   Take   : constant Ev := (Kind => E_Take);

   --  Each row reads:  From + Event (Guard) / Action >= To
   --!format off
   Table : constant Transition_Table :=
     [Idle       + Insert        / Add_Coin >= Idle,
      Idle       + Buy  (Enough) / Vend     >= Dispensing,
      Dispensing + Take                     >= Idle];
   --!format on

   --  Instance holds the machine and its Context together.
   Obj : B.Instance := B.Make (Table, Initial => Idle);

   procedure Show (Label : String) is
   begin
      Put_Line
        (Label
         & ":  state="
         & B.State_Of (Obj)'Image
         & "  balance="
         & Obj.Ctx.Balance'Image);
   end Show;

begin
   Show ("start   ");
   pragma Assert (B.State_Of (Obj) = Idle);

   --  Too little banked: the Enough guard fails, so the machine stays Idle.
   B.Process_Event (Obj, (Kind => E_Buy));
   Show ("buy poor");
   pragma Assert (B.State_Of (Obj) = Idle);

   --  Feed coins; each Insert accumulates into the bundled Context in place.
   B.Process_Event (Obj, (Kind => E_Insert, Amount => 25));
   B.Process_Event (Obj, (Kind => E_Insert, Amount => 25));
   B.Process_Event (Obj, (Kind => E_Insert, Amount => 50));
   Show ("coins   ");
   pragma Assert (Obj.Ctx.Balance = 100);

   --  Enough now: Buy dispenses and Vend debits the price, leaving change.
   B.Process_Event (Obj, (Kind => E_Buy));
   Show ("buy     ");
   pragma Assert (B.State_Of (Obj) = Dispensing);
   pragma Assert (Obj.Ctx.Balance = 100 - Price);

   B.Process_Event (Obj, (Kind => E_Take));
   Show ("take    ");
   pragma Assert (B.State_Of (Obj) = Idle);
   pragma Assert (Obj.Ctx.Balance = 25);
end Bundled_Context;
