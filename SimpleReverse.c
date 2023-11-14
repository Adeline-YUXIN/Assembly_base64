#include<stdio.h>
#include <stdlib.h>
#include <string.h>
#include<malloc.h>
//flag{Hell0!_Fr0m_Aur0r@B1nS3c_CSU}

static char buf[0x100];
static char key = 0x67;

// 全局常量定义
const char * base64char = "ZYXABCDEFGHIJKLMNOPQRSTUVWzyxabcdefghijklmnopqrstuvw0123456789+/";
const char padding_char = '=';
static unsigned char str[0x100];
static char base64encode[0x100];
static char buffer[0x1000];
static char cipher1[0x30] = {48, 13, 18, 2, 48, 84, 22, 33, 48, 51, 18, 23, 45, 63, 36, 4, 40, 12, 33, 19, 30, 52, 95, 90};
static unsigned int cipher2[0x30] = {4082864189, 3674921777, 4033020472, 3157788679, 595834044, 659704428, 2321028455, 146270356, 3232710920, 3999809776, 1271388422, 3959914972, 348432882, 2599787200, 1784650661, 3358288901};

/*编码代码
 * const unsigned char * sourcedata， 源数组
 * char * base64 ，码字保存
 */
int encode1(const unsigned char * sourcedata, char * base64) {
	int i = 0, j = 0;
	unsigned char trans_index = 0;  // 索引是8位，但是高两位都为0
	const int datalength = strlen((const char*)sourcedata);
	for (; i < datalength; i += 3) {
		// 每三个一组，进行编码
		// 要编码的数字的第一个
		trans_index = ((sourcedata[i] >> 2) & 0x3f);
		base64[j++] = base64char[(int)trans_index];
		// 第二个
		trans_index = ((sourcedata[i] << 4) & 0x30);
		if (i + 1 < datalength) {
			trans_index |= ((sourcedata[i + 1] >> 4) & 0x0f);
			base64[j++] = base64char[(int)trans_index];
		} else {
			base64[j++] = base64char[(int)trans_index];

			base64[j++] = padding_char;

			base64[j++] = padding_char;

			break;   // 超出总长度，可以直接break
		}
		// 第三个
		trans_index = ((sourcedata[i + 1] << 2) & 0x3c);
		if (i + 2 < datalength) { // 有的话需要编码2个
			trans_index |= ((sourcedata[i + 2] >> 6) & 0x03);
			base64[j++] = base64char[(int)trans_index];

			trans_index = sourcedata[i + 2] & 0x3f;
			base64[j++] = base64char[(int)trans_index];
		} else {
			base64[j++] = base64char[(int)trans_index];

			base64[j++] = padding_char;

			break;
		}
	}

	base64[j] = '\0';

	return 0;
}

void encode2 (unsigned int* v, unsigned int* k) {
	unsigned int v0 = v[0], v1 = v[1], sum = 0, i;     /* set up */
	unsigned int delta = 0x9e3779b9;                   /* a key schedule constant */
	unsigned int k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3]; /* cache key */
	for (i = 0; i < 32; i++) {                     /* basic cycle start */
		sum += delta;
		v0 += ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
		v1 += ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
	}                                              /* end cycle */
	v[0] = v0;
	v[1] = v1;
}
//解密函数
void decode (unsigned int* v, unsigned int* k) {
	unsigned int v0 = v[0], v1 = v[1], sum = 0xC6EF3720, i; /* set up */
	unsigned int delta = 0x9e3779b9;                   /* a key schedule constant */
	unsigned int k0 = k[0], k1 = k[1], k2 = k[2], k3 = k[3]; /* cache key */
	for (i = 0; i < 32; i++) {                     /* basic cycle start */
		v1 -= ((v0 << 4) + k2) ^ (v0 + sum) ^ ((v0 >> 5) + k3);
		v0 -= ((v1 << 4) + k0) ^ (v1 + sum) ^ ((v1 >> 5) + k1);
		sum -= delta;
	}                                              /* end cycle */
	v[0] = v0;
	v[1] = v1;
}

void Fail() {
	printf("Fail...Try again!\n");
	system("pause");
	exit(-1);
}


int main() {
	printf("Welcome to solve reverse me!\n");
	printf("Try to input something and Enjoy!o((>w< ))o\n");
	scanf("%34s", buf);//flag{Hell0!_Fr0m_Aur0r@B1nS3c_CSU}
	if ((strlen(buf) != 34)) {
		Fail();
	}
	if ( strncmp(buf, "flag{", 5)) {
		Fail();
	}
	memcpy(str, buf, 17);//取前17个字节进行base64
	encode1((const unsigned char *)str, base64encode);
	// printf("%s\n", base64encode);//WjueW3qFWTupJXCcOkFtyS8=
	int i = 0;
	for (i = 0; i < 24; i++) {
		buffer[i] = base64encode[i] ^ key;
		// printf("%d, ", buffer[i]);
		if (buffer[i] != cipher1[i]) {
			// printf("Fail3\n");
			Fail();
		}
	}
	// v为要加密的数据是两个32位无符号整数
	// k为加密解密密钥，为4个32位无符号整数，即密钥长度为128位
	unsigned int v[2];
	unsigned int const k[4] = { 2, 2, 3, 4 };
	for (i = 17; i <= 32; i += 2) {
		v[0] = (unsigned int)buf[i];
		v[1] = (unsigned int)buf[i + 1];
		encode2(v, k);
		// printf("\n%u, %u", v[0], v[1]);
		if (v[0] != cipher2[i - 17] || v[1] != cipher2[i - 16]) {
			// printf("Fail1\n");
			Fail();
		}
	}
	if (buf[33] != '}') {
		// printf("Fail2\n");
		Fail();
	}
	printf("\nSuccess!o(n_n)o\n");
	system("pause");
	return 0;
}
