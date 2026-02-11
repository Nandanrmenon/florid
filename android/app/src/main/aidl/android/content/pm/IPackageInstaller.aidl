package android.content.pm;

import android.content.pm.IPackageInstallerSession;
import android.content.pm.PackageInstaller;

interface IPackageInstaller {
    int createSession(in PackageInstaller.SessionParams params, String installerPackageName, String installerAttributionTag, int userId);
    IPackageInstallerSession openSession(int sessionId);
}
