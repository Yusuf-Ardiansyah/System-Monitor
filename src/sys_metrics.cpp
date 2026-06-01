#include <windows.h>
#include <iostream>

extern "C" {
// Fungsi untuk ambil penggunaan CPU (sementara return statis untuk testing FFI)
int getCpuUsage() {
    return 36;
}

// Fungsi untuk ambil penggunaan RAM
int getMemUsage() {
    MEMORYSTATUSEX memInfo;
    memInfo.dwLength = sizeof(MEMORYSTATUSEX);
    GlobalMemoryStatusEx(&memInfo);
    return (int)memInfo.dwMemoryLoad;
}
}