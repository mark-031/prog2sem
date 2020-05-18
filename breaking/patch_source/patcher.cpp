#include "patcher.h"

qint64 Patcher::calcFileHash(char* filedata, qint64 filesize) {
    if((filesize <= 0) || (filedata == nullptr))
           return 0;

    qint64 hash = static_cast<qint64>(filedata[0]);

    for(qint64 i = 1; i < filesize; ++i) {
        hash += static_cast<qint64>(filedata[i - 1] ^ (~filedata[i] << 1));
    }

    return hash;
}

qint8 Patcher::patchData(char* filedata) {
    if(filedata == nullptr)
        return -1;

    const qint64 start = 0xb0;

    const qint8 changelen = 11;
    const char to_change[] = {0x68, static_cast<char>(0xD2), 0x00, 0x40, 0x00,
                              0x68, 0x41, 0x01, 0x40, 0x00,
                              static_cast<char>(0xC3)};

    for(qint8 i = 0; i < changelen; ++i)
        filedata[start + i] = to_change[i];

    return 0;
}
