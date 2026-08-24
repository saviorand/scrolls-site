import Site

/-!
# Emitting the site

Writes one directory of static files. A page at `/rosetta` becomes
`out/rosetta/index.html`, so the URL needs no extension and no server rewrite
rule.
-/

open Site

/-- Where a page's HTML is written. `/` is the root index; everything else
gets a directory of its own. -/
def outPath (root : System.FilePath) (p : Page) : System.FilePath :=
  if p.path == "/" then root / "index.html"
  else root / (p.path.drop 1).toString / "index.html"

def main (args : List String) : IO Unit := do
  let root : System.FilePath := args.head?.getD "out"
  for p in pages do
    let target := outPath root p
    if let some dir := target.parent then
      IO.FS.createDirAll dir
    IO.FS.writeFile target (render nav p css)
    IO.println s!"  {p.path}  ->  {target}"
  IO.println s!"{pages.length} page(s)"
