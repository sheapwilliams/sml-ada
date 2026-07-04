with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Sml.Tracing is

   --  The line being composed across the hooks of one Process_Event call:
   --  On_Event opens it (kind, guards reset), On_Guard appends each guard's
   --  verdict, and On_Action / On_Unhandled close and emit it.
   Last_Event : Event_Kind;
   Guards     : Unbounded_String;

   Prefix : constant String := "sml<" & Name & ">: ";

   procedure On_Event (Evt : Event_Kind; From : State) is
      pragma Unreferenced (From);
   begin
      Last_Event := Evt;
      Guards := Null_Unbounded_String;
   end On_Event;

   procedure On_Guard (Guard : Guard_Kind; Passed : Boolean) is
   begin
      --  The Always guard carries no information -- omit it.
      if Guard /= Always then
         Append
           (Guards,
            " ("
            & Guard'Image
            & "="
            & (if Passed then "True" else "False")
            & ")");
      end if;
   end On_Guard;

   procedure On_Action (Action : Action_Kind; From, To : State) is
   begin
      Put_Line
        (Prefix
         & From'Image
         & " + "
         & Last_Event'Image
         & To_String (Guards)
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
         & To_String (Guards)
         & (if Length (Guards) = 0
            then " -- unhandled (no transition)"
            else " -- blocked by guard (no transition)"));
   end On_Unhandled;

end Sml.Tracing;
