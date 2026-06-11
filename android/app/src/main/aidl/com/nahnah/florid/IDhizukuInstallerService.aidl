package com.nahnah.florid;

interface IDhizukuInstallerService {
    int installPackage(in android.os.ParcelFileDescriptor pfd, long fileSize, String expectedPackageName, long expectedVersionCode, String installerPackageName);
    // destroy must be transaction +1: Dhizuku UserService sends FIRST_CALL_TRANSACTION + 1 on start
    void destroy();
    // uninstallPackage is transaction +2: Dhizuku UserService sends FIRST_CALL_TRANSACTION + 2 on quit
    int uninstallPackage(String packageName);
}
