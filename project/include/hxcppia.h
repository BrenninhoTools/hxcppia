#pragma once

#include <stdint.h>

namespace hxcppia
{
	enum ScriptFormat
	{
		FORMAT_INVALID = 0,
		FORMAT_TEXT = 1,
		FORMAT_BINARY = 2
	};

	int checkHeader(const unsigned char* data, int length);
	int checkFileHeader(const char* path);
	const char* hashBytes(const unsigned char* data, int length);
	const char* hashFile(const char* path);
	double fileModified(const char* path);
	double fileSize(const char* path);
	double nowNanoseconds();
	int scriptVersion(const unsigned char* data, int length);
}
