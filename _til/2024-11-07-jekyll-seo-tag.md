---
layout: til
title: "Enhancing Jekyll SEO with Image Thumbnails"
date: 2024-11-07
categories: til
image:
  path: /assets/images/jekyll-seo-tag/jekyll-seo-tag.webp
  alt: "Jekyll SEO Tag Article Image"
  caption: "Photo by ChatGPT"
---

I was frustrated when sharing links on social networks because my posts weren’t displaying a thumbnail image. Then, I
discovered that Jekyll, along with the theme I’m using, automatically includes [Open Graph](https://ogp.me/) tags for
images thanks to the [jekyll-seo-tag](https://github.com/jekyll/jekyll-seo-tag) plugin.

To enable images, all I needed to do was add an `image` key to the front matter of my posts. Here’s an example:

```yaml
image:
  path: /assets/images/post-image.webp
  alt: "Post Image Alt Text"
```