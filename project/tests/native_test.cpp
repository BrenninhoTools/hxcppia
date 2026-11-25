#include "hxcppia.h"
#include <cstdio>
#include <cstring>
int main(int argc, char** argv)
{
	int fails = 0;
	const unsigned char good[] = "CPPIB\n18\n0 \n";
	const unsigned char text[] = "CPPIA\n17\n";
	const unsigned char bad[] = "PNG...";
	if (hxcppia::checkHeader(good, 12) != hxcppia::FORMAT_BINARY) fails++;
	if (hxcppia::checkHeader(text, 9) != hxcppia::FORMAT_TEXT) fails++;
	if (hxcppia::checkHeader(bad, 6) != hxcppia::FORMAT_INVALID) fails++;
	if (hxcppia::scriptVersion(good, 12) != 18) fails++;
	if (strcmp(hxcppia::hashBytes((const unsigned char*)"a", 1), "af63dc4c8601ec8c") != 0) fails++;
	FILE* f = fopen("hxcppia_probe.cppia", "wb"); fwrite(good, 1, 12, f); fclose(f);
	if (hxcppia::checkFileHeader("hxcppia_probe.cppia") != hxcppia::FORMAT_BINARY) fails++;
	if (strcmp(hxcppia::hashFile("hxcppia_probe.cppia"), hxcppia::hashBytes(good, 12)) != 0) fails++;
	if (hxcppia::fileSize("hxcppia_probe.cppia") != 12) fails++;
	if (hxcppia::fileModified("hxcppia_probe.cppia") <= 0) fails++;
	if (hxcppia::fileModified("missing.cppia") != 0) fails++;
	double a = hxcppia::nowNanoseconds(), b = hxcppia::nowNanoseconds();
	if (b < a) fails++;
	printf(fails ? "FAIL %d\n" : "ok\n", fails);
	return fails;
}
