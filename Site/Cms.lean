import Scrolls
import Site.Render

/-!
# The CMS knowledge base

`content/cms.s.md` loaded at compile time, and the queries the site asks of
it.

## Why `include_str` rather than reading the file

The scroll is a *value*, elaborated when this module compiles. A malformed
scroll is a build error, and a query against it is an ordinary function rather
than something that can fail at request time. This is the property that makes
a Lean host worth the trouble: the knowledge base and the code that renders it
are in one program, so nothing has to serialize between them.

The path is relative to this module, which is why the loader lives in a
library module rather than in a script.

## What is here and what is not

Relatedness and undefined-concept detection are here because they are
*derived* — no YAML block can hold them, since adding a page changes what
every other page relates to.

Section and nav ordering are **not** here. They are authored in `Pages.lean`,
because an ordering is exactly what a knowledge base is bad at holding and
frontmatter is good at. Putting them here to make the demo larger would be
the trap `doc/site-spec.md` names.
-/

namespace Site

open Scrolls

/-- `content/cms.s.md`, as text, at compile time. -/
def cmsText : String := include_str "../content/cms.s.md"

/-- The CMS domain. A scroll is markdown; `Scroll.toLE` recovers the Logical
English inside it, and the importer produces the same `Domain` a `.le` file
or an `le` block would. -/
def cms : Domain :=
  let (leText, _) := Scroll.toLE cmsText "cms"
  LE.importText leText "cms" none

def cmsWs : Workspace := Workspace.ofList [cms]
def cmsProg := (programFor cmsWs "cms" []).run' 0
def cmsCtx : CompileCtx := { ws := cmsWs, domain := "cms" }

/-- Does the CMS knowledge base entail this? -/
def cmsEntails (pred : String) (args : List String) : Bool :=
  let g := compileCall cmsCtx ⟨pred, false, args.map (.ind ·)⟩
  (solveAll cmsProg [g]).answers.length > 0

/-- Every value of the one free position, for a query with a single variable.

`solveFor` needs the query variables named, which is what distinguishes a
variable the caller wants reported from one the solver merely bound on the
way. -/
def cmsAll (pred : String) (before : List String) : List String :=
  let args := before.map (Term.ind ·) ++ [Term.var "X"]
  let g := compileCall cmsCtx ⟨pred, false, args⟩
  let r := solveFor cmsProg [g] ["X"]
  (r.answers.filterMap fun a =>
    (a.bindings.find? (·.1 == "X")).map fun b => toString b.2).eraseDups

/-- Pages related to this one, derived from concepts they both explain.

A page is related to itself under the rule — it explains its own concepts — so
the page asking is dropped. That is presentation, not a fact about the domain,
which is why it is here rather than in the scroll. -/
def relatedTo (page : String) : List String :=
  (cmsAll "is-related-to" [page]).filter (· != page)

/-- Claims the content knowledge base supports that no page makes.

The seam between the two knowledge bases. `claims.s.md` knows about notations
and `cms.s.md` knows about pages; neither imports the other, so this file
names what it knows of the other rather than reaching in. The cost is one
`is available` fact per claim, and the return is that an argument sitting
unused is a query rather than something noticed on a re-read. -/
def unusedClaims : List String :=
  let g := compileCall cmsCtx ⟨"is-unused", false, [.var "C"]⟩
  let r := solveFor cmsProg [g] ["C"]
  (r.answers.filterMap fun a =>
    (a.bindings.find? (·.1 == "C")).map fun b => toString b.2).eraseDups

/-- Concepts the site leans on without explaining anywhere.

Reasoning over absence: `is-undefined` holds precisely when nothing
establishes the positive. No content system without negation can ask this. -/
def undefinedConcepts : List String :=
  let g := compileCall cmsCtx ⟨"is-undefined", false, [.var "C"]⟩
  let r := solveFor cmsProg [g] ["C"]
  (r.answers.filterMap fun a =>
    (a.bindings.find? (·.1 == "C")).map fun b => toString b.2).eraseDups

end Site
