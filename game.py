#!/user/bin/env python
#coding utf-8

import random

x = ['a', 'b', 'c']
y = [('a', 'b'),('b', 'c'),('c', 'a')]
i = 0;
count = 0;

while i<3:
    h = raw_input("input:")
    l = random.choice(x)
    print l
    if (h, l) in y:
        count += 1
    i += 1

if count>=2:
    print "successfull"
else:
    print "Fail"


