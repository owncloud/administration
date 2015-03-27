#include <QAuthenticator>
#include <QBuffer>
#include <QCoreApplication>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSignalSpy>
#include <QUrl>
#include <qtest.h>

class Test : public QObject
{
    Q_OBJECT
public:
    Test(const QUrl &rootUri)
    : rootUri(rootUri)
    , testDataUri(rootUri)
    {
        testDataUri.setPath(testDataUri.path() + "/webdav-bench-data/");

        for (auto dirSize : {1, 10, 1000}) {
            QUrl dirUri{testDataUri};
            dirUri.setPath(testDataUri.path() + "/" + QString{"initFolder-%1"}.arg(dirSize) + "/");
            initSubdirUris[dirSize] = dirUri;

            dirUri.setPath(testDataUri.path() + "/" + QString{"copiedFolder-%1"}.arg(dirSize) + "/");
            copiedSubdirUris[dirSize] = dirUri;
        }

        QObject::connect(&qnam, &QNetworkAccessManager::authenticationRequired,
            [](QNetworkReply *, QAuthenticator *authenticator) {
                auto user = qgetenv("DAV_USER");
                auto password = qgetenv("DAV_PASS");
                if (user.isEmpty())
                    qFatal("Please set the DAV_USER and DAV_PASS environment variables to authenticate.");
                authenticator->setUser(user);
                authenticator->setPassword(password);
        });
    }

private slots:
    void initTestCase();
    void cleanupTestCase();
    void putFile_data();
    void putFile();
    void getFile_data();
    void getFile();
    void propfind_data();
    void propfind();
    void propfindFolderSizes_data();
    void propfindFolderSizes();
    void copyFolder_data();
    void copyFolder();

private:
    QNetworkReply *reqPropfind(const QUrl &url, QIODevice *body = 0);
    bool waitForReply(QNetworkReply *reply, bool expectSuccess = true);
    QUrl rootUri;
    QUrl testDataUri;
    QMap<int, QUrl> initSubdirUris;
    QMap<int, QUrl> copiedSubdirUris;
    QNetworkAccessManager qnam;
};

QNetworkReply *Test::reqPropfind(const QUrl &url, QIODevice *body)
{
    QNetworkRequest req{url};
    req.setHeader(QNetworkRequest::ContentTypeHeader, "text/xml");
    req.setRawHeader("Depth", "1");
    return qnam.sendCustomRequest(req, "PROPFIND", body);
}

bool Test::waitForReply(QNetworkReply *reply, bool expectSuccess)
{
    QSignalSpy finishSpy{reply, SIGNAL(finished())};
    if (!finishSpy.wait(30000))
        return false;
    if (expectSuccess && reply->error())
        qWarning() << Q_FUNC_INFO << reply->error() << reply->errorString();
    return !reply->error();
}

void Test::initTestCase()
{
    // waitForReply(qnam.sendCustomRequest(QNetworkRequest{testDataUri}, "DELETE"));

    QNetworkRequest req{testDataUri};
    auto r = reqPropfind(testDataUri);
    waitForReply(r, false);
    if (r->error()) {
        // webdav-bench-data doesn't exist yet, create the structure
        QVERIFY(waitForReply(qnam.sendCustomRequest(QNetworkRequest{testDataUri}, "MKCOL")));

        for (auto dirSize : {1, 10, 1000}) {
            QUrl subdirUri = initSubdirUris.value(dirSize);
            qDebug() << "=== Creating" << subdirUri;
            QVERIFY(waitForReply(qnam.sendCustomRequest(QNetworkRequest{subdirUri}, "MKCOL")));

            for (int i = 0; i < dirSize; ++i) {
                QUrl fileUri{subdirUri};
                fileUri.setPath(fileUri.path() + QString{"dummy-%1.dat"}.arg(i));
                if (i % 100 == 0)
                    qDebug() << "--- Creating" << fileUri;
                QVERIFY(waitForReply(qnam.put(QNetworkRequest{fileUri}, QByteArray{})));
            }
        }
    }
}

void Test::cleanupTestCase()
{
    for (auto uri : copiedSubdirUris)
        waitForReply(qnam.sendCustomRequest(QNetworkRequest{uri}, "DELETE"), false);
}

void Test::putFile_data()
{
    QTest::addColumn<int>("fileSize");
    QTest::newRow("1k") << 1024;
    QTest::newRow("500k") << 500*1024;
    QTest::newRow("5M") << 5*1024*1024;
}

void Test::putFile()
{
    QFETCH(int, fileSize);
    QByteArray fileContents{fileSize, 'W'};

    QUrl requestUri{testDataUri};
    requestUri.setPath(requestUri.path() + "/test" + QTest::currentDataTag() + ".dat");
    QNetworkRequest req{requestUri};
    QBENCHMARK {
        QVERIFY(waitForReply(qnam.put(req, fileContents)));
    }
}

