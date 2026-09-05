# Roadmap automation

Run the bounded milestone loop from the repository root:

```powershell
& .\tools\roadmap_loop.ps1 -MaxIterations 10
```

Each iteration:

1. Verifies that `PROJECT_PLAN.md` exists and its numbered checkpoints are unique and ordered.
2. Runs gameplay tests, headless startup, whitespace checks, and roadmap validation.
3. Reads the latest checkpoint after validation.
4. Stops safely when no new checkpoint was recorded.
5. Rejects skipped checkpoint numbers and never runs more than 100 iterations.

The loop does not create roadmap entries or claim unfinished work. A milestone
must be implemented and recorded in `PROJECT_PLAN.md` by the development pass;
the next loop iteration then validates that checkpoint before continuing.

Use `-StopAtCheckpoint N` to stop after a specific checkpoint, and
`-RequireExportTemplates` when packaging is part of the gate. Windows export
templates are currently an external packaging prerequisite; normal development
validation reports their absence without failing.

Use `-ResultPath <file>` for a JSON summary containing the validated checkpoint,
iteration count, stop reason, and validation result.
