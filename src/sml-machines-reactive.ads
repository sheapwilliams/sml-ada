--  Run-to-completion with internal events.  Some states emit a follow-on event
--  on entry (e.g. a "Dialing" state that immediately sends Connect); Reactive
--  feeds the outside event, then keeps processing each entered state's entry
--  event until one settles with none.  The chain is bounded by Max_Steps, so a
--  cyclic configuration stops instead of looping forever (and SPARK proves
--  termination).  Opt-in: existing machines are untouched.
--
--     package RC is new SM.Reactive
--       (Has_Entry_Event => Has_Entry_Event, Entry_Event => Entry_Event);
--     RC.Run_To_Completion (M, Ctx, Dial);   --  -> Dialing -> Connected

generic
   --  Upper bound on the entry-event chain after the initial event.
   Max_Steps : Positive := 16;
   --  Does state S emit an event on entry, and if so which one?
   with function Has_Entry_Event (S : State) return Boolean;
   with function Entry_Event (S : State) return Event;
package Sml.Machines.Reactive with SPARK_Mode is

   --  Outcome of a run.  Settled: the chain reached a state with no entry
   --  event, or one whose entry event left it in place (a stable config).
   --  Step_Limit_Reached: the chain was still advancing when Max_Steps was
   --  hit, so the machine may not have finished settling.  (The bound is what
   --  keeps this terminating and SPARK-provable, unlike Boost.SML which runs
   --  internal transitions to completion; this flag surfaces when it bit.)
   type Completion is (Settled, Step_Limit_Reached);

   --  Process Evt, then process the entry event of each state entered, until a
   --  state has none, a state does not advance (settled), or Max_Steps is
   --  reached.  Result distinguishes settling from hitting the cap.
   procedure Run_To_Completion
     (M      : in out Machine;
      Ctx    : in out Context;
      Evt    : Event;
      Result : out Completion)
   with
     Post              =>
       Table_Of (M) = Table_Of (M'Old)
       and then Policy_Of (M) = Policy_Of (M'Old)
       and then Default_Of (M) = Default_Of (M'Old),
     --  Precise trigger (raises only under Raise_Error) is inexpressible here:
     --  Run_To_Completion raises by propagation from Process_Event, and this
     --  SPARK version havocs M on a propagated exception, so M'Old cannot be
     --  referenced in the consequence ("M might not be initialized").  The
     --  engine's Process_Event, which raises directly, does carry the trigger.
     Exceptional_Cases => (Unhandled_Event => True);

   --  Convenience overload for callers that do not inspect the outcome.
   procedure Run_To_Completion
     (M : in out Machine; Ctx : in out Context; Evt : Event)
   with
     Post              =>
       Table_Of (M) = Table_Of (M'Old)
       and then Policy_Of (M) = Policy_Of (M'Old)
       and then Default_Of (M) = Default_Of (M'Old),
     --  Precise trigger (raises only under Raise_Error) is inexpressible here:
     --  Run_To_Completion raises by propagation from Process_Event, and this
     --  SPARK version havocs M on a propagated exception, so M'Old cannot be
     --  referenced in the consequence ("M might not be initialized").  The
     --  engine's Process_Event, which raises directly, does carry the trigger.
     Exceptional_Cases => (Unhandled_Event => True);

end Sml.Machines.Reactive;
