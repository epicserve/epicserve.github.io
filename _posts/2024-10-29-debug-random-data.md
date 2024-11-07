---
layout: post
title: "Debugging Randomly Failing Tests with Reproducible Random Seeds"
date: 2024-10-29 08:58:00 -05:00
categories: django
image:
  path: /assets/images/debug-random-data/debug-random-data-header.webp
  alt: "Debugging Randomly Failing Tests with Reproducible Random Seeds Header Image"
  caption: "Image created by ChatGPT, because it's better than no image."
---

There are two things I despise in this world: dealing with printers that don't work and debugging randomly
failing tests.

While I can't solve all printer woes today, I can share how we make debugging flaky tests easier at [Canopy](https://canopyteam.org/). We
frequently use [Model Bakery](https://github.com/model-bakers/model_bakery) and [Faker](https://pypi.org/project/Faker/)
to generate test data, this randomly generated data can sometimes cause unpredictable test failures. To tackle this
challenge, we've implemented a solution that makes [pytest](https://docs.pytest.org/) print the random seed number used
in failing tests. This allows us to reproduce the same test conditions by reusing that seed number in subsequent
test runs.

When a test fails, we can examine whether the randomly generated data is the culprit by rerunning the test with the
same seed. If the test fails consistently with that seed, we've likely identified that the test's randomized data
contributes to the failure. While this isn't always the root cause, it's an excellent starting point for investigation.
(I should probably write another post about dealing with stubborn printers and other common causes of flaky tests!)

Here's the code we use to implement this functionality. First, add this to your BaseTest class:
```python
class BaseTest(TestCase):
    @pytest.fixture(autouse=True)
    def seed_random(self, request):
        # Use seed from the command line if provided
        seed = request.config.getoption("--seed")
        if seed is None:
            pytest.seed = random.randint(0, 999999)
        else:
            pytest.seed = int(seed)
        random.seed(pytest.seed)
        Faker.seed(pytest.seed)
        print(f"\nRunning test with seed: {pytest.seed}")
```

If you're using function-based tests instead of class-based tests, you'll want to add this fixture to your
`conftest.py` file:
```python
@pytest.fixture(autouse=True)
def seed_random(request):
    # Same implementation as above
    ...
```

Finally, add this to your `conftest.py` to display the seed number when a test fails:
```python
import pytest


pytest.seed = None


def pytest_runtest_makereport(item, call):
    if call.when == "call" and call.excinfo is not None:
        print(
            f"\n{'*' * 22}\nExtra Failure Context:\n* Seed number used: {pytest.seed}. Use `pytest --seed {pytest.seed}` "
            f"to run the tests again with the same seed number.\n"
        )
```

Then you can run your tests with the `--seed` flag to reproduce the same random data and investigate the issue further
(e.g., `pytest --seed 34512`).

P.S. We have some amazing engineers at Canopy, and [Levi Mann](https://www.linkedin.com/in/levi-mann-8b34a6ab/) is the
engineer at Canopy who gave us the idea. I'm just the one who used AI to help write it! 😂