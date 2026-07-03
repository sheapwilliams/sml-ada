package body Bundled_Proof
  with SPARK_Mode
is

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Locked,   E_Coin, Always, Nothing, Unlocked),
      (Unlocked, E_Push, Always, Nothing, Locked)];
   --!format on

   function Run return State is
      Obj : constant B.Instance := B.Make (Table, Initial => Locked);
   begin
      return B.State_Of (Obj);
   end Run;

end Bundled_Proof;
