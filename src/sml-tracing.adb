package body Sml.Tracing
  with
    SPARK_Mode,
    Refined_State =>
      (Trace_State => (Last_Event, Guards_Seen, Guard_Notes, Notes_Last))
is

   --  The line being composed across the hooks of one Process_Event call:
   --  On_Event opens it (kind noted, notes reset), On_Guard appends each
   --  non-trivial guard's verdict to the bounded buffer, and On_Action /
   --  On_Unhandled close and emit it.
   subtype Note_Length is Natural range 0 .. Notes_Capacity;

   Last_Event  : Event_Kind := Event_Kind'First;
   Guards_Seen : Boolean := False;
   Guard_Notes : String (1 .. Notes_Capacity) := [others => ' '];
   Notes_Last  : Note_Length := 0;

   Prefix : constant String := "sml<" & Name & ">: ";

   function Notes_Used return Natural
   is (Notes_Last);

   procedure On_Event (Evt : Event_Kind; From : State) is
      pragma Unreferenced (From);
   begin
      Last_Event := Evt;
      Guards_Seen := False;
      Notes_Last := 0;
   end On_Event;

   procedure On_Guard (Guard : Guard_Kind; Passed : Boolean) is
   begin
      --  The Always guard carries no information -- omit it.
      if Guard = Always then
         return;
      end if;

      Guards_Seen := True;

      declare
         Note : constant String :=
           " ("
           & Guard'Image
           & "="
           & (if Passed then "True" else "False")
           & ")";
      begin
         --  A note that would overflow the buffer is dropped; Guards_Seen
         --  above still records it for On_Unhandled's wording.
         if Note'Length <= Notes_Capacity - Notes_Last then
            Guard_Notes (Notes_Last + 1 .. Notes_Last + Note'Length) := Note;
            Notes_Last := Notes_Last + Note'Length;
         end if;
      end;
   end On_Guard;

   --  Both emitters open with the same skeleton -- sml<Name>: From + Event
   --  Notes -- but each builds its line in one expression: a shared helper
   --  would take the notes and tail as opaque String parameters, hiding the
   --  length bounds the concatenation's range-check proof needs.
   procedure On_Action (Action : Action_Kind; From, To : State) is
   begin
      Put_Line
        (Prefix
         & From'Image
         & " + "
         & Last_Event'Image
         & Guard_Notes (1 .. Notes_Last)
         & (if Action = Nothing then "" else " / " & Action'Image)
         & " --> "
         & To'Image);
   end On_Action;

   procedure On_Unhandled (Evt : Event_Kind; From : State) is
   begin
      Put_Line
        (Prefix
         & From'Image
         & " + "
         & Evt'Image
         & Guard_Notes (1 .. Notes_Last)
         & (if Guards_Seen
            then " -- blocked by guard (no transition)"
            else " -- unhandled (no transition)"));
   end On_Unhandled;

end Sml.Tracing;
