Markdown support in the wiki is based on a parser [written in XQuery][4]. It extends the [original markdown][3] proposal with fenced code blocks and tables. These are additional features found in [Github flavored markdown][2].

# Paragraphs

Paragraphs are separated from following blocks by a blank line. 
A single line break does **not** start a new paragraph.

# Headings

A heading starts with one or more hash signs (\#) and extends to the end of the line.

# Bold, emphasis and underline

To *emphasis* a span of text, place single \* around it. Use double \*\* for stronger emphasis (**bold**). character.

# Code

## Inline

To format inline code snippets, surround them with a single backtick: `request:get-parameter()`. Use two 
backticks to allow one backtick inside: `` `ls` ``.

## Code Blocks

A triple \`\`\` on a line starts a code block, which should be closed by another \`\`\` on a single line. Following the \`\`\` one may indicate the syntax to be used for highlighting, e.g.

```
\`\`\`xquery
for $i in 1 to 10
return
    <li>{$i * 2}</li>
\`\`\`
```

This will be rendered as follows:

```xquery
for $i in 1 to 10
return
    <li>{$i * 2}</li>
```

# Lists

## Simple list

For an unordered list, start each item on a line with a \*:

* Buy milk
* Drink it
* Be happy

For an ordered list, each item should start with a number followed by a period (1.):

1. First item
2. Second item
3. Third item

## Nested list:

1. One
1. Two
    * A nested list item
    * in an unordered list.
1. Three
1. Four

# Links

Links can be specified directly or by reference. For example, \[this link\]\[1\] references a link definition given at the end of the document:

```
[1]: http://exist-db.org "eXist-db homepage"
```

A direct link is written as

```
\[link text\]\(url "optional alt text"\)
```

Here's a live example of both link types in action:

This [link][1] references a link definition given at the end of the document! And here's a direct link to the eXist [documentation](http://exist-db.org/exist/apps/docs "eXist-db Documentation").

# Images

![eXist-db Logo](http://exist-db.org/exist/apps/homepage/resources/img/existdb.gif)

Image linked through reference: ![eXist Book][5].

# Tables

A full table with headers is formatted as follows:

```
| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | **centered**  |   $12 |
| zebra stripes | are neat      |    $1 |
```

This will render as:

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | **centered**  |   $12 |
| zebra stripes | are neat      |    $1 |

You can also create a simple table without header:

```
simple table | column1 | column2
```

simple table | column1 | column2

# Inline HTML and blocks

<figure style="float: right">
    <img src="/_galleries/london.jpg" width="200"/>
    <figcaption>An HTML figure floated to the right</figcaption>
</figure>

You may inline HTML inside a block. For example, we can turn the following <span style="color: red">span of text into red</span>.

It is also possible to use HTML block-level elements, but please note that they must start and end on a new line. Anything between the start and end HTML tag will be rendered as HTML. It is thus not possible to use markdown syntax within an HTML block. For example, we may use an HTML figure element to include an image:

[1]: http://exist-db.org "eXist-db homepage"
[2]: https://help.github.com/articles/github-flavored-markdown
[3]: http://daringfireball.net/projects/markdown/syntax
[4]: https://github.com/wolfgangmm/exist-markdown
[5]: http://exist-db.org/exist/apps/homepage/resources/img/book-cover.gif "eXist Book"
