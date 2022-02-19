<?php

$rootFolder = "/framelix";

// do some checks if already installed
if (
    !is_dir($rootFolder) ||
    file_exists($rootFolder . "/install.php") ||
    file_exists($rootFolder . "/index.php") ||
    is_dir($rootFolder . "/modules")
) {
    return;
}

$module = $_SERVER['FRAMELIX_MODULE'] ?? null;
if (!$module) {
    echo "[ERROR] Module not defined in .env";
    exit(1);
}

// updating nginx config
$nginxConfigPath = '/framelix-scripts/nginx-config.conf';
$nginxConfig = file_get_contents($nginxConfigPath);
$nginxConfig = preg_replace("~framelix/modules/(.*?)/~", "framelix/modules/$module/", $nginxConfig);
file_put_contents($nginxConfigPath, $nginxConfig);

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
    $zipFile = $rootFolder . "/backup.zip";
    $zipArchive = new ZipArchive();
    $openResult = $zipArchive->open($zipFile, ZipArchive::RDONLY);
    if ($openResult !== true) {
        throw new Exception("Cannot open ZIP File '$zipFile' ($openResult)");
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

// find a release zip file
$files = scandir($rootFolder);
$zipFile = null;
foreach ($files as $file) {
    if (str_starts_with($file, "release") && str_ends_with($file, ".zip")) {
        $zipFile = $rootFolder . "/" . $file;
        break;
    }
}

if (($_SERVER['INITIAL_GITHUB_RELEASE_URL'] ?? null) && !$zipFile) {
    $zipFile = $rootFolder . "/release.zip";
    // fresh new installation with auto download from github
    $context = stream_context_create([
            'http' => [
                'method' => "GET",
                'user_agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'
            ]
        ]
    );

    $releaseData = json_decode(
        file_get_contents(
            $_SERVER['INITIAL_GITHUB_RELEASE_URL'],
            false,
            $context
        ),
        true
    );
    file_put_contents($zipFile, file_get_contents($releaseData['assets'][0]['browser_download_url'], 0, $context));
}

if (file_exists($zipFile)) {
    $zipArchive = new ZipArchive();
    $openResult = $zipArchive->open($zipFile, ZipArchive::RDONLY);
    if ($openResult !== true) {
        throw new Exception("Cannot open ZIP File '$zipFile' ($openResult)");
    }
    $zipArchive->extractTo($rootFolder);
    $zipArchive->close();
    unlink($zipFile);

    // call install process right away
    $_GET['unpack'] = 1;
    include_once $rootFolder . "/install.php";
}