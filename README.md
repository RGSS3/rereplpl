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
-2
```

Usage
==============
Try the .yml file      
The default configuration hardcoded in main.rb is just an REPL for C language   
but you may try:    
```shell
ruby main.rb simple_echo.yml --- Hello
```

Words
==============
A value in change is not a good inspection in unit developing
