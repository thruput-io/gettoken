# Architectural Decision Records

Read these in reverse: highest number first, down to `0001`.

Reading forwards will mislead you. A later record replaces an earlier one
without annotating it, so the first record you meet reading backwards is the one
that holds, and anything older saying otherwise is history that can be
discarded.

## Immutable

A record is never edited once it is merged. A decision that no longer holds is
replaced by a later record, not amended in place. One that turned out to be
wrong stays in the sequence as evidence of what was believed at the time.

## No status, no dates

A pull request is accepted when it is merged, and that is the status. Git holds
the dates, and git can also show what the code looked like at the time, which is
what explains why legacy code works the way it does.

## First rule wins

Reading backwards, the first record that speaks to a question settles it. A new
decision therefore never has to hunt down and annotate what it supersedes. It
only has to be later.

## Naming

`NNNN-short-title.md`, numbered in the order the decisions were made.
