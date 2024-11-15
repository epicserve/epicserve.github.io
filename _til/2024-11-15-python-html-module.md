---
layout: til
title: "Who knew Python had an HTML module?"
date: 2024-11-15
categories: til
---

While one of our student engineers was fixing a bug in our HTML-to-Markdown converter, they asked why we weren't using
Python's built-in [html.unescape()](https://docs.python.org/3/library/html.html#html.unescape) function to
convert HTML entities to Unicode characters.

The reason was simple: I wasn't aware it existed. Upon investigation, I discovered that `html.unescape()` would
indeed convert HTML entities like `&nbsp;` to actual non-breaking space characters.

We ultimately decided against implementing this method right now. Currently, we're replacing `&nbsp;` with
a regular space character rather than a non-breaking space character, and using `html.unescape()` would change how
text is rendered wherever we use this function. Before making such a change, we would need spend a little more time
investigating to ensure it would benefit our users without introducing unexpected side effects.

Additionally, looking at the [source code](https://github.com/python/cpython/blob/3.13/Lib/html/entities.py) it seems
like there are lots of HTML entities that would be converted to Unicode characters. I asked Claude AI and he said
there are 2,125 entities defined. So it seems like it would be prudent to thoroughly evaluate all these potential
conversions before implementing such a change.
