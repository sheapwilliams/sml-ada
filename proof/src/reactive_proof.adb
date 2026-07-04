package body Reactive_Proof
  with SPARK_Mode
is

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Idle,    E_Dial,    Always, Nothing, Dialing),
      (Dialing, E_Connect, Always, Nothing, Connected)];
   --!format on

   --  RC.Run_To_Completion's body is proved through the instantiation; Run only
   --  anchors Make's Post, since Run_To_Completion could raise by design.
   function Run return State
   is (Started (Table, Idle));

end Reactive_Proof;
