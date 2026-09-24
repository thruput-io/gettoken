# 28. Report, threshold, and check build model

## Context

A quality tool invoked directly from a Make recipe answers only "pass" or "fail".
There are so many ways to get that wrong that this record exists to lower the
risk of it happening. Hidden lint and test errors are the most harmful failures
there are: they fail entire projects.

## Decision

This record is followed as written, without interpretation.

Every quality tool is wired as a three-stage chain of Make targets: report,
threshold, check. The stages are separate targets, not steps inside one recipe.
Where this record calls for a clean invocation, other rules bend to it:
cleanliness that prevents obfuscation always takes precedence. Defaulting of any
kind is not allowed.

A quality tool is, among others: a test runner with its test result, a coverage
collector with its coverage, a linter with its lint result, a schema verifier
with its report.

### The invocation stays clean

The invocation is as simple and clear as possible: no indirection, chaining,
piping, other tricks, or variables.

Good: `test: test-tool -R src/test > build/test-report.json`

Bad: `test: test-tool $(params) $(SOURCES) | jq 'result' > build/test-report.json`

### 1. Report

The tool runs and its native output lands at `build/<tool>-report.<ext>`.

The report lands untouched. No normalisation, filtering, reformatting or
merging: a report that has been rewritten is no longer evidence of what the tool
found.

The report stage does not judge. A tool that exits non-zero because it found
something still leaves its report, and the check will see what it found and
fail. No exit code is defaulted or rewritten to move a decision into the check.
`.DELETE_ON_ERROR` is not used. The reports are the proof that nobody has
tampered with the pipeline. A tool that crashes does not leave a truncated
report, or it is highly unlikely that it does, and deleting reports on error
would destroy that proof to guard against a false positive.

### 2. Threshold

Threshold constants are written directly in the `.checked` recipe where they are
evaluated.

A threshold is never moved to make a build pass. Changing one is a reviewable
change to the repository's quality bar.

### 3. Check

`build/<tool>.checked` reads the report in place.

The check prints one line stating measured against allowed, so the build log
records the quality position and not merely a verdict.

The check asserts coverage as well as violation counts. A report may not pass by
having examined nothing.

`[ a -gt b ] && [ c -eq d ]` is the only form for combining conditions: simple
variables or constants, one comparator each, and only `&&` between conditions.

`.checked` produces no file. The comparison is cheap, so it runs every time;
the targets are phony.
