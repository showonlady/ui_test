#!/user/bin/env python
#encoding:utf-8


def fun(x):
    d = {'1': '一', '2': '二', '3': '三', '4': '四', '5':'五'
         , '6': '六', '7': '七', '8': '八', '9': '九', '0':'零'}
    y = []
    z = ['千','百','十','万','千','百','十']
    x = str(x)
    i = -1
    if x[-1] == '0':
        while x[-1] == '0':
            i = i -1
            x = x[:-1]

    else:
        y.append(d[x[-1]])
        x = x[:-1]

    while x:
        if x[-1] != '0':
            y.append(z[i])
            y.append(d[x[-1]])

        elif x[-1] == '0' and y[-1] != '零':
            y.append('零')
        i = i -1
        x = x[:-1]
    y.reverse()
    return y

if __name__ == "__main__":
    x = input("input a number:")
    z = fun(x)
    z = str(z)
    print z.decode('string_escape')










