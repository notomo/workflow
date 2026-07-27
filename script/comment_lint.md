# comment rule

`make comment_lint` enforces this over `lua/` and `spec/lua/`.

- delete the comment. it restates the code and drifts away from it. express what it says as a test, a type annotation or a better name instead.
- before keeping one, revert the decision it defends and run the tests. a test that catches the reversal is already what stops a reader from undoing it, so name that test well and delete the comment. keep it only when the reversal survives the suite, or when the reason is an outside fact the failure cannot state on its own — what an API rejects, what a runtime forbids, what a measurement showed.
- a kept comment must be in English and in this form, where each entry may continue onto the following comment lines:

      -- WHY: {reason}
      -- NOT: {rejected alternative a reader would plausibly take instead}

- `NOT:` must name something a reader could write in its place and would expect to work: an option the API offers, an idiom, a simpler shape, a form that was tried and failed. "not writing this", "dropping the guard", "letting it raise" are the negation of the `WHY:`, not alternatives to it — a comment that can offer only those has nothing to reject, so delete it.
- never invent a `NOT:` to satisfy the form. if a value or a step still needs explaining, give it a named constant or a test.
- do not start the `WHY:` with what the next line already says. begin at the reason.
- one fact, one site. two blocks must never carry the same reason: keep it at the site no test guards, since that is the one a reader can still undo, and delete the other. a pointer comment is not a third option — a comment that only says where to look holds no reason and is deleted like any other. a reason already recorded in a machine-readable file (a mutation baseline `rationale`, say) is not repeated in the code it describes.
- an outside fact that stands on its own belongs in the commit message, not in the code.
- type annotations are allowed. write descriptions on the annotation line itself, not as prose lines.
- in the document sources listed in the `DOC_CONFIG` json, a `---` description directly above a declaration is kept, since it is extracted into the generated document. a `---` prose block attached to nothing is linted like anywhere else.
- `spec/lua/{plugin}/example.lua` and `spec/lua/{plugin}/doc/` are rendered into the document as they are, so they are not linted at all. put no spec there.
- a test needs no marker comment on its data (`-- 1 code, hit`, `-- line 3`). name the values, or lay the case out so the expectation is readable without one.
