# Turn prose into something a computer can reason about

Most of what you know is prose. Specs, contracts, papers, runbooks, the memory
file your agent keeps. A computer can search it and summarize it. It cannot
tell you whether a conclusion follows from it, what it would take for one to
follow, or when a claim about it stopped being true.

A **scroll** is a markdown file — `.s.md`, renders anywhere — where the prose
stays and the claims it makes are *also* written down in a form a solver can
execute. As English sentences a domain expert can check, each carrying the
words it came from.

```
$ scrolls check auth.s.md
ok — 1 domain(s), 0 finding(s)
```

Now someone renames a function the document describes:

```
$ scrolls check auth.s.md
error [cite-symbol-missing] auth: rule `refresh-allowed`: symbol not found: `refreshToken`
```

The claim that broke is named. Nothing else is touched, and the document has
stopped asserting something that is no longer true. Put that in CI and the
link between text and code cannot rot quietly.

## Conclusions come with proofs

Ask something the document never states:

```
$ scrolls why tobacco.s.md tobacco "(is-at-risk-of ann lung-cancer)"

provable:
  ann is at risk of lung-cancer, because:
    1. ann smokes pipe-tobacco
    2. pipe-tobacco contains tar, because:
      1. pipe-tobacco is made from tobacco-leaf  [article:3] "Pipe tobacco is made from cured tobacco leaf."
      2. tobacco-leaf contains tar  [article:5] "Tobacco leaf contains tar"
    3. tar causes lung-cancer  [article:7] "Tar causes lung cancer."
```

Nothing in the source says Ann is at risk, and the middle step — that pipe
tobacco contains tar — had to be worked out.

**Step 1 carries no quote, and that silence is a claim.** `ann smokes
pipe-tobacco` is the author's own fact rather than the article's. The proof
keeps that distinction instead of presenting everything as the source's word.

## What it's for

- **Reasoning over a codebase** — claims about how a system works, each citing
  the symbol it rests on
- **Agent memory** — a `CLAUDE.md` that can fail, instead of one that silently
  goes stale
- **Encoding a document that matters** — a contract or regulation, clause by
  clause, checkable by the person who knows the domain

## Try it

```sh
git clone https://github.com/saviorand/krokodil-lean
cd krokodil-lean
lake build
./.lake/build/bin/scrolls why examples/scroll/tobacco.s.md tobacco \
  "(is-at-risk-of ann lung-cancer)"
```
