#include "hxcppia.h"

#include <chrono>
#include <cstdio>
#include <cstring>
#include <sys/stat.h>

#if defined(_WIN32)
#include <windows.h>
#endif

namespace
{
	const uint64_t FNV_OFFSET = 14695981039346656037ULL;
	const uint64_t FNV_PRIME = 1099511628211ULL;

	thread_local char hashText[17];

	uint64_t fnv(uint64_t hash, const unsigned char* data, size_t length)
	{
		for (size_t i = 0; i < length; i++)
		{
			hash ^= data[i];
			hash *= FNV_PRIME;
		}
		return hash;
	}

	const char* hexOf(uint64_t value)
	{
		static const char digits[] = "0123456789abcdef";
		for (int i = 15; i >= 0; i--)
		{
			hashText[i] = digits[value & 0xF];
			value >>= 4;
		}
		hashText[16] = '\0';
		return hashText;
	}

	FILE* openFile(const char* path)
	{
#if defined(_WIN32)
		int size = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
		if (size <= 0) return NULL;
		wchar_t* wide = new wchar_t[size];
		MultiByteToWideChar(CP_UTF8, 0, path, -1, wide, size);
		FILE* file = _wfopen(wide, L"rb");
		delete[] wide;
		return file;
#else
		return fopen(path, "rb");
#endif
	}

	bool statFile(const char* path, double* modified, double* size)
	{
#if defined(_WIN32)
		int length = MultiByteToWideChar(CP_UTF8, 0, path, -1, NULL, 0);
		if (length <= 0) return false;
		wchar_t* wide = new wchar_t[length];
		MultiByteToWideChar(CP_UTF8, 0, path, -1, wide, length);
		WIN32_FILE_ATTRIBUTE_DATA data;
		BOOL ok = GetFileAttributesExW(wide, GetFileExInfoStandard, &data);
		delete[] wide;
		if (!ok) return false;
		ULARGE_INTEGER time;
		time.LowPart = data.ftLastWriteTime.dwLowDateTime;
		time.HighPart = data.ftLastWriteTime.dwHighDateTime;
		if (modified) *modified = ((double)time.QuadPart - 116444736000000000.0) / 10000.0;
		if (size) *size = (double)(((uint64_t)data.nFileSizeHigh << 32) | data.nFileSizeLow);
		return true;
#else
		struct stat info;
		if (stat(path, &info) != 0) return false;
#if defined(__APPLE__)
		if (modified) *modified = (double)info.st_mtimespec.tv_sec * 1000.0 + (double)info.st_mtimespec.tv_nsec / 1000000.0;
#else
		if (modified) *modified = (double)info.st_mtim.tv_sec * 1000.0 + (double)info.st_mtim.tv_nsec / 1000000.0;
#endif
		if (size) *size = (double)info.st_size;
		return true;
#endif
	}
}

namespace hxcppia
{
	int checkHeader(const unsigned char* data, int length)
	{
		if (data == NULL || length < 6) return FORMAT_INVALID;
		if (memcmp(data, "CPPIA", 5) != 0 && memcmp(data, "CPPIB", 5) != 0) return FORMAT_INVALID;
		if (data[5] != '\n' && data[5] != '\r') return FORMAT_INVALID;
		return data[4] == 'B' ? FORMAT_BINARY : FORMAT_TEXT;
	}

	int checkFileHeader(const char* path)
	{
		if (path == NULL) return FORMAT_INVALID;
		FILE* file = openFile(path);
		if (file == NULL) return FORMAT_INVALID;
		unsigned char header[8];
		size_t read = fread(header, 1, sizeof(header), file);
		fclose(file);
		return checkHeader(header, (int)read);
	}

	const char* hashBytes(const unsigned char* data, int length)
	{
		if (data == NULL || length <= 0) return hexOf(FNV_OFFSET);
		return hexOf(fnv(FNV_OFFSET, data, (size_t)length));
	}

	const char* hashFile(const char* path)
	{
		hashText[0] = '\0';
		if (path == NULL) return hashText;
		FILE* file = openFile(path);
		if (file == NULL) return hashText;
		uint64_t hash = FNV_OFFSET;
		unsigned char buffer[16384];
		size_t read;
		while ((read = fread(buffer, 1, sizeof(buffer), file)) > 0)
			hash = fnv(hash, buffer, read);
		fclose(file);
		return hexOf(hash);
	}

	double fileModified(const char* path)
	{
		double modified = 0;
		return path != NULL && statFile(path, &modified, NULL) ? modified : 0;
	}

	double fileSize(const char* path)
	{
		double size = -1;
		return path != NULL && statFile(path, NULL, &size) ? size : -1;
	}

	double nowNanoseconds()
	{
		return (double)std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
	}

	int scriptVersion(const unsigned char* data, int length)
	{
		if (checkHeader(data, length) == FORMAT_INVALID) return -1;
		int position = 6;
		int version = 0;
		bool digits = false;
		while (position < length && data[position] >= '0' && data[position] <= '9')
		{
			version = version * 10 + (data[position] - '0');
			digits = true;
			position++;
			if (version > 100000) return -1;
		}
		return digits ? version : -1;
	}
}
