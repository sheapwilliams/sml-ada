package body Proof_Scaffold
  with SPARK_Mode
is

   --  The only guard is "Always", so it ignores its inputs.
   function Evaluate
     (G : Guard_Kind; Ctx : Context; Evt : Event) return Boolean
   is
      pragma Unreferenced (G, Ctx, Evt);
   begin
      return True;
   end Evaluate;

end Proof_Scaffold;
