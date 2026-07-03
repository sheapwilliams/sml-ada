package body Sml.Machines.Bundled
  with SPARK_Mode
is

   function Make
     (Table        : Transition_Table;
      Initial      : State;
      Complete     : Completeness := Partial;
      On_Unhandled : Unhandled_Policy := Stay;
      Default      : State := State'First) return Instance is
   begin
      return Self : Instance (Table'Length) do
         Self.M :=
           Sml.Machines.Make (Table, Initial, Complete, On_Unhandled, Default);
      end return;
   end Make;

   procedure Process_Event (Self : in out Instance; Evt : Event) is
   begin
      Sml.Machines.Process_Event (Self.M, Self.Ctx, Evt);
   end Process_Event;

   procedure Process_Event
     (Self : in out Instance; Evt : Event; Handled : out Boolean) is
   begin
      Sml.Machines.Process_Event (Self.M, Self.Ctx, Evt, Handled);
   end Process_Event;

end Sml.Machines.Bundled;
