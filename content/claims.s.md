# What the site claims about the world

The content knowledge base. Not metadata about pages — the technical claims
the site's argument rests on, in a form that lets a page assert one only if it
follows.

Everything here is about notations and what they can express. A page that
renders one of these claims carries a proof obligation the compiler discharges
against this file, so the site cannot assert something this knowledge base
does not entail.

## The vocabulary

```scroll
#| templates
    *a notation* expresses *a construct*.
    *a notation* needs *a mechanism* for *a construct*.
    *a notation* stores *a construct*.
    *a notation* is as expressive as *a second notation*.
    *a notation* expresses *a construct* more directly than *a second notation*.
    *a notation* carries *a facility*.
```

## What each notation expresses

The three dialects the Rosetta page compares, and the constructs it compares
them on.

```scroll
sql expresses relations.
sql expresses joins.
sql expresses recursion.
sql expresses constraints.
sql expresses n-ary-relations.

cypher expresses relations.
cypher expresses joins.
cypher expresses recursion.
cypher expresses constraints.

logical-english expresses relations.
logical-english expresses joins.
logical-english expresses recursion.
logical-english expresses constraints.
logical-english expresses n-ary-relations.
```

Cypher has no *n*-ary relation: an edge joins exactly two nodes, and a fact of
higher arity has to be reified into a node that the author never wrote.

## What each mechanism costs

Expressing a construct and expressing it *directly* are different claims. This
is where the Rosetta page's argument actually lives.

```scroll
sql needs with-recursive for recursion.
cypher needs star-operator for recursion.
logical-english needs plain-reference for recursion.

sql needs join-on for joins.
cypher needs path-pattern for joins.
logical-english needs repeated-variable for joins.
```

## Derived relations

A view is stored; a Cypher query is not. This is one of the two rows where the
comparison favours Logical English outright.

```scroll
sql stores derived-relations.
logical-english stores derived-relations.
```

## Test suites

The other such row. Neither database carries its expectations in the schema.

```scroll
logical-english carries expected-answers.
```

## Parity, derived

Two notations are equally expressive on the evidence here when each expresses
what the other does. This is the Rosetta page's headline claim, and it is a
rule rather than an assertion.

```scroll
#| name: parity
a notation is as expressive as a second notation if
    the notation expresses a construct
    and the second notation expresses the construct.
```

## Directness, derived

One notation expresses a construct more directly than another when both
express it but only the second needs a dedicated mechanism for it. Plain
reference is not a mechanism in this sense: it is what a rule already does.

```scroll
#| name: directness
a notation expresses a construct more directly than a second notation if
    the notation needs plain-reference for the construct
    and the second notation needs a mechanism for the construct
    and it is not the case that
        the mechanism is plain-reference.
```
