---
layout: post
title:  "Serialize Django Data for Javascript"
date:   2022-08-27 16:11:00 -0500
categories: jekyll update
---
So you have a Django view with some data that you want to use in some
Javascript code, and you're thinking that will be easy to pass the data from
your Django view to Javascript. Well you're right in one sense, it's "easy" in
most cases; but in another sense it can become hard and headache-inducing,
depending on the data types that you're passing to Javascript and there are some
edge cases to think about that have caused some pain for us at
[Canopy](https://canopyteam.org).

Let's dive in and look at some code. Let's say you have the following Django
view that I'm using for illustrative purposes only. Hopefully, you'll notice in
my example I have a data variable that is a list of dicts with one dict that has
a lot of different data types, so that we can illustrate some of the issues that
come into play with different data types.

{% highlight python %}
def send_data_to_js_example(request):
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
    return render(request, "send_data_to_js_example.html", {"data": data})
{% endhighlight %}

With the following template `send_data_to_js_example.html`.

{% highlight html %}
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset=UTF-8>
    <title>Send data to js example</title>
  </head>
  <body>
    <script>
      function send_data_to_js_example(data) {
        console.assert(data[0].mystr === "Foo");
        console.assert(data[0].myint === 123);
        console.assert(data[0].myfloat === 123.45);
        console.assert(data[0]['456'] === "abc");
        console.assert(data[0].truebool === true);
        console.assert(data[0].falsebool === false);
        console.assert(data[0].user_list[0] === [{"a": 1, "name": "Joe Example"}]);
        console.assert(data[0].user.id === 1);
        console.assert(data[0].html === '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>');
        console.assert(data[0].user_list[0].last_name === "Example");
      }
      send_data_to_js_example({% raw %}{{ data }}{% endraw %});
    </script>
  </body>
</html>
{% endhighlight %}

So in this first example that we start with we try to pass the data into the
Javascript function without doing anything to the context data. Which would get
rendered like this:

{% highlight html %}
send_data_to_js_example([{&#x27;mystr&#x27;: &#x27;Foo&#x27;, &#x27;myint&#x27;: 123, &#x27;myfloat&#x27;: 123.45, 456: &#x27;abc&#x27;, &#x27;truebool&#x27;: True, &#x27;falsebool&#x27;: False, &#x27;list&#x27;: [&#x27;a&#x27;, 1, &#x27;b&#x27;], &#x27;user&#x27;: {&#x27;id&#x27;: 1, &#x27;name&#x27;: &#x27;Joe Example&#x27;}, &#x27;user_list&#x27;: &lt;QuerySet [&lt;User: user&gt;, &lt;, &#x27;...(remaining elements truncated)...&#x27;]&gt;, &#x27;date_time&#x27;: datetime.datetime(2022, 8, 27, 15, 22, 54, 684497, tzinfo=&lt;UTC&gt;), &#x27;html&#x27;: &#x27;&lt;p class=&quot;m-100 float-left random modifier p-100 spacer-5 john-b-good&quot;&gt;My &lt;strong&gt;Paragraph&lt;/strong&gt;&lt;/p&gt;&#x27;}]);
{% endhighlight %}

Obviously this isn't what we want because this will throw the following console
error because the browser Javascript interpreter can't parse the data because of
all the different HTML entities (e.g. `&#x27;, &gt;, &lt;`) that Django uses to
escape the data because it wasn't marked as safe. Django does this to protect
against [XSS][django_xss_exploits] exploits.

```
Uncaught SyntaxError: expected property name, got '&'
```

So now you might be thinking, "I know that the data context variable is safe
because it wasn't created by a user, so I'll just go ahead and change my
template so I'm using the
[safe template filter][safe] (e.g. `{% raw %}{{ data|safe }}{% endraw %}`". This
is some logical thinking, which can work if your context variable is very simple
and only has strings and integers. However, let's look at how it renders
our data.

{% highlight html %}
send_data_to_js_example([{'mystr': 'Foo', 'myint': 123, 'myfloat': 123.45, 456: 'abc', 'truebool': True, 'falsebool': False, 'list': ['a', 1, 'b'], 'user': {'id': 1, 'name': 'Joe Example'}, 'user_list': <QuerySet [<User: user>, '...(remaining elements truncated)...']>, 'date_time': datetime.datetime(2022, 8, 27, 15, 19, 32, 372419, tzinfo=<UTC>), 'html': '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>'}]);
{% endhighlight %}

This is better, because we don't have everything escaped with HTML entities.
However, this ends up also throwing another console error
(`Uncaught SyntaxError: missing variable name`) and if you take a look at the
rendered data you'll see that it's clearly not what you want. The first thing
you'll notice is that the boolean variables aren't lowercase which is correct
for Python, but not Javascript. Basically any variable type that isn't a string
or an integer isn't converted correctly.

Next, you might notice in the Django documentation for [filters][filters] that there is an
[escapejs][escapejs] filter and you might want to try that filter combined with
the `safe` (e.g. `{% raw %}{{ data|safe|escapejs }}{% endraw %}`) thinking that
Django will just magically escape and render your data correctly for Javascript.
However, the following is how your data gets rendered.

{% highlight html %}
send_data_to_js_example([{\u0027mystr\u0027: \u0027Foo\u0027, \u0027myint\u0027: 123, \u0027myfloat\u0027: 123.45, 456: \u0027abc\u0027, \u0027truebool\u0027: True, \u0027falsebool\u0027: False, \u0027list\u0027: [\u0027a\u0027, 1, \u0027b\u0027], \u0027user\u0027: {\u0027id\u0027: 1, \u0027name\u0027: \u0027Joe Example\u0027}, \u0027user_list\u0027: \u003CQuerySet [\u003CUser: user\u003E, \u0027...(remaining elements truncated)...\u0027]\u003E, \u0027date_time\u0027: datetime.datetime(2022, 8, 27, 15, 40, 11, 37302, tzinfo\u003D\u003CUTC\u003E), \u0027html\u0027: \u0027\u003Cp class\u003D\u0022m\u002D100 float\u002Dleft random modifier p\u002D100 spacer\u002D5 john\u002Db\u002Dgood\u0022\u003EMy \u003Cstrong\u003EParagraph\u003C/strong\u003E\u003C/p\u003E\u0027}]);
{% endhighlight %}

This isn't at all what we want, mainly because the [escapejs][escapejs] is only
for escaping a single variable and not a nested list of dicts with different
data types.

At this point you might start to get a little frustrated because you're thinking
this has got to a common thing that everyone needs to do. Why isn't there a
filter that just works?! 😖 Then you might look at your data and think, of
course, we have data types like a QuerySet in our data that needs to be escaped.
So you do a quick Google search for "Django serialize QuerySet" and discover
Django's documentation on [serializing objects][serializing_objects] and you
also remember that Python has the builtin serializer for json (`json.dumps()`)
so you decide to change your Django view to the following.

{% highlight python %}
def send_data_to_js_example(request):
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
            "user_list": serializers.serialize("json", User.objects.all()),
            "date_time": now(),
            "html": '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>',
        },
    ]
    data = json.dumps(data)
    return render(request, "send_data_to_js_example.html", {"data": data})
{% endhighlight %}

Except this doesn't work because it ends up throwing a Python exception error,
`Object of type datetime is not JSON serializable`!

![Rage Gif](https://media.giphy.com/media/22CEvbj04nLLq/giphy.gif)

Now you're ticked and thinking I have four years of college in computer science
and lots of experience, why the hell is this so damn hard for something that
should be so simple. But you're determined and start doing some
Google (or Duck Duck Go) searching on the exception error. So after some
searching you discover [DjangoJSONEncoder][DjangoJSONEncoder] and you try it
out with the following code.

{% highlight python %}
def send_data_to_js_example(request):
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
            "user_list": serializers.serialize("json", User.objects.all()[:1]),
            "date_time": now(),
            "html": '<p class="m-100 float-left random modifier p-100 spacer-5 john-b-good">My <strong>Paragraph</strong></p>',
        },
    ]
    data = json.dumps(data, cls=DjangoJSONEncoder)
    return render(request, "send_data_to_js_example.html", {"data": data})
{% endhighlight %}

But then what happens is that the `user_list` value has been turned into a JSON
string from using Django's `serialize()` funct and then when it's serilaized
again with `json.dumps()` it ends up just being an escaped string that isn't a
Javascript object literal like we want it to be.

So now you're getting smart and thinking you'll make a utility function that I
can just reuse anytime I need this same functionality. So then after some trial
and error you might end up with something like the following.

{% highlight python %}
class DjangoModelJSONEncoder(DjangoJSONEncoder):
    def default(self, o):
        if isinstance(o, QuerySet) is True:
            return json.loads(serializers.serialize("json", o))
        return super().default(o)


def to_json(value: Any, indent: int = None):
    return json.dumps(value, cls=DjangoModelJSONEncoder, indent=indent)


def send_data_to_js_example(request):
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
        }
    ]
    data = to_json(data)
    return render(request, "send_data_to_js_example.html", {"data": data})
{% endhighlight %}

