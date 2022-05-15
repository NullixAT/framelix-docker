<?php

$rootFolder = "/framelix";
$moduleFile = $rootFolder . "/MODULE";

// do some checks if already installed
if (
    !is_dir($rootFolder) ||
    file_exists($moduleFile) ||
    is_dir($rootFolder . "/modules")
) {
    return;
}

// check if backup exist, if so, import
if (file_exists($rootFolder . "/backup.zip")) {
    // to many files in folder, stop
    if (count(scandir($rootFolder)) > 4) {
        echo "[ERROR] Too many files in app folder beside backup.zip. Delete everything except the backup.zip";
        exit(1);
    }

    // wait for db to run
    while (true) {
        try {
            $mysql = new mysqli("db", "app", "app", "app");
            break;
        } catch (Exception $e) {
        }
        sleep(1);
    }

    $mysql = new mysqli("db", "app", "app", "app");
    $releaseArchivePath = $rootFolder . "/backup.zip";
    $zipArchive = new ZipArchive();
    $openResult = $zipArchive->open($releaseArchivePath, ZipArchive::RDONLY);
    if ($openResult !== true) {
        throw new Exception("Cannot open ZIP File '$releaseArchivePath' ($openResult)");
    }
    $zipArchive->extractTo($rootFolder);
    $zipArchive->close();
    unlink($rootFolder . "/backup.zip");
    exec("mv /framelix/appfiles/* /framelix");
    exec("mv /framelix/appfiles/.* /framelix");
    rmdir($rootFolder . "/appfiles");
    $mysql->query('DROP DATABASE app');
    $mysql->query('CREATE DATABASE app');
    $mysql->query('USE app');

    $templine = '';
    $lines = file($rootFolder . "/appdatabase/backup.sql");
    foreach ($lines as $line) {
        if (str_starts_with($line, '--') || $line == '') {
            continue;
        }
        $templine .= $line;
        if (str_ends_with(trim($line), ';')) {
            $mysql->query($templine);
            $templine = '';
        }
    }
    unlink($rootFolder . "/appdatabase/backup.sql");
    rmdir($rootFolder . "/appdatabase");
    exit;
}

// find a release tar file
$files = scandir($rootFolder);
$releaseArchivePath = null;
foreach ($files as $file) {
    if (str_contains($file, "release") && str_ends_with($file, ".tar")) {
        $releaseArchivePath = $rootFolder . "/" . $file;
        break;
    }
}

if (file_exists($releaseArchivePath)) {
    $status = -1;
    $out = null;
    exec(
        "tar --overwrite -xf " . escapeshellarg($releaseArchivePath) . " -C " . escapeshellarg($rootFolder),
        $out,
        $status
    );
    if ($status) {
        echo implode("\n", $out);
        exit($status);
    }
    unlink($releaseArchivePath);
}

if (!file_exists($moduleFile)) {
    echo "[ERROR] No MODULE file exists in app folder";
    exit(1);
}

$module = trim(file_get_contents($moduleFile));
$moduleFolder = $rootFolder . "/modules/" . $module;
if (!is_dir($moduleFolder)) {
    echo "[ERROR] Module directory not exists in app/modules/$module folder";
    exit(1);
}