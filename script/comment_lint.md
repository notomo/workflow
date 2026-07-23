# comment rule

`make comment_lint` enforces this over `lua/` and `spec/lua/`.

- delete the comment. it restates the code and drifts away from it. express what it says as a test, a type annotation or a better name instead, and keep a comment only if a reader would otherwise undo the decision.
- a kept comment must be in English and in this form, where each entry may continue onto the following comment lines:

      -- WHY: {reason}
      -- NOT: {rejected alternative a reader would plausibly take instead}

- `NOT:` is mandatory. never invent one: a comment with no alternative to reject is a restatement or an outside fact, so delete it and, if a value or a step still needs explaining, give it a named constant or a test.
- an outside fact that stands on its own belongs in the commit message, not in the code.
- type annotations are allowed. write descriptions on the annotation line itself, not as prose lines.
- in the document sources listed in the `DOC_CONFIG` json, a `---` description directly above a declaration is kept, since it is extracted into the generated document. a `---` prose block attached to nothing is linted like anywhere else.
- `spec/lua/{plugin}/example.lua` and `spec/lua/{plugin}/doc/` are rendered into the document as they are, so they are not linted at all. put no spec there.
- a test needs no marker comment on its data (`-- 1 code, hit`, `-- line 3`). name the values, or lay the case out so the expectation is readable without one.
