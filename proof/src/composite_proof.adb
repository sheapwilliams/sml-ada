package body Composite_Proof
  with SPARK_Mode
is

   procedure No_Child
     (Ctx : in out Context; Evt : Event; Handled : out Boolean)
   is
      pragma Unreferenced (Ctx, Evt);
   begin
      Handled := False;
   end No_Child;

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Off, E_Power, Always, Nothing, On),
      (On,  E_Power, Always, Nothing, Off)];
   --!format on

   function Run return State
   is (Started (Table, Off));

end Composite_Proof;
