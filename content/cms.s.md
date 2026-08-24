# What the site knows about itself

The CMS knowledge base: which pages exist, what they explain, how they relate.

Frontmatter is the incumbent here and it is a strong one — four lines of YAML
per page, no templates to declare, and every static site generator already
reads it. This layer earns its place only where derivation and constraints buy
something YAML cannot express. Where it does not, the fact belongs in the
`Page` structure instead.

## The vocabulary

```scroll
#| templates
    *a page* is in *a section*.
    *a page* explains *a concept*.
    *a page* is related to *a second page*.
    *a concept* is explained somewhere.
    *a page* mentions *a concept*.
    *a concept* is undefined.
```

## The pages

Sections are authored, because an ordering is exactly what a knowledge base is
bad at holding.

```scroll
index is in overview.
rosetta is in overview.
```

## What each page explains

The one fact frontmatter could also hold — but see the rules below for what it
buys once it is here rather than there.

```scroll
index explains scrolls.
index explains provenance.
index explains proofs.
rosetta explains scrolls.
rosetta explains sql.
rosetta explains cypher.
rosetta explains recursion.
rosetta explains joins.
```

## Relatedness is derived

Two pages are related when they explain a concept in common. Nothing authors
this: adding a page changes what every other page is related to, and no YAML
block can be edited to keep up.

```scroll
#| name: related
a page is related to a second page if
    the page explains a concept
    and the second page explains the concept.
```

## A concept nobody explains

A page may *mention* a concept without explaining it. Where nothing explains
it anywhere, the site is using a term it never defines — the reader is
expected to already know.

This is reasoning over absence, and it is the thing no CMS can do: `is
undefined` holds precisely when no fact establishes the positive.

```scroll
#| name: explained
a concept is explained somewhere if
    a page explains the concept.
```

```scroll
#| name: undefined
a concept is undefined if
    a page mentions the concept
    and it is not the case that
        the concept is explained somewhere.
```

Mentions, recorded where a page leans on a term it does not define.

```scroll
rosetta mentions datalog.
```