Finally, we're getting somewhere and when rendered we only have a couple
assertion errors in the console. So let's try and deal with those. The first
assertion that fails is because when we use `serializers.serialize("json", o)`
in our `DjangoModelJSONEncoder` class it renders the `QuerySet` in the
following way:

{% highlight python %}
"user_list": [
  {
    "model": "accounts.user",
    "pk": 1,
    "fields": {
      "password": "redacted",
      "last_login": "2022-08-27T14:31:56.467Z",
      "is_superuser": true,
      "username": "example",
      "first_name": "Joe",
      "last_name": "Example",
      "email": "joe@examle.com",
      "is_staff": true,
      "is_active": true,
      "date_joined": "2022-07-25T21:08:54.957Z",
      "time_zone": "US/Central",
      "groups": [],
      "user_permissions": []
    }
  }
]
{% endhighlight %}

This is hardly ever what we want or need when working with Javascript, because
we want our data flat and not nested inside a fields key since that makes our
data much easier to work with. So in order to achive this we end up modifying
custom JSON serializer class in the following way.

{% highlight python %}
class DjangoModelJSONEncoder(DjangoJSONEncoder):
    def default(self, o):
        if isinstance(o, QuerySet) is True:
            if o._iterable_class is ModelIterable:
                o = o.values()
            return list(o)
        return super().default(o)
{% endhighlight %}

