package body Sml.Machines
  with SPARK_Mode
is

   --  The defensive Total check raises Incomplete_Table; Make's precondition
   --  proves that raise unreachable for SPARK callers, while the check still
   --  guards ordinary (non-SPARK) callers at run time.
   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Machine is
   begin
      if Complete = Total then
         for S in State loop
            for K in Event_Kind loop
               if not Covers (Table, S, K) then
                  raise Incomplete_Table
                    with "missing transition: " & S'Image & " on " & K'Image;
               end if;
            end loop;
         end loop;
      end if;

      return
        (Count        => Table'Length,
         Current      => Initial,
         On_Unhandled => On_Unhandled,
         Default      => Default,
         Table        => Table);
   end Make;

   procedure Process_Event
     (M       : in out Machine;
      Ctx     : in out Context;
      Evt     : Event;
      Handled : out Boolean)
   is
      K   : constant Event_Kind := Kind_Of (Evt);
      Cur : constant State := M.Current;
   begin
      On_Event (K, Cur);

      for I in M.Table'Range loop
         --  Nothing before a fired transition touches Current or Ctx, so every
         --  matching guard tried so far failed (or we'd have returned), which
         --  discharges the "not Handled => nothing was enabled" postcondition.
         pragma Loop_Invariant (M.Current = Cur);
         pragma
           Loop_Invariant
             (for all J in M.Table'First .. I - 1 =>
                (if Matches (M.Table (J), Cur, K)
                 then not Evaluate (M.Table (J).Guard, Ctx, Evt)));
         declare
            T : Transition renames M.Table (I);
         begin
            if Matches (T, Cur, K) then
               declare
                  Pass : constant Boolean := Evaluate (T.Guard, Ctx, Evt);
               begin
                  On_Guard (T.Guard, Pass);
                  if Pass then
                     On_Action (T.Action, Cur, T.To);
                     Execute (T.Action, Ctx, Evt);
                     M.Current := T.To;
                     Handled := True;
                     return;
                  end if;
               end;
            end if;
         end;
      end loop;
      Handled := False;
   end Process_Event;

   procedure Process_Event
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   is
      Handled : Boolean;
   begin
      Process_Event (M, Ctx, Evt, Handled);

      if not Handled then
         declare
            K : constant Event_Kind := Kind_Of (Evt);
         begin
            On_Unhandled (K, M.Current);

            case M.On_Unhandled is
               when Stay          =>
                  null;

               when Raise_Error   =>
                  raise Unhandled_Event
                    with M.Current'Image & " on " & K'Image;

               when Go_To_Default =>
                  M.Current := M.Default;
            end case;
         end;
      end if;
   end Process_Event;

end Sml.Machines;
