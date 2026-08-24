import Scrolls
import Site.Render

/-!
# The content knowledge base, and the obligation it imposes

`content/claims.s.md` loaded at compile time, plus the mechanism that makes a
rendered claim answerable to it.

## The point of the whole experiment

`Entailed` is a proposition, and `claimCard` takes a proof of one. A page
cannot render a claim the knowledge base does not support, because the call
does not elaborate:

```
error: Tactic `native_decide` evaluated that the proposition
  Entailed "is-as-expressive-as" ["logical-english", "cobol"]
is false
```

Not a check someone remembers to run — the site does not compile. That is
what a knowledge base being an ordinary Lean value buys, and it is available
to no content system that serializes between its facts and its renderer.

The obligation is discharged by `native_decide`, which runs the solver during
elaboration. Measured at roughly 75ms per claim against a fixed cost of about
28 seconds for the domain itself, so a page may carry as many as it likes.
-/

namespace Site

open Scrolls

def claimsText : String := include_str "../content/claims.s.md"

def claims : Domain :=
  let (leText, _) := Scroll.toLE claimsText "claims"
  LE.importText leText "claims" none

def claimsWs : Workspace := Workspace.ofList [claims]
def claimsProg := (programFor claimsWs "claims" []).run' 0
def claimsCtx : CompileCtx := { ws := claimsWs, domain := "claims" }

/-- Does the content knowledge base entail this claim? -/
def entails (pred : String) (args : List String) : Bool :=
  let g := compileCall claimsCtx ⟨pred, false, args.map (.ind ·)⟩
  (solveAll claimsProg [g]).answers.length > 0

/-- The proof obligation a rendered claim carries.

Decidable by evaluation, which is what lets `native_decide` discharge it. -/
abbrev Entailed (pred : String) (args : List String) : Prop :=
  entails pred args = true

open Html

/-- The site's own words for a claim, so a card reads as prose rather than as
a tuple. The knowledge base names things the way a logic program does; a
reader should not have to.

Unlisted arguments render as themselves with hyphens opened out, which is the
right failure: a new claim shows up readable rather than blank. -/
def phrase : String → String
  | "logical-english" => "Logical English"
  | "sql" => "SQL"
  | "cypher" => "Cypher"
  | "n-ary-relations" => "n-ary relations"
  | "derived-relations" => "stored derived relations"
  | "expected-answers" => "its own expected answers"
  | "with-recursive" => "WITH RECURSIVE"
  | "star-operator" => "a path-length operator"
  | "plain-reference" => "no mechanism at all"
  | s => s.replace "-" " "

/-- A claim the knowledge base entails, rendered.

`_h` is the whole design: supplying it is the caller's problem, and the only
way to supply it is for the claim to follow. -/
def claimCard (text : String) (pred : String) (args : List String)
    (_h : Entailed pred args) : Node .flow :=
  Html.section_ [
    Html.p [Node.text text] { class_ := some "claim-text" },
    Html.p [
      Node.text "entailed by ",
      code [Node.text (pred.replace "-" " ")],
      Node.text " on ",
      Node.text (String.intercalate ", " (args.map phrase))
    ] { class_ := some "claim-src" }
  ] { class_ := some "claim" }

/-! ## The claims this site makes

Each one is checked against `content/claims.s.md` as this module compiles.
Changing the knowledge base so a claim no longer follows breaks the build,
which is the property the site exists to demonstrate. -/

/-- Logical English reaches SQL on everything the comparison covers. -/
def parityWithSql : Node .flow :=
  claimCard
    "Logical English is as expressive as SQL on every construct this page compares."
    "is-as-expressive-as" ["logical-english", "sql"]
    (by native_decide)

/-- And expresses recursion with no dedicated mechanism, where SQL needs one. -/
def recursionDirect : Node .flow :=
  claimCard
    "Logical English expresses recursion more directly than SQL: a rule naming itself, against WITH RECURSIVE and a restated base case."
    "expresses-more-directly-than" ["logical-english", "recursion", "sql"]
    (by native_decide)

/-- The same against Cypher's path-length operator. -/
def recursionVsCypher : Node .flow :=
  claimCard
    "And more directly than Cypher, which needs a path-length operator."
    "expresses-more-directly-than" ["logical-english", "recursion", "cypher"]
    (by native_decide)

/-- Cypher has no stored derived relation; both others do. -/
def storesDerived : Node .flow :=
  claimCard
    "Logical English stores derived relations, as SQL does with a view. A graph query computes one and keeps nothing."
    "stores" ["logical-english", "derived-relations"]
    (by native_decide)

/-- The claims the Rosetta page carries.

The heading is here rather than in the markdown so that it appears exactly
when there are claims under it. -/
def rosettaClaims : List (Node .flow) :=
  [ h2 [Node.text "Checked against the knowledge base"],
    Html.p [Node.text
      "Each claim below is discharged against content/claims.s.md when this \
       site compiles. Change the knowledge base so one no longer follows and \
       the build fails rather than the page going quietly out of date."]
      { class_ := some "claim-intro" },
    parityWithSql, recursionDirect, recursionVsCypher, storesDerived ]

end Site
