package body Tracing_Proof
  with SPARK_Mode
is

   use TSM;

   procedure Count (Item : String) is
      pragma Unreferenced (Item);
   begin
      if Lines < Natural'Last then
         Lines := Lines + 1;
      end if;
   end Count;

   --!format off
   Table : constant Transition_Table :=
     [(Locked,   E_Coin, Always, Nothing, Unlocked),
      (Unlocked, E_Push, Always, Nothing, Locked)];
   --!format on

   --  As in the other harnesses: Make's Post chains to Run's result; the
   --  hooks' and engine's bodies are proved through the instantiations, so
   --  Run need not call Process_Event (which could raise by design).
   function Run return State
   is (State_Of (Make (Table, Initial => Locked)));

end Tracing_Proof;
