# What the experiment found

The site is built. This records what using a scroll as a content layer
actually cost and returned, including where it returned nothing.

Measurements are from the working repository, not estimates.

---

## The headline

**A page cannot render a claim the knowledge base does not entail.** Not a
check that runs in CI — the site does not compile.

```
error: Tactic `native_decide` evaluated that the proposition
  Entailed "expresses" ["cypher", "n-ary-relations"]
is false
```

Verified by writing that claim and watching the build stop. The mechanism is
one argument:

```lean
def claimCard (text : String) (pred : String) (args : List String)
    (_h : Entailed pred args) : Node .flow
```

`Entailed` is decidable by evaluation, so `native_decide` discharges it by
running the solver during elaboration. Supplying the proof is the caller's
problem and the only way to supply it is for the claim to follow.

This is what a knowledge base being an ordinary Lean value buys. Every other
content system — frontmatter, a headless CMS, a JSON export — connects to its
renderer by serialization, and a serialized fact cannot impose a proof
obligation on the code that reads it.

## What it cost

| | |
|---|---|
| Fixed cost, per knowledge base | ~28s to elaborate and compile the solver |
| Per proof obligation | ~75ms |
| Full site build, two knowledge bases, 4 claims | ~90s cold, seconds warm |

The per-claim cost is low enough that it never entered the design. A page may
carry as many claims as it wants.

The fixed cost is the real number, and it is per *domain*, paid whether the
domain has four facts or four hundred. Two knowledge bases is about a minute
of the build. A third would be another 28 seconds.

## What each layer returned

### Layer 2 — the CMS knowledge base

**Derived relatedness works and frontmatter cannot do it.**

```
a page is related to a second page if
    the page explains a concept
    and the second page explains the concept.
```

The "Related" block under each page is a query answer. Adding a page changes
what every other page relates to, and no YAML block can be edited to keep up.

**Reasoning over absence is the part with no equivalent anywhere.**

```
a concept is undefined if
    a page mentions the concept
    and it is not the case that
        the concept is explained somewhere.
```

The build reports `datalog` — a term the Rosetta page leans on that nothing on
the site explains. A linter cannot ask this, because the question is about
what is *not* in the corpus.

**What did not go in.** Sections and nav ordering stayed authored in
`Pages.lean`. An ordering is what a knowledge base is worst at holding and
YAML is best at, and moving it in to make the demo larger would have proved
less. The spec named this trap in advance, which is the only reason it was
avoided — the pull toward it was real.

### Layer 1 — the content knowledge base

Four claims on the Rosetta page, each discharged at compile time. Two rules do
the work: parity, and one notation expressing a construct more directly than
another.

The directness rule is the one that earned its place:

```
a notation expresses a construct more directly than a second notation if
    the notation needs plain-reference for the construct
    and the second notation needs a mechanism for the construct
    and it is not the case that
        the mechanism is plain-reference.
```

`scrolls why` returns the derivation, not just the answer:

```
logical-english expresses recursion more directly than sql, because:
  1. logical-english needs plain-reference for recursion
  2. sql needs with-recursive for recursion
```

That is the page's headline argument, derived from facts about mechanisms
rather than asserted. Changing SQL's row so it needs no mechanism would
retract the claim and break the build.

### The seam

`cms.s.md` gained `a page asserts a claim`, and with it:

```
a claim is unused if
    the claim is available
    and it is not the case that
        the claim is asserted somewhere.
```

This found something real: **`carries-expected-answers` is unused.** The
content knowledge base supports the claim that neither SQL nor Cypher carries
its own test suite, and no page makes it. An argument sitting available and
unspent, surfaced by a query rather than by re-reading.

That is the clearest evidence for the author-facing case in the spec —
*help you build up your case consistently* — and it arrived without being
looked for.

## What went wrong

**The first `unused` rule was unsatisfiable.** It said a claim is unused if it
is asserted somewhere and it is not asserted somewhere. It checked clean,
parsed fine, and proved nothing. Nothing in the toolchain flags a rule whose
body contradicts itself, and a rule that silently never fires is worse than
one that errors — the query returns no answers and the absence reads as good
news.

Separating `is available` from `is asserted somewhere` fixed it. But the class
of bug is worth naming: **a knowledge base can be well-formed, check clean,
and still assert nothing.**

**`signature-match` fires constantly and is mostly noise here.** Seven
findings on `cms.s.md`, all of the form "`is-unused` has the same signature as
`is-available`". True, and not a problem: a CMS vocabulary has many unary
predicates over the same sort. The check earns its keep in a corpus where two
names for one concept is the failure mode; in a small schema-like domain it is
chaff.

**The site's own filing system wanted into the content knowledge base.** Every
time a claim needed a page attached, the easy move was to add `a page asserts`
to `claims.s.md`. Keeping it out cost one `is available` fact per claim. Worth
it — the content vocabulary stays about notations, which is what lets it
outlive any particular page — but the pressure was constant.

## What was not tested

**Scale.** Two pages, two knowledge bases, four claims, about thirty facts.
Every finding here is real and every one is small. Whether consistency
checking pays at a hundred pages is exactly the question this could not
answer, and the honest reading is that the technique was never stressed.

**Vocabulary drift.** The spec named this as the thing to watch, and with two
knowledge bases written in one sitting by one author it did not happen.
`overlap` was never needed. This is the finding most likely to reverse at
scale.

**The code half.** With a Lean host there is no code-fact extraction step at
all, so the question the spec raised — does the Go and Java fact vocabulary
survive TypeScript — was never asked. It is still open, and still worth
asking, but not here.

## The honest summary

The mechanism works and is cheap. A site that cannot compile while asserting
something its knowledge base denies is a real property, available to no other
content stack, and it took about two hundred lines.

The findings it produced are genuine but small: one undefined term, one unused
argument. A careful editor re-reading two pages would have found both. The
case for this is that a careful editor does not scale and a query does — and
that case is *argued* here, not demonstrated, because two pages is not the
scale where it bites.

What is demonstrated is that the plumbing holds: a scroll is a compile-time
value, queries against it are ordinary functions, the answers reach the page,
and a false claim stops the build.
