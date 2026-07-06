package body Turnstile_Proof
  with SPARK_Mode
is

   use SM, Op;

   Coin : constant Ev := (Kind => E_Coin);
   Push : constant Ev := (Kind => E_Push);

   --!format off
   Table : constant Transition_Table :=
     [Locked   + Coin >= Unlocked,
      Unlocked + Push >= Locked];
   --!format on

   --  Started chains Make's Post (State_Of (Make'Result) = Initial) to Run's
   --  result.  Process_Event's body is proved free of run-time errors by
   --  virtue of the SM instantiation (gnatprove analyses the instance), so it
   --  need not be called here -- and calling it would oblige Run, a function,
   --  to handle the by-design Unhandled_Event (functions can't carry
   --  Exceptional_Cases).
   function Run return State
   is (Started (Table, Locked));

   function Push_In_Locked return State is
      M : Machine := Make (Table, Initial => Locked);
      C : Context;
      pragma
        Warnings
          (GNATprove,
           Off,
           "* set by ""Process_Event"" but not used after the call",
           Reason =>
             "the turnstile's Context is a null record, irrelevant here");
   begin
      Process_Event
        (M, C, (Kind => E_Push));   --  3-arg: unhandled, Stay => put
      return State_Of (M);
   end Push_In_Locked;

   function Coin_In_Locked return State is
      M       : Machine := Make (Table, Initial => Locked);
      C       : Context;
      Handled : Boolean;
      pragma
        Warnings
          (GNATprove,
           Off,
           "* set by ""Process_Event"" but not used after the call",
           Reason =>
             "neither the null-record Context nor Handled is read here");
   begin
      Process_Event (M, C, (Kind => E_Coin), Handled);
      --  4-arg: completeness forces Handled
      return State_Of (M);
   end Coin_In_Locked;

end Turnstile_Proof;
