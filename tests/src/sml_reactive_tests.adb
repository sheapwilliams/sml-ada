with AUnit.Assertions; use AUnit.Assertions;

with Sml.Machines;
with Sml.Machines.Reactive;

package body Sml_Reactive_Tests is

   use AUnit.Test_Cases.Registration;

   type Null_Ctx is null record;
   type G is (Always);
   type A is (Nothing);

   --  Phone: dialling settles to Connected on its own via an entry event.
   type P_St is (Idle, Dialing, Connected);
   type P_Ev is (E_Dial, E_Connect);

   type P_Event is record
      Kind : P_Ev;
   end record;

   function P_Kind (E : P_Event) return P_Ev
   is (E.Kind);

   function P_Eval (Gk : G; C : Null_Ctx; E : P_Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end P_Eval;

   procedure P_Exec (Ak : A; C : in out Null_Ctx; E : P_Event) is null;

   package P_SM is new
     Sml.Machines
       (P_St,
        P_Ev,
        P_Event,
        Null_Ctx,
        G,
        A,
        P_Kind,
        P_Eval,
        P_Exec);

   function P_Has (S : P_St) return Boolean
   is (S = Dialing);

   function P_Entry (S : P_St) return P_Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Connect);
   end P_Entry;

   package P_RC is new
     P_SM.Reactive (Has_Entry_Event => P_Has, Entry_Event => P_Entry);

   --!format off
   Phone : constant P_SM.Transition_Table :=
     [(Idle,    E_Dial,    Always, Nothing, Dialing),
      (Dialing, E_Connect, Always, Nothing, Connected)];
   --!format on

   --  Ping/Pong: every state has an entry event, so the chain is cyclic and is
   --  cut off by Max_Steps rather than looping forever.
   type T_St is (Ping, Pong);
   type T_Ev is (E_Beat);

   type T_Event is record
      Kind : T_Ev;
   end record;

   function T_Kind (E : T_Event) return T_Ev
   is (E.Kind);

   function T_Eval (Gk : G; C : Null_Ctx; E : T_Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end T_Eval;

   procedure T_Exec (Ak : A; C : in out Null_Ctx; E : T_Event) is null;

   package T_SM is new
     Sml.Machines
       (T_St,
        T_Ev,
        T_Event,
        Null_Ctx,
        G,
        A,
        T_Kind,
        T_Eval,
        T_Exec);

   function T_Has (S : T_St) return Boolean is
      pragma Unreferenced (S);
   begin
      return True;
   end T_Has;

   function T_Entry (S : T_St) return T_Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Beat);
   end T_Entry;

   package T_RC is new
     T_SM.Reactive
       (Max_Steps       => 3,
        Has_Entry_Event => T_Has,
        Entry_Event     => T_Entry);

   --!format off
   Toggle : constant T_SM.Transition_Table :=
     [(Ping, E_Beat, Always, Nothing, Pong),
      (Pong, E_Beat, Always, Nothing, Ping)];
   --!format on

   --  Self-loop: an entry event that fires but leaves the state unchanged must
   --  be treated as settled (fire once), not spun Max_Steps times.  A Context
   --  counter makes the number of firings observable.
   type NS_Ctx is record
      Count : Natural := 0;
   end record;

   type NS_St is (NS_Start, NS_Loop);
   type NS_Ev is (E_Go, E_Tick);

   type NS_Event is record
      Kind : NS_Ev;
   end record;

   type NS_A is (Nothing, Bump);

   function NS_Kind (E : NS_Event) return NS_Ev
   is (E.Kind);

   function NS_Eval (Gk : G; C : NS_Ctx; E : NS_Event) return Boolean is
      pragma Unreferenced (Gk, C, E);
   begin
      return True;
   end NS_Eval;

   procedure NS_Exec (Ak : NS_A; C : in out NS_Ctx; E : NS_Event) is
      pragma Unreferenced (E);
   begin
      if Ak = Bump then
         C.Count := C.Count + 1;
      end if;
   end NS_Exec;

   package NS_SM is new
     Sml.Machines
       (NS_St,
        NS_Ev,
        NS_Event,
        NS_Ctx,
        G,
        NS_A,
        NS_Kind,
        NS_Eval,
        NS_Exec);

   function NS_Has (S : NS_St) return Boolean
   is (S = NS_Loop);

   function NS_Entry (S : NS_St) return NS_Event is
      pragma Unreferenced (S);
   begin
      return (Kind => E_Tick);
   end NS_Entry;

   package NS_RC is new
     NS_SM.Reactive (Has_Entry_Event => NS_Has, Entry_Event => NS_Entry);

   --!format off
   Self_Loop : constant NS_SM.Transition_Table :=
     [(NS_Start, E_Go,   Always, Nothing, NS_Loop),
      (NS_Loop,  E_Tick, Always, Bump,    NS_Loop)];
   --!format on

   procedure Test_Run_To_Completion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      C  : Null_Ctx;
      M1 : P_SM.Machine := P_SM.Make (Phone, Initial => Idle);
      M2 : P_SM.Machine := P_SM.Make (Phone, Initial => Idle);
   begin
      --  One plain event only advances one step.
      P_SM.Process_Event (M1, C, (Kind => E_Dial));
      Assert (P_SM.State_Of (M1) = Dialing, "a single event lands in Dialing");

      --  Run-to-completion processes Dialing's entry event too.
      P_RC.Run_To_Completion (M2, C, (Kind => E_Dial));
      Assert
        (P_SM.State_Of (M2) = Connected,
         "run-to-completion reaches Connected via the entry event");
   end Test_Run_To_Completion;

   procedure Test_Bounded (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      C : Null_Ctx;
      M : T_SM.Machine := T_SM.Make (Toggle, Initial => Ping);
   begin
      --  A cyclic entry-event chain: this must terminate (not hang) at the cap.
      --  Ping -beat-> Pong, then 3 entry steps: Pong->Ping->Pong->Ping.
      T_RC.Run_To_Completion (M, C, (Kind => E_Beat));
      Assert
        (T_SM.State_Of (M) = Ping,
         "cyclic entry events stop after Max_Steps without looping forever");
   end Test_Bounded;

   procedure Test_Completion_Settled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type P_RC.Completion;
      C       : Null_Ctx;
      M       : P_SM.Machine := P_SM.Make (Phone, Initial => Idle);
      Outcome : P_RC.Completion;
   begin
      P_RC.Run_To_Completion (M, C, (Kind => E_Dial), Outcome);
      Assert (P_SM.State_Of (M) = Connected, "settles to Connected");
      Assert
        (Outcome = P_RC.Settled,
         "a chain reaching a state with no entry event reports Settled");
   end Test_Completion_Settled;

   procedure Test_Completion_Step_Limit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type T_RC.Completion;
      C       : Null_Ctx;
      M       : T_SM.Machine := T_SM.Make (Toggle, Initial => Ping);
      Outcome : T_RC.Completion;
   begin
      T_RC.Run_To_Completion (M, C, (Kind => E_Beat), Outcome);
      Assert
        (Outcome = T_RC.Step_Limit_Reached,
         "a still-progressing chain that hits Max_Steps reports the limit");
   end Test_Completion_Step_Limit;

   procedure Test_No_Spin_On_Self_Loop
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type NS_RC.Completion;
      C       : NS_Ctx;
      M       : NS_SM.Machine := NS_SM.Make (Self_Loop, Initial => NS_Start);
      Outcome : NS_RC.Completion;
   begin
      NS_RC.Run_To_Completion (M, C, (Kind => E_Go), Outcome);
      Assert
        (C.Count = 1,
         "a self-looping entry event fires once, not Max_Steps times");
      Assert
        (Outcome = NS_RC.Settled,
         "a state that does not advance is settled, not a step-limit");
   end Test_No_Spin_On_Self_Loop;

   procedure Register_Tests (T : in out Test) is
   begin
      Register_Routine
        (T,
         Test_Run_To_Completion'Access,
         "Run_To_Completion follows entry events to a settled state");
      Register_Routine
        (T,
         Test_Bounded'Access,
         "Max_Steps bounds a cyclic entry-event chain");
      Register_Routine
        (T,
         Test_Completion_Settled'Access,
         "Run_To_Completion reports Settled when the chain settles");
      Register_Routine
        (T,
         Test_Completion_Step_Limit'Access,
         "Run_To_Completion reports Step_Limit_Reached at the cap");
      Register_Routine
        (T,
         Test_No_Spin_On_Self_Loop'Access,
         "A self-looping entry event fires once, not Max_Steps times");
   end Register_Tests;

   overriding
   function Name (T : Test) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Sml.Machines.Reactive (run-to-completion)");
   end Name;

end Sml_Reactive_Tests;
