---
layout: post
title: "Improving the New Django Developer Experience"
date: 2024-10-24 16:26:00 -0500
categories: django
---

<img alt="Improving the New Django Developer Experience Header Image" src="/assets/images/better-django-experience/improving-the-new-django-developer-experience-header-image.webp" width="100%">
Image created by ChatGPT

At DjangoCon 2024, I gave a lightning talk about improving the experience for new Django developers. While Django is an incredibly powerful framework, there's one aspect of the initial developer experience that I believe we can significantly enhance. Let's explore the current onboarding experience and how we might make it more intuitive for newcomers.

## The Current Django Project Setup

If you look at the official Django documentation, the tutorial instructs you to create a new project like this:

```bash
$ mkdir djangotutorial
$ django-admin startproject mysite djangotutorial
```

This creates the following directory structure:
```bash
.
├── manage.py
└── mysite
    ├── __init__.py
    ├── asgi.py
    ├── settings.py
    ├── urls.py
    └── wsgi.py
```

As someone who's both learned and taught Django, I've noticed this structure raises several questions for newcomers:

* Why create a `djangotutorial` directory only to have another directory called `mysite` inside it?
* What should the `mysite` directory be named in a real-world project?
* Why are configuration files housed in a project-named directory?
* How does this impact project maintainability, especially when version control and project renaming come into play?

## Learning from Other Frameworks

To provide context, let's look at how other modern web frameworks handle project initialization. Laravel, for instance, offers a notably streamlined experience:

<img alt="Laravel New Project Bash Session" src="/assets/images/better-django-experience/laravel-demo.gif" width="100%"/>

Laravel places all configuration files in a dedicated `config` directory:

```bash
.
...
├── config
│   ├── app.php
│   ├── auth.php
│   ├── cache.php
│   ├── database.php
│   ├── filesystems.php
│   ├── logging.php
│   ├── mail.php
│   ├── queue.php
│   ├── services.php
│   └── session.php
...
```

Compare this to the current Django experience:

<img alt="Django Start Project Bash Session" src="/assets/images/better-django-experience/django.gif" width="100%"/>

The Django CLI experience has some rough edges - error messages aren't consistently formatted, and simple issues like hyphens in project names result in errors rather than automatic conversion to underscores. The resulting structure still uses the project name for configuration files:

```bash
.
├── example_project
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```

## A Path Forward: DJ Beat Drop

While changing Django's core project templates might be challenging (as evidenced by [this PR](https://github.com/django/django/pull/15609) that's been open for two years), we can take a more pragmatic approach. I've created [dj-beat-drop](https://github.com/epicserve/dj-beat-drop), a modern Django project initializer that brings the best practices from other frameworks to the Django ecosystem.

DJ Beat Drop offers:
- A more intuitive project structure
- It uses the official Django project template, but puts all configuration files in a `config` directory
- Built-in support for environment variables via `.env` files
- Integration with modern Python tooling like `uv`
- A smoother, more user-friendly CLI experience

Here's what creating a new Django project with DJ Beat Drop looks like:

<img alt="DJ Beat Drop New Project Bash Session" src="/assets/images/better-django-experience/beatdrop.gif" width="100%"/>

With the defaults the resulting structure looks like this:
```bash
.
├── README.md
├── config
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── db.sqlite3
├── manage.py
├── pyproject.toml
└── uv.lock
```

If you say no to the defaults, then the resulting structure looks like this:
```bash
.
├── config
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```

## Join the Movement

If you're interested in improving the Django developer experience, I invite you to try DJ Beat Drop and share your feedback. With community support, this could become the recommended way to start new Django projects, making the framework even more accessible to newcomers while maintaining the power and flexibility that Django developers love.

Want to help? Star the [repository on GitHub](https://github.com/epicserve/dj-beat-drop) and share it with your fellow Djangonauts. Together, we can make the Django ecosystem even better for the next generation of developers.
