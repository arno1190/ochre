# Ochre: build iteration

You are one iteration of an autonomous loop that builds Ochre from its specification. Follow `AGENTS.md`.

1. Read `progress.txt` and `git log --oneline -15`. If `## Current State:` is `INITIALIZING`, set it to `IN_PROGRESS`.
2. Open the current milestone in `docs/11-roadmap.md`, and read every spec section it names, in full.
3. Take the first unchecked acceptance criterion of that milestone:
   1. write its test and run it: it must be **red**;
   2. implement until it is **green**;
   3. run `make check` (once the Makefile exists) and fix anything it reports;
   4. tick the criterion in `progress.txt` and commit the code and `progress.txt` together.
4. Repeat step 3 until every criterion of the milestone is ticked and the roadmap's definition of done holds. Then tick the milestone, add a dated line under `## Log`, and move `## Current milestone:` to the next one.
5. End the iteration after finishing one milestone, or earlier if the remaining work no longer fits. Before ending, `## Next step:` must hold the exact next action in one line.
6. When M12 is ticked, set `## Current State: COMPLETED`.

Stop and set `## Current State: BLOCKED` only for the cases `AGENTS.md` lists, writing the exact question under `## Blocked on`.

`progress.txt` rule: the words COMPLETED and BLOCKED appear in that file **only** on the `## Current State:` line, because the loop script greps for them.
