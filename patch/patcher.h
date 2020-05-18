#ifndef PATCHER_H
#define PATCHER_H

#endif // PATCHER_H

#include <QFile>

namespace Patcher {
    qint64 calcFileHash(char*, qint64);
    qint8 patchData(char*);
}
