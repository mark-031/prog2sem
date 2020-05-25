#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "patcher.h"
#include <QFileDialog>
#include <QMessageBox>
#include <QFile>
#include <QDebug>


MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_chooseFile_clicked()
{
    const qint64 correct_hash = -12715;
    const qint64 patched_hash = -13496;

    QString file_name = QFileDialog::getOpenFileName(this, "Choose a file to patch");
    QFile file(file_name);

    if(!file.open(QFile::ReadOnly)) {
        QMessageBox::critical(this, "File open error!", "Unable to open a file");
        return;
    }

    qint64 filesize = file.size();

    if(filesize <= 0) {
        file.close();
        QMessageBox::critical(this, "File size error!", "Unknow error with size of the file!");
        return;
    }

    char* filedata = new char[filesize]();

    if(file.read(filedata, filesize) != filesize) {
        file.close();
        delete [] filedata;
        QMessageBox::critical(this, "Error reading file!", "Unable to read file");
        return;
    }

    qint64 hash = Patcher::calcFileHash(filedata, filesize);

    if(hash == correct_hash) {
        Patcher::patchData(filedata);
        file.close();

        if(!file.open(QFile::WriteOnly | QFile::Truncate)) {
            delete [] filedata;
            QMessageBox::critical(this, "Overwrite error!", "Unable to overwrite file");
            return;
        }

        if(file.write(filedata, filesize) != filesize) {
            delete [] filedata;
            file.close();
            QMessageBox::critical(this, "Write error!", "Unknown error with write to file!");
            return;
        }

        QMessageBox::information(this, "Successful", "File was successfully patched");
    } else if (hash == patched_hash) {
        QMessageBox::information(this, "Already patched", "File was already patched");
    } else {
        QMessageBox::critical(this, "Incorrect Hash!", "Hash of choosen file is incorrect!");
    }

    delete [] filedata;
    file.close();
}
