---
layout: post
title:  Use Fly.io with the Django Base Site
date:   2022-12-30 07:17:00 -0500
categories: django
---

Since Heroku no longer has a free plan, I wanted to try out [fly.io](https://fly.io/) that I've heard about as an
alternative to Heroku. For me there is no better way to try it than to use my
[Django Base Site](https://github.com/epicserve/django-base-site). In the past, I made sure that my starter template
project worked with Heroku, so it makes sense that I should try it out with a new and up and coming PaaS.

As of the writing of this blog post, these are the steps I used to deploy the Django Base Site to Fly.io.

1. [Install flyctl](https://fly.io/docs/hands-on/install-flyctl/)
2. Run `fly launch` and answer all the input prompts. Make sure you respond with `y` when it asks to set up Postgres and
   Redis. It's important to note that if you choose that you would like it to deploy now it will fail, so choose no.
   Fly.io's default configuration is to use Heroku buildpacks, which should work with the Django Base Site, but for
   whatever reason I wasn't able to get it work by using the Heroku buildpack for builder. If interested have a look at
   the steps I tried below.
   ```
   ➜ fly launch
   Creating app in /Users/brento/Sites/personal/django-base-site
   Scanning source code
   Detected a NodeJS app
   Using the following build configuration:
           Builder: heroku/buildpacks:20
   ? Choose an app name (leave blank to generate one): django-base-site
   automatically selected personal organization: Brent O'Connor
   ? Choose a region for deployment: Dallas, Texas (US) (dfw)
   Created app django-base-site in organization personal
   Admin URL: https://fly.io/apps/django-base-site
   Hostname: django-base-site.fly.dev
   Wrote config file fly.toml
   ? Would you like to set up a Postgresql database now? Yes
   ? Select configuration: Development - Single node, 1x shared CPU, 256MB RAM, 1GB disk
   Creating postgres cluster in organization personal
   Creating app...
   Setting secrets on app django-base-site-db...
   Provisioning 1 of 1 machines with image flyio/postgres:14.4
   Waiting for machine to start...
   Machine 3d8d3d7fe56989 is created
   ==> Monitoring health checks
     Waiting for 3d8d3d7fe56989 to become healthy (started, 3/3)
   
   Postgres cluster django-base-site-db created
     Username:    postgres
     Password:    <redacted>
     Hostname:    django-base-site-db.internal
     Proxy port:  5432
     Postgres port:  5433
     Connection string: postgres://postgres:<redacted>@django-base-site-db.internal:5432
   
   Save your credentials in a secure place -- you won't be able to see them again!
   
   Connect to postgres
   Any app within the Brent O'Connor organization can connect to this Postgres using the following connection string:
   
   Now that you've set up Postgres, here's what you need to understand: https://fly.io/docs/postgres/getting-started/what-you-should-know/
   
   Postgres cluster django-base-site-db is now attached to django-base-site
   The following secret was added to django-base-site:
     DATABASE_URL=postgres://django_base_site:tERgYWZ1jV2fHbJ@top2.nearest.of.django-base-site-db.internal:5432/django_base_site?sslmode=disable
   Postgres cluster django-base-site-db is now attached to django-base-site
   ? Would you like to set up an Upstash Redis database now? Yes
   ? Select an Upstash Redis plan Free: 100 MB Max Data Size
   input:3: createAddOn Validation failed: Name has already been taken
   
   ? Would you like to deploy now? No
   ```
4. Edit the `fly.toml` file the previous command created by updating the following sections to match below. Also
   make sure you replace `<app_name>` with the name of the app that was created when you ran `fly launch`.
   ```
   [build]
     dockerfile = "config/docker/Dockerfile"

   [build.args]
     ENV_NAME = "prod"

   [deploy]
     release_command = "python manage.py migrate --noinput"

   [env]
     PORT = "8080"
     ALLOWED_HOSTS = "<app_name>.fly.dev"
     INTERNAL_IPS = "<app_name>.fly.dev"
     DB_SSL_REQUIRED = "off"
   ```
5. Set the `SECRET_KEY` as a secret environment variable:
   ```
   fly secrets set SECRET_KEY=$(python -c "import random; print(''.join(random.SystemRandom().choice('abcdefghijklmnopqrstuvwxyz0123456789%^&*(-_=+)') for i in range(50)))")
   ```
6. Run `fly deploy` to deploy your app to Fly.io.
7. Run `fly ssh console` and then run `cd /srv/app && ./manage.py migrate && ./manage.py createsuperuser` to create your
   user for signing in. Exit your ssh session.
8. Run `fly open` to open the app in your browser. You won't be able to login via /accounts/login/ until you validate
   your email address. To do this, go to /admin/ and sign in. Then go to /admin/account/emailaddress/ and mark your
   email address as primary and validated. Then you should be able to sign in with the standard sign-in view. If your
   app was set up to send email, you wouldn't have to validate your email address in the admin first because when you
   sign in, the app will send you an email with a link to click on to validate your email address.
9. Hurray, you've successfully deployed to Fly.io! 🎉

## Troubleshooting

If you get a 500 error after you sign in or at any point with your running application and need to debug it, you can add
the following to your settings and then run `fly deploy`. Once the app deploys, you can trigger the 500
error again, and then when you run `fly logs`, you should be able to see a python traceback of the exception error. This
is a quick and easy solution for debugging, but a better solution for production environments is to set up something
like [Sentry](https://sentry.io/).

```
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

## Steps I tried to get Fly.io working with Heroku Buildpacks

1. I added a `requirements.txt` file in the root of the project so the Heroku Buildpack would detect that the project is
   a Python application. Inside the file I pointed to my production requirements
   file `-r config/requirements/prod_lock.txt`.
2. Then I ran `fly deploy`, which failed because it couldn't install the requirements and quit with the following error.
   ```
   ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==. These do not:
       tomli from https://files.pythonhosted.org/packages/97/75/10a9ebee3fd790d20926a90a2547f0bf78f371b2f13aa822c759680ca7b9/tomli-2.0.1-py3-none-any.whl (from coverage[toml]==7.0.1->-r /workspace/config/requirements/prod_lock.txt (line 131))
   ```
3. Next, I tried pointing the requirements to the un-hashed version of my
   requirements (`-r config/requirements/prod.in`) and then ran `fly deploy` again. This ultimately failed again, but
   this time it failed after installing the requirements and failed because it wasn't able to read the `SECRET_KEY`
   environment variable.
   ```
         File "/workspace/config/settings/_base.py", line 28, in <module>
           SECRET_KEY = env("SECRET_KEY")
         File "/app/.heroku/python/lib/python3.10/site-packages/environs/__init__.py", line 116, in method
           raise EnvError('Environment variable "{}" not set'.format(proxied_key or parsed_key))
         environs.EnvError: Environment variable "SECRET_KEY" not set

   !     Error while running '$ python manage.py collectstatic --noinput'.
         See traceback above for details.

         You may need to update application code to resolve this error.
         Or, you can disable collectstatic for this application:

         $ heroku config:set DISABLE_COLLECTSTATIC=1
   ```
4. Logically, I tried setting the `SECRET_KEY` using `fly secrets set SECRET_KEY=" <redacted>" ` and then I tried
   deploying again with `fly deploy`, but ultimately that failed again with the same error as the previous step. As
   another troubleshooting step, I also tried removing the `SECRET_KEY` with `fly secrets unset SECRET_KEY` and then
   adding it to the `[env]` section of the `fly.toml` file. This also failed with the same error when I ran
   `fly deploy`. This is where I gave up and tried the approach above by using the Django Base Site Dockerfile.

If anyone has any other ideas or can get the Django Base Site working with
fly.io [please let me know](mailto:brent@epicserve.com).

## Conclusions

It would be nice to figure out why Heroku buildpacks (the default builder) didn't work for me at some point
because I had to create a pretty sophisticated Dockerfile to get Fly.io working. It makes me wonder if
other people using Fly.io for a Django project run into the same problems or if it's just something that unique to my
Django Base Site.

If you want to deploy a hobby project to the world quickly then Fly.io seems like a good choice. Especially with its
free plan. One of the things I liked about Fly.io is that it has intelligent caching. If you haven't made changes to
project requirement files, it deploys quickly (less than a minute), which is very nice!
