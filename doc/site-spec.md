# The Scrolls site — specification

A marketing site for Scrolls, built as three knowledge bases and a Lean
frontend that consumes them. The site has to exist anyway; building it this
way tests whether a scroll can serve as a content layer, and whether being an
ordinary Lean value buys anything a JSON export would not.

Measurements below were taken against a working prototype, not estimated.

---

## 1. The claim being tested

A scroll is a knowledge base *and* a Lean value. Every other content system —
frontmatter, a headless CMS, a JSON blob — connects to its renderer by
serialization: write facts out, read them back, hope they still agree. A
scroll and the code that renders it can instead be **in the same program**,
where the compiler checks the agreement.

The site is the smallest honest test of that: a real corpus, a real codebase,
at a scale where a wrong answer costs an afternoon.

## 2. Three knowledge bases

Separate because they have different vocabularies, different authors, and
different lifetimes. Keeping them apart is what lets each be judged on its
own.

### Layer 1 — content

What the site claims about the world: that Logical English reaches SQL on
recursion, that a graph database has no stored derived relation, that five
truth states are distinguished rather than two.

```
*a notation* expresses *a construct*.
*a construct* needs *a mechanism* in *a notation*.
*a notation* is as expressive as *a second notation*.
```

Technical claims with technical content, which two pages can contradict.
This is the half of Scrolls the smoking example tests, pointed at the site's
own argument.

### Layer 2 — CMS

What the site knows about itself: pages, sections, concepts.

```
*a page* is in *a section*.
*a page* explains *a concept*.
*a page* is related to *a second page*.
```

**Frontmatter is the incumbent and it is strong.** Four lines of YAML, no
templates, every generator already reads it. The layer earns its place only
through derivation and constraints — and it does, measurably: see §4.

### Layer 3 — presentation

Components, routes, rendering. A Lean frontend on `lean-html` and
`lean-markdown`, with no CMS concerns inside it.

**Layer 3 is not a third knowledge base.** It is where the other two are
consumed and enforced. This is the change the prototype forced: with a Lean
host there is no code-fact extraction step, because the code and the
knowledge base are already in one program.

## 3. What the prototype established

All four results are from working code at `scratchpad/lhtest/`.

### The stack composes

Scrolls, `lean-html` v0.8.0 and `lean-markdown` v0.5.0 build together on Lean
**4.33** — 92 jobs, no errors. Latest tags of both; no release candidate
required.

`lake update` rewrites `lean-toolchain` to match a dependency's. It must be
pinned back after every update or the repo drifts to an rc on its own.

### A renderer can demand a proof

```lean
abbrev Entailed (p : String) (args : List String) : Prop :=
  entails p args = true

def claimCard (pred : String) (args : List String) (_h : Entailed pred args)
    : Node .flow := ...
```

Entailed claim compiles and renders:

```
claimCard "is-as-expressive-as" ["logical-english", "sql"] (by native_decide)
→ <div><p>is as expressive as</p><ul><li>logical-english</li><li>sql</li></ul></div>
```

Unentailed claim fails the build:

```
error: Tactic `native_decide` evaluated that the proposition
  Entailed "is-as-expressive-as" ["logical-english", "cobol"]
is false
```

**This is the finding.** Not "citations are re-checked on every run" but *the
site does not compile*. No serialization step, no CI script to remember.

### Proof obligations are effectively free

| Proofs | Wall clock |
|---|---|
| 0 | 28.5s |
| 12 | 26.6s |
| 48 | 32.1s |

About **75ms per obligation**, against ~28s of fixed cost — elaborating the
`le` block and compiling the solver, paid once. A site with hundreds of
checked claims stays practical, and the design need not work around
`native_decide`.

### Derived navigation works

`is-related-to` computed from shared concepts, never authored:

```
relatedTo "rosetta"   → [intro, rosetta, theory, memory]
relatedTo "citations" → [citations, extract]
```

Correct in both directions — `rosetta`/`publish` is false, sharing no
concept.

## 4. Where each layer earns its place

**Layer 1.** Two pages asserting incompatible things about the same
capability; a comparison claiming parity the worked example does not show; a
count stated one way in the pitch and another in the theory page. No existing
tool checks these, because doing so needs negation and constraints over what
the writing asserts.

**Layer 2.** Derived relatedness (measured above), plus queries over absence —
a concept used but defined nowhere, a section with no pages. Constraints
replace lint rules: *it must not be the case that a page is published and has
no description.*

