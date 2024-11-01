---
layout: til
title: "Pathlib has nice shortcuts for reading and writing to files"
date: 2024-10-30
categories: til
---

TIL: If you use `pathlib` to work with files, you can use the `read_text` and `write_text` methods to read and write to
files. This is a nice alternative to using `open()` and `close()` directly.

It used to be that if you wanted to read and write to a file, you would do something like this:
```python
with open("example.txt", "r") as f:
    text = f.read()

with open("example.txt", "w") as f:
    f.write(text + " (updated)")
```

But with `pathlib`, you can do this instead:
```python
from pathlib import Path

path = Path("example.txt")
text = path.read_text()
path.write_text(text + " (updated)")
```

Using `pathlib` is not only more concise but also handles file opening and closing for you, ensuring proper resource management.

## Behind the Scenes
From the `pathlib` source code, you can see that `read_text` and `write_text` methods using context managers to open and
close the files, so you don't have to worry about it:
```python
def read_text(self, encoding=None, errors=None, newline=None):
    """
    Open the file in text mode, read it, and close the file.
    """
    with self.open(mode='r', encoding=encoding, errors=errors, newline=newline) as f:
        return f.read()

def write_text(self, data, encoding=None, errors=None, newline=None):
    """
    Open the file in text mode, write to it, and close the file.
    """
    if not isinstance(data, str):
        raise TypeError('data must be str, not %s' % data.__class__.__name__)
    with self.open(mode='w', encoding=encoding, errors=errors, newline=newline) as f:
        return f.write(data)
```
