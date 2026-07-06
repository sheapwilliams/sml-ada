package body Sml.Machines.Regions
  with SPARK_Mode
is

   procedure Broadcast
     (Regions : in out Region_Array; Ctx : in out Context; Evt : Event) is
   begin
      for I in Regions'Range loop
         pragma
           Loop_Invariant
             (for all J in Regions'Range =>
                Table_Of (Regions (J)) = Table_Of (Regions'Loop_Entry (J))
                and then Policy_Of (Regions (J))
                         = Policy_Of (Regions'Loop_Entry (J))
                and then Default_Of (Regions (J))
                         = Default_Of (Regions'Loop_Entry (J)));
         Process_Event (Regions (I), Ctx, Evt);
      end loop;
   end Broadcast;

end Sml.Machines.Regions;
