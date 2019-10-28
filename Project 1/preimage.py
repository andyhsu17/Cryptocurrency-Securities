import hashlib
names = "anhs3970-brhe4981-yach9834-"
for x in range(0,50000000):

    newstr = names + str(x)
    encodestr = newstr.encode()

    z = hashlib.sha256(encodestr).hexdigest()
    a = z[0:6]
    if a == "000000":
        print(newstr + " " + z)
        break
