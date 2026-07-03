with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Bundled;

package body Sml_Bundled_Tests is

   use AUnit.Test_Cases.Registration;

   --  A toggle whose On state accumulates ticks, so the bundled Context is
   --  visibly carried across events without being passed to Process_Event.
   type St is (Off, On);
   type Ev is (E_Toggle, E_Tick);

   type Evt is record
      Kind : Ev;
   end record;

   type Ctx_T is record
      Count : Natural := 0;
   end record;

   type G_Kind is (Always);
   type A_Kind is (Nothing, Bump);

   function Kind_Of (E : Evt) return Ev
   is (E.Kind);

   function Evaluate (G : G_Kind; C : Ctx_T; E : Evt) return Boolean is
      pragma Unreferenced (G, C, E);
   begin
      return True;
   end Evaluate;

   procedure Execute (A : A_Kind; C : in out Ctx_T; E : Evt) is
      pragma Unreferenced (E);
   begin
      if A = Bump then
         C.Count := C.Count + 1;
      end if;
   end Execute;

   package M is new
     Sml.Machines
       (St,
        Ev,
        Evt,
        Ctx_T,
        G_Kind,
        A_Kind,
        Kind_Of,
        Evaluate,
        Execute);

   package B is new M.Bundled;

   --!format off
   Table : constant M.Transition_Table :=
     [(Off, E_Toggle, Always, Nothing, On),
      (On,  E_Tick,   Always, Bump,    On),
      (On,  E_Toggle, Always, Nothing, Off)];
   --!format on

   procedure Test_Bundled_Context (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Obj : B.Instance := B.Make (Table, Initial => Off);
   begin
      Assert (B.State_Of (Obj) = Off, "starts Off");

      --  Events carry only the event -- no Context argument.
      B.Process_Event (Obj, (Kind => E_Toggle));
      Assert (B.State_Of (Obj) = On, "Toggle -> On");

      B.Process_Event (Obj, (Kind => E_Tick));
      B.Process_Event (Obj, (Kind => E_Tick));
      Assert
        (Obj.Ctx.Count = 2, "the bundled Context accumulates across events");
   end Test_Bundled_Context;

   procedure Test_Bundled_Handled (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Obj     : B.Instance := B.Make (Table, Initial => Off);
      Handled : Boolean;
   begin
      --  Off has no E_Tick row: the reporting overload says so and stays put.
      B.Process_Event (Obj, (Kind => E_Tick), Handled);
      Assert (not Handled, "unhandled event reports Handled => False");
      Assert (B.State_Of (Obj) = Off, "unhandled event leaves the state");
   end Test_Bundled_Handled;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Bundled_Context'Access,
         "A bundled machine carries its Context across events");
      Register_Routine
        (T,
         Test_Bundled_Handled'Access,
         "The bundled reporting overload signals unhandled events");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Bundled (machine owns its context)");
   end Name;

end Sml_Bundled_Tests;