This will then flatten user_list to the following:

{% highlight python %}
"user_list": [
  {
    "id": 1,
    "password": "redacted",
    "last_login": "2022-08-27T14:31:56.467Z",
    "is_superuser": true,
    "username": "example",
    "first_name": "Joe",
    "last_name": "Example",
    "email": "joe@examle.com",
    "is_staff": true,
    "is_active": true,
    "date_joined": "2022-07-25T21:08:54.957Z",
    "time_zone": "US/Central",
    "groups": [],
    "user_permissions": []
  }
]
{% endhighlight %}

And now when you go to the view you only have the following assertion that
is failing.

{% highlight python %}
console.assert(data[0].date_time.toDateString() === "Sat Aug 27 2022");
{% endhighlight %}

The reason that it's failing is because the date_time key's value when rendered
is a string (e.g. `"2022-08-27T18:33:18.449Z"`) and not a Javascript object.

To fix this, all we need to do is update the template with the following. In
order to convert the serialized Python date object from a string to an actual
Javascript Date object.

{% highlight html %}
<script>
  function send_data_to_js_example(data) {
    data[0].date_time = new Date(data[0].date_time);
    ...
    console.assert(data[0].date_time.toDateString() === "Sat Aug 27 2022");
    ...
  }
  send_data_to_js_example({% raw %}{{ data|safe }}{% endraw %});
</script>
{% endhighlight %}

Finally, we're done and have a workable solution, right? Well not so fast! There
is one last situation that can cause a lot of headaches. What do you do in a
stuation where you're using a Javascript framework like Vue and you need to pass
the data from python and into a custom component maybe something like
the following.

{% highlight html %}
<custom-data :data="{% raw %}{{ data|safe }}{% endraw %}">
{% endhighlight %}

This doesn't work because our `{% raw %}{{ data|safe }}{% endraw %}` context
variable has a lot of double quotes in it which causes the browser to not be
able to render the view. We can illustrate this with the following template.

{% highlight html %}
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset=UTF-8>
    <title>Send data to js example</title>
  </head>
  <body>
    <div id="data-div" data-data="{% raw %}{{ data|safe }}{% endraw %}"></div>
    <script>
      function get_data_from_data_attribute() {
        const divElem = document.querySelector('#data-div');
        let data = divElem.dataset.data;
        data = JSON.parse(data)
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
      get_data_from_data_attribute();
    </script>
  </body>
</html>
{% endhighlight %}

When the view is rendered the browser won't be able to render the page since we
have double quotes that are unescaped. Example:

{% highlight html %}
<div id="data-div" data-data="[{"mystr": "Foo", ...}]"></div>
{% endhighlight %}

To fix this we can remove the safe filter and use
`{% raw %}{{ data }}{% endraw %}`. Or if
for some reason the data has already been marked safe in the Django view using
`marke_safe()` we can use
[force_escape][force_escape] (e.g.{% raw %}{{ data|force_escape }}{% endraw %})
which will end up rendering our data correctly and our Javascript assertions
will pass! 🎉

{% highlight html %}
<div id="data-div" data-data="[{&quot;mystr&quot;: &quot;Foo&quot;, ...}]"></div>
{% endhighlight %}

![Gif of Data from Star Trek Celebrating](https://media.giphy.com/media/msKNSs8rmJ5m/giphy.gif)

## Summary

If you want to make your life a lot easier, then create a custom utility
function that you can use to serialize your data either as a Django filter or by
calling in directly in your Django views. Something like the following.

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
    return mark_safe(json.dumps(value, cls=DjangoModelJSONEncoder, indent=indent))
{% endhighlight %}

Then in your templates all you have to do is use
`{% raw %}{{ data|to_json }}{% endraw %}`, unless the data is inside an html
attribute, then you would just use
`{% raw %}{{ data|to_json|force_escape }}{% endraw %}`.

It's my hope that this blog post will end up saving engineers a lot of time and
prevent a lot of bugs from being created. It is also my hope that maybe someday
Django would work on using this information to have a filter included in Django
that just works without a lot of hassel.

[django_xss_exploits]: https://docs.djangoproject.com/en/4.1/topics/security/#cross-site-scripting-xss-protection
[safe]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#std-templatefilter-safe
[escapejs]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#escapejs
[filters]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/
[serializing_objects]: https://docs.djangoproject.com/en/4.1/topics/serialization/
[DjangoJSONEncoder]: https://docs.djangoproject.com/en/4.1/topics/serialization/#djangojsonencoder
[force_escape]: https://docs.djangoproject.com/en/4.1/ref/templates/builtins/#force-escape