package android.content.pm;

import android.content.IntentSender;
import android.os.ParcelFileDescriptor;

interface IPackageInstallerSession {
    ParcelFileDescriptor openWrite(String name, long offsetBytes, long lengthBytes);
    void fsync(in ParcelFileDescriptor fd);
    void commit(in IntentSender statusReceiver, boolean forTransfer);
    void close();
}