**Layer 3.** The proof obligation above, and the same mechanism applied to
routes.

## 5. Deliberately excluded

**A `publish` command.** The site repo gets a generator. If it generalizes,
the feature follows from evidence rather than from wanting one.

**Code fact extraction.** [code-substrate.md](https://github.com/saviorand/krokodil-lean/blob/main/doc/code-substrate.md) settled the
vocabulary for extracted code facts, and the Go and Java extractors fill it.
A Lean frontend needs none of it: there is no serialization gap to bridge.
Whether the vocabulary survives TypeScript remains an open question — it is
simply not this experiment's question.

**Frontmatter replacement for its own sake.** Section, ordering, status and
asset paths stay in YAML where they are cheapest. An encoding a linter or a
`find` could answer is not testing anything.

**Anything numeric or presentational.** Dates, widths, image paths.

## 6. Repository layout

Three knowledge bases, one frontend. Whether these are three repositories or
three directories is a decision to make once there is something in them; the
point is three vocabularies with three lifetimes.

```
scrolls-site/
  Content.lean      layer 1 — `le content "..."`
  Cms.lean          layer 2 — `le cms "..."`
  Site/
    Page.lean       typed page, demands Entailed
    Render.lean     markdown → html
    Nav.lean        derived from Cms
  content/*.s.md    prose
  Main.lean         emits the site
```

The content and CMS knowledge bases are authored as `.s.md` and loaded at
compile time:

```lean
def contentText : String := include_str "content.s.md"

def content : Domain :=
  let (leText, _) := Scroll.toLE contentText "content"
  LE.importText leText "content" none
```

Verified against `examples/scroll/tobacco.s.md`: 5 predicates, 6 rules, 0
errors, and a `native_decide` theorem over the result type-checks. Prose and
knowledge stay in one markdown file that renders on GitHub, and the domain is
still a compile-time value.

Two constraints found in testing. `include_str` resolves relative to the
module, so this must live in a **library module** rather than a script run
through `lake env lean`. And `le` is a reserved keyword from the DSL, so it
cannot be used as a local binding name.

There is **no `scroll` command** corresponding to `le` — nothing elaborates a
`.s.md` path directly into a `Domain`. The `include_str` form above is three
lines and needs no new syntax, but a `scroll content "content.s.md"` command
would be the obvious convenience if this pattern recurs.

## 7. Sequencing

**Phase 1 — the site ships.** Ordinary pages, hand-authored, on the Lean
stack. No knowledge base required. The pitch does not wait on the experiment
and the experiment gets a real corpus.

**Phase 2 — layer 2, the CMS.** Cheapest to encode, and derived navigation is
already proven. Nav and related-pages come from queries. First real use.

**Phase 3 — layer 1, the content.** Encode the technical claims the site
makes. Renderers demand `Entailed`. This is the phase that either finds
inconsistencies worth the encoding or does not, and either result is worth
writing down.

**Phase 4 — the seams.** Claims tied to the pages that assert them; pages to
the components that render them. The question that only becomes askable here:
*this component changed — which claims does it affect the presentation of?*

**Phase 5 — the write-up.** What worked, what it cost, whether a scroll is a
good content layer. Publishable whichever way it falls.

## 8. Risks

**The corpus may be too small.** A few dozen claims may sit below the scale
where consistency checking pays. If so, knowing where the technique starts to
work is the finding.

**`native_decide` puts the compiler in the trusted base.** Measured as cheap;
for a website the trust question is unobjectionable, but it should be said
rather than discovered.

**Encoding is manual.** [vision.md](https://github.com/saviorand/krokodil-lean/blob/main/doc/vision.md) is straight about this: no
`scrolls encode`, no pipeline. A few dozen claims is an afternoon.

**The vocabulary problem, in miniature.** Three vocabularies referring to the
same page, claim and symbol is the drift problem from [vision.md](https://github.com/saviorand/krokodil-lean/blob/main/doc/vision.md)
at small scale. A Lean host removes part of it — the module system does the
coordinating an upper ontology would otherwise buy — but not the part where
two authors name one concept differently. `overlap` exists for that.

**Layer 2 is the seductive one.** Easiest to encode, most visible results,
and the easiest place to avoid comparing honestly against YAML. If the
experiment's headline ends up being derived navigation, that is a warning
rather than a success.
