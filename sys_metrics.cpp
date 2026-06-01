#define WIN32_LEAN_AND_MEAN  // <--- INI MANTRA SAKTINYA!
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>

// Beritahu compiler untuk melampirkan library IP Helper Windows
#pragma comment(lib, "iphlpapi.lib")

extern "C" {

// ==========================================
// 1. FUNGSI MEMBACA MEMORY (RAM)
// ==========================================
__declspec(dllexport) int getMemUsage() {
    MEMORYSTATUSEX memInfo;
    memInfo.dwLength = sizeof(MEMORYSTATUSEX);
    GlobalMemoryStatusEx(&memInfo);
    return (int)memInfo.dwMemoryLoad;
}

// ==========================================
// 2. FUNGSI MEMBACA CPU
// ==========================================
__declspec(dllexport) int getCpuUsage() {
    static FILETIME idleTime, kernelTime, userTime;
    static bool firstRun = true;

    if (firstRun) {
        GetSystemTimes(&idleTime, &kernelTime, &userTime);
        firstRun = false;
        return 0;
    }

    FILETIME newIdleTime, newKernelTime, newUserTime;
    if (GetSystemTimes(&newIdleTime, &newKernelTime, &newUserTime)) {
        ULARGE_INTEGER idle, kernel, user;
        ULARGE_INTEGER oldIdle, oldKernel, oldUser;

        idle.LowPart = newIdleTime.dwLowDateTime;
        idle.HighPart = newIdleTime.dwHighDateTime;
        kernel.LowPart = newKernelTime.dwLowDateTime;
        kernel.HighPart = newKernelTime.dwHighDateTime;
        user.LowPart = newUserTime.dwLowDateTime;
        user.HighPart = newUserTime.dwHighDateTime;

        oldIdle.LowPart = idleTime.dwLowDateTime;
        oldIdle.HighPart = idleTime.dwHighDateTime;
        oldKernel.LowPart = kernelTime.dwLowDateTime;
        oldKernel.HighPart = kernelTime.dwHighDateTime;
        oldUser.LowPart = userTime.dwLowDateTime;
        oldUser.HighPart = userTime.dwHighDateTime;

        ULONGLONG idleDiff = idle.QuadPart - oldIdle.QuadPart;
        ULONGLONG kernelDiff = kernel.QuadPart - oldKernel.QuadPart;
        ULONGLONG userDiff = user.QuadPart - oldUser.QuadPart;

        ULONGLONG totalSystemTime = kernelDiff + userDiff;

        idleTime = newIdleTime;
        kernelTime = newKernelTime;
        userTime = newUserTime;

        if (totalSystemTime == 0) return 0;

        double cpu = 100.0 * (totalSystemTime - idleDiff) / totalSystemTime;
        if (cpu < 0.0) cpu = 0.0;
        if (cpu > 100.0) cpu = 100.0;

        return (int)cpu;
    }
    return 0;
}

// ==========================================
// 3. FUNGSI MEMBACA TRAFFIC UPLOAD (OUT)
// ==========================================
__declspec(dllexport) double getNetworkOutBytes() {
    PMIB_IF_TABLE2 pIfTable = NULL;
    double totalOut = 0;

    if (GetIfTable2(&pIfTable) == NO_ERROR) {
        for (ULONG i = 0; i < pIfTable->NumEntries; i++) {
            MIB_IF_ROW2 row = pIfTable->Table[i];
            // Hanya hitung antarmuka yang aktif dan abaikan Loopback (virtual)
            if (row.OperStatus == IfOperStatusUp && row.Type != IF_TYPE_SOFTWARE_LOOPBACK) {
                totalOut += (double)row.OutOctets;
            }
        }
        FreeMibTable(pIfTable);
    }
    return totalOut;
}

// ==========================================
// 4. FUNGSI MEMBACA TRAFFIC DOWNLOAD (IN)
// ==========================================
__declspec(dllexport) double getNetworkInBytes() {
    PMIB_IF_TABLE2 pIfTable = NULL;
    double totalIn = 0;

    if (GetIfTable2(&pIfTable) == NO_ERROR) {
        for (ULONG i = 0; i < pIfTable->NumEntries; i++) {
            MIB_IF_ROW2 row = pIfTable->Table[i];
            if (row.OperStatus == IfOperStatusUp && row.Type != IF_TYPE_SOFTWARE_LOOPBACK) {
                totalIn += (double)row.InOctets;
            }
        }
        FreeMibTable(pIfTable);
    }
    return totalIn;
}

} // Akhir dari extern "C"