void Test::getFile_data()
{
    QTest::addColumn<int>("fileSize");
    QTest::newRow("1k") << 1024;
    QTest::newRow("500k") << 500*1024;
    QTest::newRow("5M") << 5*1024*1024;
}

void Test::getFile()
{
    QFETCH(int, fileSize);

    QUrl requestUri{testDataUri};
    requestUri.setPath(requestUri.path() + "/test" + QTest::currentDataTag() + ".dat");
    QNetworkRequest req{requestUri};
    QBENCHMARK {
        auto r = qnam.get(req);
        QVERIFY(waitForReply(r));
        QCOMPARE(r->size(), fileSize);
    }
}

void Test::propfind_data()
{
    QTest::addColumn<QByteArray>("properties");
    QTest::newRow("RequestEtagJob") << QByteArray("<d:getetag/>");
    QTest::newRow("ConnectionValidator") << QByteArray("<d:getlastmodified/>");
    QTest::newRow("DiscoverySingleDirectoryJob") << QByteArray("<d:resourcetype/><d:getlastmodified/><d:getcontentlength/><d:getetag/><oc:id/><oc:downloadURL/><oc:dDC/><oc:permissions/>");
    QTest::newRow("CheckQuotaJob") << QByteArray("<d:quota-available-bytes/><d:quota-used-bytes/>");
}

void Test::propfind()
{
    const char *head = "<?xml version=\"1.0\" ?><d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\"><d:prop>";
    const char *tail = "</d:prop></d:propfind>";
    QFETCH(QByteArray, properties);

    QByteArray body = head + properties + tail;
    QBuffer bodyBuffer(&body);
    bodyBuffer.open(QBuffer::ReadOnly);
    QBENCHMARK {
        bodyBuffer.seek(0);
        QVERIFY(waitForReply(reqPropfind(initSubdirUris.value(1000), &bodyBuffer)));
    }
}

void Test::propfindFolderSizes_data()
{
    QTest::addColumn<int>("dirSize");
    QTest::newRow("1") << 1;
    QTest::newRow("10") << 10;
    QTest::newRow("1k") << 1000;
}

void Test::propfindFolderSizes()
{
    QFETCH(int, dirSize);

    QUrl subdirUri = initSubdirUris.value(dirSize);
    QByteArray body("<?xml version=\"1.0\" ?><d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\"><d:prop><d:getlastmodified/></d:prop></d:propfind>");

    QBuffer bodyBuffer(&body);
    bodyBuffer.open(QBuffer::ReadOnly);
    QBENCHMARK {
        bodyBuffer.seek(0);
        QVERIFY(waitForReply(reqPropfind(subdirUri, &bodyBuffer)));
    }
}

void Test::copyFolder_data()
{
    QTest::addColumn<int>("dirSize");
    QTest::newRow("1") << 1;
    QTest::newRow("10") << 10;
    // QTest::newRow("1k") << 1000;
}

void Test::copyFolder()
{
    QFETCH(int, dirSize);

    QUrl sourceUri = initSubdirUris.value(dirSize);
    QUrl destUri = copiedSubdirUris.value(dirSize);

    QBENCHMARK {
        QNetworkRequest req{sourceUri};
        req.setRawHeader("Destination", destUri.toEncoded());
        QVERIFY(waitForReply(qnam.sendCustomRequest(req, "COPY")));
    }
}

int main(int argc, char *argv[])
{
    if (argc < 2) {
        qDebug() << "Usage: bench <WebDAV URI> [QTest options]";
        qDebug() << "";
        qDebug() << "Credentials are passed in USERNAME and DAV_PASS environment variables.";
        qDebug() << "Use the -csv or -xml to get QTest machine-readable output.";
        qDebug() << "";
        qDebug() << "To run a single benchmark you can pass the test name after the server URI.";
        qDebug() << "";
        qDebug() << "Examples:";
        qDebug() << "\tDAV_USER=admin DAV_PASS=admin" << argv[0] << "http://localhost/owncloud/remote.php/webdav/ -csv";
        qDebug() << "";
        qDebug() << "\tDAV_USER=admin DAV_PASS=admin" << argv[0] << "http://localhost/owncloud/remote.php/webdav/ -iterations 1 putFile";
        return 1;
    }

    QString serverUri{argv[1]};

    QVector<QByteArray> newArgs;
    newArgs.append(QByteArray{argv[0]});
    // All this needed to pass a default value for -iterations
    newArgs.append("-iterations");
    newArgs.append("10");

    for (int i = 2; i < argc; ++i)
        newArgs.append(QByteArray(argv[i]));

    QVector<char*> newArgv;
    for (int i = 0; i < newArgs.size(); ++i)
        newArgv.append(newArgs[i].data());
    int newArgc = newArgv.size();

    QCoreApplication app(newArgc, newArgv.data());
    Test tc{serverUri};
    return QTest::qExec(&tc, newArgc, newArgv.data());
}

#include "main.moc"
