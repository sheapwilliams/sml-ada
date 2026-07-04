package body Deferring_Proof
  with SPARK_Mode
is

   use SM;

   --!format off
   Table : constant Transition_Table :=
     [(Stopped, E_Play,  Always, Nothing, Playing),
      (Playing, E_Pause, Always, Nothing, Paused),
      (Playing, E_Stop,  Always, Nothing, Stopped),
      (Paused,  E_Play,  Always, Nothing, Playing),
      (Paused,  E_Stop,  Always, Nothing, Stopped)];
   --!format on

   function Run return State
   is (Started (Table, Stopped));

end Deferring_Proof;
