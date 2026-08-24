# scrolls-site

The website for [Scrolls](https://github.com/saviorand/krokodil-lean), and an
experiment in using a scroll as a site's content layer.

```sh
lake build
./.lake/build/bin/build-site out
```

Writes a static directory. No server, no configuration.

Served from a subpath — a GitHub project page, say — set the base:

```sh
SITE_BASE=/scrolls-site ./.lake/build/bin/build-site out
```

## Deploying

`.github/workflows/deploy.yml` publishes to GitHub Pages on a push to `main`.
It checks out `krokodil-lean` and `le-lean` as siblings, because the lakefile
requires them by relative path, and caches elan and every `.lake` directory.

The workflow compiles Lean rather than running a markdown pass, which is the
whole point: the knowledge bases are compile-time values, so a claim that
stopped following fails the build before anything is published. Budget minutes
for a cold cache.

For a project page, set the repository variable `SITE_BASE` to `/<repo>`. A
user page or a custom domain needs nothing.

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

`doc/site-spec.md` is the plan; `doc/results.md` is what it found, including
where it found nothing.

## Layout

```
content/*.md        prose, readable in the repo
content/cms.s.md    what the site knows about itself
content/claims.s.md what the site claims about the world
static/site.css     the stylesheet
Site/Render.lean    markdown -> a typed HTML document
Site/Cms.lean       the CMS knowledge base, and its queries
Site/Claims.lean    the content knowledge base, and the proof obligation
Site/Pages.lean     the pages, via include_str
Main.lean           writes out/
```

## What the build reports

```
$ ./.lake/build/bin/build-site out
  mentioned but never explained: datalog
  supported but asserted nowhere: carries-expected-answers
  /         ->  out/index.html          (related: Three ways to say the same thing)
  /rosetta  ->  out/rosetta/index.html  (related: Scrolls)
```

Both absences come from rules with `it is not the case that` in them. Neither
fails the build: they are notes to an author, and the author decides. A false
*claim* is different — that stops the build.
