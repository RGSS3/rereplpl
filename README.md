reREPLpl
============

reREPLpl (REPL in replay)(2/100)

a new style of REPL which keeps neutral to languages and runtimes.

```shell
~> ##include <stdio.h>
~> ##include <stdlib.h>
~> ##include <time.h>
~> int a = 3;
~> int b = 5;
~> srand(time(0));
~> printf("rand=%d a+b=%d\n", rand(), a+b);
rand=17675 a+b=8
~> printf("%d\n", a - b);
rand=17692 a+b=8
-2
~> printf("%d\n", a - b);
rand=17702 a+b=8
-2
~> printf("%d\n", a - b);
rand=19834 a+b=8
-2
```

Words
==============
A value in change is not a good value in unit developing
