package body Sml.Machines.Regions
  with SPARK_Mode
is

   procedure Broadcast
     (Regions : in out Region_Array; Ctx : in out Context; Evt : Event) is
   begin
      for R of Regions loop
         Process_Event (R, Ctx, Evt);
      end loop;
   end Broadcast;

end Sml.Machines.Regions;
