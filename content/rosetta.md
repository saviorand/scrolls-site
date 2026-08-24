# It reads like English. It's as rich as your database.

A scroll's claims are written as sentences a domain expert can check. That
wording is a real advantage, but it invites a wrong conclusion: that something
readable must be less capable than SQL or Cypher.

It isn't. Below is the same knowledge base written three ways, from schema
through recursive join to the answer. The Logical English column is verbatim
from [`examples/scroll/tobacco.s.md`](https://github.com/saviorand/krokodil-lean/blob/main/examples/scroll/tobacco.s.md).

## Declaring the schema

All three declare typed structure up front. A template's noun phrases *are*
its types — `*a person* smokes *a product*` types both positions in the act of
naming the relation.

**SQL**

```sql
CREATE TABLE smokes (
  person   TEXT REFERENCES person(id),
  product  TEXT REFERENCES product(id)
);
CREATE TABLE is_made_from (
  product  TEXT REFERENCES product(id),
  material TEXT REFERENCES material(id)
);
```

**Cypher** — relationship types are convention, not schema.

```cypher
CREATE CONSTRAINT FOR (p:Person) REQUIRE p.id IS UNIQUE;
// (:Person)-[:SMOKES]->(:Product)
// (:Product)-[:MADE_FROM]->(:Material)
```

**Logical English**

```
*a person* smokes *a product*.
*a product* is made from *a material*.
*a material* contains *a chemical*.
*a chemical* causes *a disease*.
*a person* is at risk of *a disease*.
```

Parity, with one asymmetry: SQL and LE both declare typed positions, Cypher
does not. LE gets its types from the nouns the author already wrote, so the
declaration and the documentation are the same artifact.

## A three-way join

Who is at risk of what. The relation spans four tables and is stored nowhere —
every dialect computes it.

**SQL**

```sql
CREATE VIEW is_at_risk_of AS
SELECT DISTINCT s.person, c.disease
  FROM smokes s
  JOIN contains_t ct ON ct.whole = s.product
  JOIN causes c ON c.chemical = ct.chemical;
```

**Cypher**

```cypher
MATCH (p:Person)-[:SMOKES]->(prod)-[:MADE_FROM*0..]->()
      -[:CONTAINS]->(ch:Chemical)-[:CAUSES]->(d:Disease)
RETURN DISTINCT p.id, d.id
```

**Logical English**

```
a person is at risk of a disease if
    the person smokes a product
    and the product contains a chemical
    and the chemical causes the disease.
```

All three express one three-way join. SQL names the join keys, Cypher walks a
path, LE binds by reusing the noun. **The joins are not hidden — they are the
repeated words**, which is why a domain expert can verify the logic without
knowing what a join is.

## Recursion

A product contains what its materials contain, to any depth. This is the query
most often cited as the reason to leave SQL for a graph database.

**SQL** needs a `UNION` and a restated base case.

```sql
WITH RECURSIVE contains_t(whole, chemical) AS (
  SELECT whole, chemical FROM contains
  UNION
  SELECT m.product, t.chemical
    FROM is_made_from m JOIN contains_t t ON t.whole = m.material
)
SELECT * FROM contains_t;
```

**Cypher** needs path-length syntax.

```cypher
MATCH (p:Product)-[:MADE_FROM*0..]->()-[:CONTAINS]->(c:Chemical)
RETURN DISTINCT p.id, c.id
```

**Logical English** needs nothing.

```
a product contains a chemical if
    the product is made from a material
    and the material contains the chemical.
```

The rule mentions `contains` in its own body and that is the entire mechanism.
No `WITH RECURSIVE`, no `*` operator, no base case written twice. **Here
recursion is what a sentence does when it refers to itself.**

## The concept map

| Concept | SQL | Cypher | Logical English |
|---|---|---|---|
| Relation | table | relationship type | template |
| Tuple | row | edge | a sentence |
| Type | column type + FK | node label | the slot's noun |
| Join | `JOIN … ON` | path pattern | a repeated variable |
| Derived relation | `VIEW` | *(none)* | a rule |
| Recursion | `WITH RECURSIVE` | `*0..` | a rule naming itself |
| Disjunction | `UNION` / `OR` | `OR` | two rules, same head |
| Constraint | `CHECK` | `CREATE CONSTRAINT` | `it must not be the case that …` |
| Test | *(external)* | *(external)* | a scenario + expected answers |

Two rows favour LE outright: a graph database has no stored derived relation,
and neither SQL nor Cypher carries its own test suite in the schema file.

## And then it does something they can't

Parity established, here is what `scrolls why` actually printed:

```
ann is at risk of lung-cancer, because:
  1. ann smokes pipe-tobacco                    ← our claim, not the article's
  2. pipe-tobacco contains tar, because:
    1. pipe-tobacco is made from tobacco-leaf   [article:3]
    2. tobacco-leaf contains tar                [article:5]
  3. tar causes lung-cancer                     [article:7]
```

Neither database can produce this, because neither kept the reason. Every step
cites its source, the citations are re-checked on every run, and step 1's
silence records it as the author's own inference.
