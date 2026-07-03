package body Sml.Machines.Reactive
  with SPARK_Mode
is

   procedure Run_To_Completion
     (M      : in out Machine;
      Ctx    : in out Context;
      Evt    : Event;
      Result : out Completion) is
   begin
      Process_Event (M, Ctx, Evt);
      Result := Settled;
      for Step in 1 .. Max_Steps loop
         declare
            S : constant State := State_Of (M);
         begin
            exit when not Has_Entry_Event (S);
            Process_Event (M, Ctx, Entry_Event (S));
            --  The entry event left us in the same state: a stable (or
            --  self-looping) configuration -- stop rather than re-fire it.
            exit when State_Of (M) = S;
            if Step = Max_Steps and then Has_Entry_Event (State_Of (M)) then
               Result := Step_Limit_Reached;
            end if;
         end;
      end loop;
   end Run_To_Completion;

   procedure Run_To_Completion
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      Ignored : Completion;
   begin
      Run_To_Completion (M, Ctx, Evt, Ignored);
   end Run_To_Completion;

end Sml.Machines.Reactive;
