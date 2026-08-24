# scrolls-site

The website for [Scrolls](https://github.com/saviorand/krokodil-lean), and an
experiment in using a scroll as a site's content layer.

```sh
lake build
./.lake/build/bin/build-site out
```

Writes a static directory. No server, no configuration.

## Why Lean

A scroll is a knowledge base *and* an ordinary Lean value. Every other content
system connects to its renderer by serialization — write facts out, read them
back, hope they still agree. Here the knowledge base and the code that renders
it are in one program, so the compiler checks the agreement:

```lean
def claimCard (pred : String) (args : List String) (_h : Entailed pred args)
    : Node .flow := ...
```

A claim the knowledge base does not entail is a **build error**, not a failed
check someone has to remember to run.

The spec is in `doc/site-spec.md`. Phase 1 — this — is prose only: no
knowledge base yet, so the site ships before the experiment starts.

## Layout

```
content/*.md     prose, readable in the repo
static/site.css  the stylesheet
Site/Render.lean markdown -> a typed HTML document
Site/Pages.lean  the pages, via include_str
Main.lean        writes out/
```
