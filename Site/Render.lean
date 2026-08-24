import Html
import GFMarkdown

/-!
# Markdown to a page

The site's prose is ordinary markdown, so that a page is readable in the
repository and on GitHub before anything renders it. This module turns one
such file into a complete HTML document.

Nothing here knows about knowledge bases. Phase 1 of the site is prose only,
and keeping the renderer ignorant of the later layers is what lets them be
added without rewriting it: a claim card is a `Node`, and a page that carries
one is the same page shape as a page that does not.

## Why the markdown is not typed

`GFMarkdown.renderHtml` returns a `String`, while everything else here is a
`Html.Node` whose category is checked. The seam is `Node.unsafeRaw`, which is
the one place a string re-enters the typed tree.

That is not a hole in the checking so much as a boundary of it: the markdown
renderer has its own well-formedness story, and re-parsing its output into
`Node` to prove what it already guarantees would buy nothing. The unsafety is
named at the single call site rather than spread across the module.
-/

namespace Site

open Html

/-- One page of the site, before rendering. -/
structure Page where
  /-- URL path, leading slash, no extension: `/rosetta`. -/
  path : String
  /-- Shown in `<title>` and in the nav. -/
  title : String
  /-- One sentence, for `<meta name="description">` and the nav. -/
  blurb : String
  /-- Markdown body. -/
  body : String
  /-- Extra nodes appended after the prose. Phase 1 leaves this empty; it is
      where a claim card lands once the content knowledge base exists. -/
  extra : List (Node .flow) := []

/-- The href to link this page by.

A page at `/rosetta` is written to `rosetta/index.html`, and a link to
`/rosetta` without the trailing slash only resolves because the server
redirects. Emitting the slash directly means the link is correct against a
plain file server, a CDN, and `file://` alike, none of which agree about
whether to redirect. -/
def Page.href (p : Page) : String :=
  if p.path == "/" then "/" else p.path ++ "/"

/-- Markdown to flow content.

`unsafeRaw` is the seam described in the module note: GFM renders to a string
and this is where that string re-enters the typed tree. -/
def markdown (src : String) : Node .flow :=
  Node.unsafeRaw (GFMarkdown.renderHtml (GFMarkdown.parseDocument src))

/-- The site header, identical on every page.

`current` suppresses the link to the page being rendered — a link to here is
noise, and marking it is what tells a reader where they are. -/
def header (nav : List Page) (current : String) : Node .flow :=
  Html.header [
    Html.nav [
      a { href := "/", class_ := some "brand" } [Node.text "Scrolls"],
      ul (nav.map fun p =>
        li [
          if p.path == current then
            span [Node.text p.title] { class_ := some "here" }
          else
            a { href := p.href } [Node.text p.title]
        ])
    ]
  ]

def footer : Node .flow :=
  Html.footer [
    Html.p [
      Node.text "Scrolls is ",
      a { href := "https://github.com/saviorand/krokodil-lean" }
        [Node.text "open source"],
      Node.text "."
    ]
  ]

/-- A page as a complete HTML document. -/
def render (nav : List Page) (p : Page) (css : String) : String :=
  let doc : Node .flow :=
    div [
      header nav p.path,
      main [
        article ([markdown p.body] ++ p.extra)
      ],
      footer
    ]
  -- Assembled by hand rather than through `Html.document`, because the head
  -- carries a `<style>` whose content must not be escaped.
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n" ++
  "<meta charset=\"utf-8\">\n" ++
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n" ++
  "<title>" ++ Html.escape p.title ++ "</title>\n" ++
  "<meta name=\"description\" content=\"" ++ Html.escape p.blurb ++ "\">\n" ++
  "<style>\n" ++ css ++ "\n</style>\n" ++
  "</head>\n<body>\n" ++
  Node.render doc ++
  "\n</body>\n</html>\n"

end Site
