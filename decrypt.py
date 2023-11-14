import base64
from ctypes import *

cipher1 = [37, 24, 7, 23, 37, 65, 3, 52, 37, 38, 7, 2, 56, 42, 17, 49, 61, 25, 52, 6, 11, 33, 74, 79]
decrypt1 = []
for i in cipher1:
    decrypt1.append(chr(i ^ 0x67))
print(''.join(decrypt1))
# str1是要解密的base64编码串
str1 = 'WjueW3qFWTupJXCcOkFtyS8='
# string1是改过之后的base64表
string1 = "ZYXABCDEFGHIJKLMNOPQRSTUVWzyxabcdefghijklmnopqrstuvw0123456789+/"
string2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
print(base64.b64decode(str1.translate(str.maketrans(string1, string2))))
result = ''
result += str(base64.b64decode(str1.translate(str.maketrans(string1, string2))))
result = result[2:19]

cipher2 = [4082864189, 3674921777, 4033020472, 3157788679, 595834044, 659704428, 2321028455, 146270356, 3232710920,
           3999809776, 1271388422, 3959914972, 348432882, 2599787200, 1784650661, 3358288901]
key = [2, 2, 3, 4]


def decipher(v, k):
    y = c_uint32(v[0])
    z = c_uint32(v[1])
    sum = c_uint32(0xc6ef3720)
    delta = 0x9e3779b9
    n = 32
    w = [0, 0]

    while n > 0:
        z.value -= (y.value << 4) + k[2] ^ y.value + sum.value ^ (y.value >> 5) + k[3]
        y.value -= (z.value << 4) + k[0] ^ z.value + sum.value ^ (z.value >> 5) + k[1]
        sum.value -= delta
        n -= 1

    w[0] = y.value
    w[1] = z.value
    return w


cipher = [0, 0]
for i in range(0, len(cipher2) - 1):
    cipher[0] = cipher2[i]
    cipher[1] = cipher2[i + 1]
    print(decipher(cipher, key))

decrypt2 = [65, 117, 114, 48, 114, 64, 66, 49, 110, 83, 51, 99, 95, 67, 83, 85]
for i in decrypt2:
    print(chr(i), end='')
    result += chr(i)
print()
print(result + '}')

str2 = 'WjueW3q5y3ScVUGiU3GmW2e0cN=='
string1 = "ZYXABCDEFGHIJKLMNOPQRSTUVWzyxabcdefghijklmnopqrstuvw0123456789+/"
string2 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
print(base64.b64decode(str2.translate(str.maketrans(string1, string2))))

