import Site

/-!
# Emitting the site

Writes one directory of static files. A page at `/rosetta` becomes
`out/rosetta/index.html`, so the URL needs no extension and no server rewrite.

The related-pages list on each page comes from the CMS knowledge base
(`Site.Cms`), not from anything authored here: two pages are related when they
explain a concept in common, and that is a rule rather than a list.
-/

open Site

/-- Where a page's HTML is written. `/` is the root index; everything else
gets a directory of its own. -/
def outPath (root : System.FilePath) (p : Page) : System.FilePath :=
  if p.path == "/" then root / "index.html"
  else root / (p.path.drop 1).toString / "index.html"

/-- A page's id in the knowledge base: the path without its slash, and
`index` for the root. The scroll names pages the way an author would, not the
way a URL does. -/
def pageId (p : Page) : String :=
  if p.path == "/" then "index" else (p.path.drop 1).toString

def main (args : List String) : IO Unit := do
  let root : System.FilePath := args.head?.getD "out"

  -- Reported rather than enforced: the site still builds, and a term the
  -- prose leans on without defining is a note to the author, not an error.
  let undef := undefinedConcepts
  unless undef.isEmpty do
    IO.println s!"  concepts mentioned but never explained: {String.intercalate ", " undef}"

  for p in pages do
    let ids := relatedTo (pageId p)
    let related := pages.filter fun q => ids.contains (pageId q)
    let target := outPath root p
    if let some dir := target.parent then
      IO.FS.createDirAll dir
    IO.FS.writeFile target (render nav p css related)
    let note := if related.isEmpty then "" else
      s!"  (related: {String.intercalate ", " (related.map (·.title))})"
    IO.println s!"  {p.path}  ->  {target}{note}"
  IO.println s!"{pages.length} page(s)"
