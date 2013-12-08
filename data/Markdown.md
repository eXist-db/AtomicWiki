# Supported Markdown syntax

The parser extends the [original markdown][3] proposal with fenced code blocks and tables. These are additional features found in [Github flavored markdown][2].

## Paragraphs
Paragraphs are separated from following blocks by a blank line. 
A single line break does **not** start a new paragraph.

Lorem ipsum dolor sit amet, `consectetur` adipiscing elit. Curabitur nec lobortis magna. Fusce vestibulum felis a eros suscipit mattis. Pellentesque sit amet enim libero. Sed sed tempus nibh. Ut pellentesque quam ac bibendum iaculis. Suspendisse **vitae** interdum risus, [convallis auctor](/WikiIntro) urna. Mauris vel sapien ut sapien mollis rhoncus non a nibh. Nullam vulputate consequat purus, ut varius justo ornare vel. Etiam ornare diam at velit varius volutpat. Mauris vel luctus mi, at fermentum purus. *Vestibulum ante ipsum* primis in faucibus orci luctus et ultrices posuere cubilia Curae; Cras lobortis est dolor, et tristique lorem egestas vitae. Sed feugiat dictum nunc. Nullam ultricies vehicula aliquam. Cras felis ante, ultrices sed lacinia et, pharetra in tellus. Vivamus scelerisque ut mi a dapibus.

## Code

To format inline code snippets, surround them with a single backtick: `request:get-parameter()`. Use two 
backticks to allow one backtick inside: `` `ls` ``.

## Lists

### Simple list

* Buy milk
* Drink it
* Be happy

### Nested list:

1. One
1. Two
    * A nested list item
    * in an unordered list.
1. Three
1. Four

## Links

Links can be specified directly or by reference.

This [link][1] references a link definition given at the end of the document ! And here's a direct link to the eXist [documentation](http://exist-db.org/exist/apps/docs "eXist-db Documentation").

## Images

![eXist-db Logo](http://exist-db.org/exist/apps/homepage/img/existdb.gif)

Image linked through reference: ![Read more][glasses].

## Code Blocks

```xquery
for $i in 1 to 10
return
    <li>{$i * 2}</li>
```

## Table

| Tables        | Are           | Cool  |
| ------------- |:-------------:| -----:|
| col 3 is      | right-aligned | $1600 |
| col 2 is      | **centered**  |   $12 |
| zebra stripes | are neat      |    $1 |

Another simple table:

simple table | column1 | column2

[1]: http://exist-db.org "eXist-db homepage"
[2]: https://help.github.com/articles/github-flavored-markdown
[3]: http://daringfireball.net/projects/markdown/syntax
[glasses]: http://exist-db.org/exist/apps/homepage/img/view.png "Documentation"
