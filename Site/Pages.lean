import Site.Render

/-!
# The site's pages

Prose lives in `content/*.md` and arrives here through `include_str`, so a
page is a value the compiler has already seen rather than a file read at run
time. A missing page is a build error.

`nav` is written out. Phase 2 replaces it with a query against the CMS
knowledge base — the ordering is the only thing that would be lost, and it is
the one thing a knowledge base is bad at.
-/

namespace Site

def index : Page where
  path := "/"
  title := "Scrolls"
  blurb := "Turn prose into something a computer can reason about."
  body := include_str "../content/index.md"

def rosetta : Page where
  path := "/rosetta"
  title := "Three ways to say the same thing"
  blurb := "The same knowledge base as SQL, as Cypher, and as Logical English."
  body := include_str "../content/rosetta.md"

def pages : List Page := [index, rosetta]

/-- Nav order, which is authored rather than derived. -/
def nav : List Page := pages

def css : String := include_str "../static/site.css"

end Site
