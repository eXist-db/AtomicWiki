Markdown support in the wiki is based on a parser [written in XQuery][4]. It extends the [original markdown][3] proposal with fenced code blocks and tables. These are additional features found in [Github flavored markdown][2].

# Paragraphs

Paragraphs are separated from following blocks by a blank line. 
A single line break does **not** start a new paragraph.

# Headings

A heading starts with one or more hash signs (\#) and extends to the end of the line.

# Bold, emphasis and underline

To *emphasis* a span of text, place a single \* or _ around it. Use double \*\* or __ for stronger emphasis. For example, \*\*bold\*\* will render: **bold**.

# Code

## Inline

To format inline code snippets, surround them with a single backtick, e.g. \`1 +1\`, which renders as `1+1`. Use two backticks to allow one backtick inside: \`\`\`ls\`\`\` becomes ```ls```.

## Code Blocks

A triple backtick \`\`\` on a line starts a code block, which should be closed by another \`\`\` on a single line. Following the opening \`\`\` one may indicate the syntax to be used for highlighting, e.g.

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

## Simple List

For an unordered list, start each item on a line with a \*:

```markdown
\* Buy milk
\* Drink it
\* Be happy
```
becomes formatted as:

* Buy milk
* Drink it
* Be happy

For an ordered list, each item should start with a number followed by a period (1.):

1. First item
2. Second item
3. Third item

## Nested List

Nested lists are created by adding tabs in front of the nested list items:

1. One
1. Two
    * A nested list item
    * in an unordered list.
1. Three
1. Four

## Task List

```markdown
\* [x] write documentation
\* [ ] create tests
```

becomes

* [x] write documentation
* [ ] create tests

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

Please note that the () characters need to be escaped within a link.

## Absolute and relative links

Every link which does not contain a protocol and host part (http://...) is considered to point to a resource within the wiki space. Relative paths are relative to the current feed, absolute paths are resolved starting at the root feed of the wiki. For example, `/help/Markdown` references the article with id *Markdown* inside the *help* feed.

# Images

The syntax for images is similiar to the one for links:

```markdown
\!\[eXist-db Logo\]\(http://exist-db.org/exist/apps/homepage/resources/img/existdb.gif\)
```

inserts the eXistdb Logo:

![eXist-db Logo](http://exist-db.org/exist/apps/homepage/resources/img/existdb.gif)

You can also use a reference at the end of the document to specify the source link of the image. This works in the same way as for hyperlinks:

![eXist Book][5].

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

# Quotes

Quote paragraphs by prefixing them with a `> `:

> Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
> incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis
> nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
> Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
> eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt
> in culpa qui officia deserunt mollit anim id est laborum.

# Inline HTML and blocks

You may inline HTML inside a block. For example, we can turn the following <span style="color: red">span of text into red</span>.

HTML block-level elements are also supported, but please note that they **must** start and end on a new line, and there should not be any whitespace between the start of the line and the opening/closing element. Anything between the start and end HTML tag will be rendered as HTML. For example, we may use an HTML figure element to include an image:

```xml
<figure style="float: right">
    <img src="/_galleries/london.jpg" width="200"/>
    <figcaption>An HTML figure</figcaption>
</figure>
```

The rendered output is shown below:

<figure>
    <img src="/_galleries/london.jpg" width="200"/>
    <figcaption>An HTML figure</figcaption>
</figure>

Contrary to other markdown implementations, text inside HTML blocks will be parsed for markdown markup. You can thus mix HTML and markdown freely, as long as the closing element starts on a separate line with no whitespace in front.

[1]: http://exist-db.org "eXist-db homepage"
[2]: https://help.github.com/articles/github-flavored-markdown
[3]: http://daringfireball.net/projects/markdown/syntax
[4]: https://github.com/wolfgangmm/exist-markdown
[5]: http://exist-db.org/exist/apps/homepage/resources/img/book-cover.gif "eXist Book"