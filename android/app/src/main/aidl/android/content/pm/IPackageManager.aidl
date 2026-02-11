package android.content.pm;

import android.content.pm.IPackageInstaller;

interface IPackageManager {
    IPackageInstaller getPackageInstaller();
}
