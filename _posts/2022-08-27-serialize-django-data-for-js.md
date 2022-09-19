---
layout: post
title:  "Serialize Django Data for Javascript"
date:   2022-08-27 16:11:00 -0500
categories: django
---

Serializing Django view context data for use in Javascript is something I've
always thought should be extremely easy, but any time you have data that is more
then a simple data type like a string or an integer, it can get complicated
pretty quickly and can end up causing hard-to-solve bugs.

In most cases, if you have context data in your view like the following:

{% highlight python %}
data = [
    {
        "mystr": "Foo",
        "myint": 123,
    },
]
{% endhighlight %}

Then all you have to do to make it work in a template is to use the [safe][safe]
template filter and then it just works. Example:

{% highlight html %}
<script>
  function send_data_to_js_example(data) {
    console.assert(data[0].mystr === "Foo");
    console.assert(data[0].myint === 123);
  }
  send_data_to_js_example({% raw %}{{ data|safe }}{% endraw %});
</script>
{% endhighlight %}

But what if your data is more complex like the following example?

{% highlight python %}
data = [
    {
        "mystr": "Foo",
        "myint": 123,
        "myfloat": 123.45,
        456: "abc",
        "truebool": True,
        "falsebool": False,
        "list": ["a", 1, "b"],
        "user": {"id": 1, "name": "Joe Example"},
        "user_list": User.objects.all(),
        "date_time": now(),
        "html": '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>',
    },
]
{% endhighlight %}

Using the `safe` template filter no longer works because your booleans aren't
converted to lowercase for use in Javascript as well as some of the other data
types like the QuerySet, the Python datetime object, and your HTML string.

You might try using something like the [escapejs][escapejs] hoping
to find some easy template filter that just works. However, I'll save you the
trouble; it doesn't work and the [escapejs][escapejs] filter is only meant for
use on a single variable and not a list of dicts. You also might try using
`json.dumps()` with [Django's serialize()][serializing_objects] function, but as
I discovered this doesn't work so well for most of my use cases because the
`serialize()` function doesn't serialize the model instances in a flattened
structure and serializes the data in a more nested structure. Example:

{% highlight python %}
[
  {
    "model": "accounts.user",
    "pk": 1,
    "fields": {
      "first_name": "Joe",
      "last_name": "Example",
      "email": "joe@examle.com",
      ...
    }
  }
]
{% endhighlight %}

## The Magic Solution

So if you're wanting a Django template filter that just works, you'll have to
create your own. The following is the solution I came up with that just works
and extends Django's [DjangoJSONEncoder][DjangoJSONEncoder] encoder class which
adds the functionality to serialize QuerySets.

{% highlight python %}
class DjangoModelJSONEncoder(DjangoJSONEncoder):
    def default(self, o):
        if isinstance(o, QuerySet) is True:
            if o._iterable_class is ModelIterable:
                o = o.values()
            return list(o)
        return super().default(o)


@register.filter
def to_json(value: Any, indent: int = None):
    return mark_safe(json.dumps(value, cls=DjangoModelJSONEncoder, indent=indent).translate({
        ord(">"): "\\u003E",
        ord("<"): "\\u003C",
        ord("&"): "\\u0026",
    }))
{% endhighlight %}

With the previous `to_json` template filter created, then using it in a template
like the following just works!

{% highlight html %}
<script>
  function get_data_from_data_attribute() {
    data[0].date_time = new Date(data[0].date_time);
    console.assert(data[0].mystr === "Foo");
    console.assert(data[0].myint === 123);
    console.assert(data[0].myfloat === 123.45);
    console.assert(data[0]['456'] === "abc");
    console.assert(data[0].truebool === true);
    console.assert(data[0].falsebool === false);
    console.assert(data[0].user_list[0].last_name === "O'Connor");
    console.assert(data[0].user.id === 1);
    console.assert(data[0].date_time.toDateString() === "Sat Aug 27 2022");
    console.assert(data[0].html === '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>');
  }
  get_data_from_data_attribute({% raw %}{{ data|to_json }}{% endraw %});
</script>
{% endhighlight %}

Keep in mind if you use a Javascript framework like [Vue][Vue] or [React][React]
and you're wanting to pass your context data into a custom component, then
you'll need to use [force_escape][force_escape]. Example:

{% highlight html %}
<div id="data-div" data-data="{% raw %}{{{ data|safe|force_escape }}{% endraw %}"></div>
<script>
function get_data_from_data_attribute() {
  const divElem = document.querySelector('#data-div');
  let data = divElem.dataset.data;
  data = JSON.parse(data)
  data[0].date_time = new Date(data[0].date_time);
  ...
}
get_data_from_data_attribute();
</script>
{% endhighlight %}

## So why not use Django's json_script template tag?

The short answer is you can use the [json_script][json_script] template tag, but there are some things to consider.
First, if you look at the [actual code][json_script_code] you'll see that the filter wraps the code in a script tag
which I've found to not be necessary. Secondly, there isn't a great way to use a subclassed `DjangoJSONEncoder` that we
need if there are custom data types that the default `DjangoJSONEncoder` doesn't handle.

## What about security?

You should always be mindful of security and test your application to make sure that it hasn't created a security
exploit. I also recommend reading Django's excellent [security documentation][security_docs]. Having said that, in our
example filter, `to_json()` I'm using [mark_safe][mark_safe], which I'm fine with because I've read and know the
precautions to take. First, under no circumstances pass user-submitted data to the `to_json()` filter unless you know
the data has been sanitized with something like [bleach][bleach]. Secondly, write some tests and test your application
manually for XSS exploits.

I should also mention that in our example data we're using `User.objects.all()` for illustrative purposes only. However,
those with a keen eye might recognize that this would send the hashed password to the template, which I don't
recommend. Instead, to avoid this I recommend you something like
`User.objects.values_list('first_name', 'last_name', 'email')` or something equivalent.

## Final Thoughts
Hopefully, this post will end up saving engineers a lot of time and prevent a lot of bugs from being created. I also
hope that maybe Django could either include some of this information in the documentation or add a template filter
like `to_json` to Django that could be easily extended with your project's own default encoder.

[safe]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#std-templatefilter-safe
[escapejs]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#escapejs
[filters]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/
[serializing_objects]: https://docs.djangoproject.com/en/4.1/topics/serialization/
[DjangoJSONEncoder]: https://docs.djangoproject.com/en/4.1/topics/serialization/#djangojsonencoder
[Vue]: https://vuejs.org/
[React]: https://reactjs.org/
[force_escape]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#force-escape
[json_script]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#json-script
[json_script_code]: https://github.com/django/django/blob/ae509f8f0804dea0eea89e27329014616c9d4cc0/django/utils/html.py#L62
[security_docs]: https://docs.djangoproject.com/en/4.1/topics/security/#cross-site-scripting-xss-protection
[mark_safe]: https://docs.djangoproject.com/en/4.1/ref/utils/#django.utils.safestring.mark_safe
[bleach]: https://github.com/mozilla/bleach
