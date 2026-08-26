# Structured data from your text

Point an agent at your text — a contract, an article, a task description, a
`notes` column. It comes back as structured, cited data you can query with SQL
or browse as a graph — no new language to learn on day one.

When you are ready, the same data answers questions the text never states, with
a proof that quotes every step back to its source.

## Prose in, rows out

Two paragraphs of Wikipedia, encoded:

```
$ scrolls index smoking.krok
smoking  preds:54 facts:44 rules:17 individuals:34
  top predicates: is-a-disease, is-among-the-leading-causes-of, is-an-instrument

$ scrolls facts smoking.krok
smoking	le-8	is-an-instrument	cigarette
smoking	le-20	is-typically-inhaled	cigarette
smoking	le-21	is-typically-not-inhaled	pipe
…44 rows
```

Every row carries the sentence it came from — and says whether the encoding
was approximate:

```json
{"pred":"is-the-dominant-form-of-tobacco-smoking","args":["cigarette"],
 "quotes":[{"source":"article","quote":"Today, smoking is mostly practiced by rolling…"}],
 "partial":"\"Mostly\" is a graded quantifier with no Logical English counterpart…"}
```

18 of those 44 rows are marked approximate. Most extraction tools drop the
hedges silently and report full confidence. This one files a report.

## Then use what you already know

The rows are ordinary data. Load them into SQLite:

```sql
select e.type, count(*) n from arg a join entity e on e.name = a.value
group by e.type order by n desc limit 5;
```
```
estimate    14
instrument  12
disease     10
```

Nobody wrote that summary — it falls out of the structure. Binary facts are
edges and entity types are node labels, so the same tables are a property
graph without transformation.

**You can stop here.** Structured, searchable, cited data out of prose is a
complete thing to have.

## Five rungs, stop at any of them

1. **Structure** — prose becomes rows *(one new idea)*
2. **Explore** — SQL, graph, search *(no new ideas)*
3. **Consolidate** — merge concepts spelled twice
4. **Reason** — ask what the text never says
5. **Prove** — theorems the Lean kernel checks

Most people should stop after 2.

## Conclusions come with proofs

Nothing in the source says Ann is at risk:

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

Step 1 carries no quote, and that silence is a claim: it is the author's own
fact, not the article's.

Conclusions can also **go away**. Add one fact — `ann is atypical` — and a
default that held stops holding. Every database is monotonic: adding a row
never removes an answer. Real documents are full of defaults with exceptions.

## It re-checks itself

Quotes resolve against the source on every run. Rename a function a claim
depends on:

```
$ scrolls check auth.s.md
error [cite-symbol-missing] auth: rule `refresh-allowed`: symbol not found: `refreshToken`
```

The claim that broke is named. Put that in CI and the link between text and
code cannot rot quietly.

## What it's for

Three shapes, separated by **who audits the encoding**:

- **A document** — a contract or regulation, clause by clause, checkable by the
  person who knows the domain
- **A corpus** — notes, papers, or the memory an agent keeps; nobody reads all
  of it, so the value is finding what bears on a question
- **A column** — the `notes` field, the task description, the free-text comment
  every schema has. Real relational structure nobody modelled. A direction the
  project is heading rather than something it does today.

Also: **reasoning over a codebase**, where claims cite the symbol they rest on
and a rename names the claims that broke.

## Try it

```sh
git clone https://github.com/saviorand/krokodil-lean
cd krokodil-lean
lake build
./.lake/build/bin/scrolls facts examples/smoking/smoking.krok
./.lake/build/bin/scrolls why examples/cited/tobacco.krok tobacco \
  "(is-at-risk-of ann lung-cancer)"
```
