#!/usr/bin/env php
<?php
$mergeFromPath = $argv[1];
$mergeToPath = $argv[2] ?? "/dev/null";
$mergeToPath = realpath($mergeToPath);
$directoryIteratorFrom = new RecursiveDirectoryIterator($mergeFromPath);

foreach (new RecursiveIteratorIterator($directoryIteratorFrom) as $fromFile) {
	if($fromFile->isDir()) {
		continue;
	}
	$relativePath = substr($fromFile->getPathName(), strlen($mergeFromPath));
	$relativePath = ltrim($relativePath, "/");
	$toFile = new SplFileInfo("$mergeToPath/$relativePath");

	$toObject = parseFile($toFile);
	$fromObject = parseFile($fromFile);
	if(empty($toObject) || empty($fromObject)) {
		continue;
	}

	$toObject = array_replace_recursive($toObject, $fromObject);

	serialiseToFile($toFile, $toObject);
}

function parseFile(SplFileInfo $file):array {
	$parsedObject = [];

	$ext = $file->getExtension();
	$filePath = $file->getPathname();

	switch($ext) {
	case "ini":
		$parsedObject = parse_ini_file($filePath, true);
		break;

	case "json":
		$parsedObject = json_decode(file_get_contents($filePath), true);
		break;

	default:
		echo "Unknown file extension: $ext ($filePath)." . PHP_EOL;
	}

	if(is_null($parsedObject)) {
		die("Error parsing file: `$filePath`.");
	}

	return $parsedObject;
}

function serialiseToFile(SplFileInfo $file, array $data) {
	$ext = $file->getExtension();
	$filePath = $file->getPathname();

	switch($ext) {
	case "ini":
		break;

	case "json":
		break;
	}
}

##