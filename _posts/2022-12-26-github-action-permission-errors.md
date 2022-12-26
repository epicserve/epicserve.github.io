---
layout: post
title:  "Fix GitHub Action Docker Compose Permission Errors"
date:   2022-12-26 11:34:00 -0500
categories: django
---

I was working on my [Django Base Site](https://github.com/epicserve/django-base-site) project when I discovered a test
was failing in a GitHub Action when trying to run Django's `collectstatic` manager command. It was failing in Python
with the error, `PermissionError: [Errno 13] Permission denied: '/srv/app/collected_static'`.

I'll save you from all the boring details from my hours of debugging and trying to fix it. What ending up being the fix
was simply running my Docker Compose commands as root with the `-u root` argument.

Example:

```bash
docker compose run -u root --rm --no-deps web ./manage.py collectstatic --no-input
```

The reason I had to do this is that my Docker image is built using the `USER app` instruction in the Dockerfile and
according to the GitHub documentation on the Dockerfile it [says][1]:

> Docker actions must be run by the default Docker user (root). Do not use the USER instruction in your Dockerfile,
> because you won't be able to access the GITHUB_WORKSPACE. For more information, see "Using environment variables" and
> USER reference in the Docker documentation.

As a bonus, if you're debugging GitHub Actions, a fantastic tool that can save you hours of frustration is to use the
[mxschmitt/action-tmate][2] action. Instead of making a change to your Github Action YAML file and then pushing the
change and waiting to see if it passes. You can use this action to create a live interactive shell for the container
your action is running in so that you can quickly test and try new fixes.

[1]: https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions#user
[2]: https://github.com/mxschmitt/action-tmate