package body Regions_Proof
  with SPARK_Mode
is

   use Reg;

   function Run return Boolean is
      None : constant Region_Array (1 .. 0) := [];
   begin
      return All_In (None, Off);
   end Run;

end Regions_Proof;
