#!/usr/bin/env php
<?php
/**
 * Usage: replace-config.php /path/to/config/directory /path/to/deploy/directory
 */
const REPLACEMENT_LIST = [
	"DEPLOY_REF",
];

$mergeFromPath = $argv[1];
$mergeToPath = $argv[2] ?? "/dev/null";
$mergeToPath = realpath($mergeToPath);
$directoryIteratorFrom = new RecursiveDirectoryIterator($mergeFromPath);

foreach(new RecursiveIteratorIterator($directoryIteratorFrom) as $fromFile) {
	if($fromFile->isDir()) {
		continue;
	}

	$relativePath = substr($fromFile->getPathName(), strlen($mergeFromPath));
	$relativePath = ltrim($relativePath, "/");
	if(!is_file("$mergeToPath/$relativePath")) {
		touch("$mergeToPath/$relativePath");
	}
	$toFile = new SplFileObject("$mergeToPath/$relativePath", "r+");

	$toData = parseFile($toFile);
	$fromData = parseFile($fromFile);
	if(empty($toData) || empty($fromData)) {
		continue;
	}

	$toData = array_replace_recursive($toData, $fromData);
	serialiseToFile($toFile, $toData);
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

	$file->ftruncate(0);

	switch($ext) {
	case "ini":
		foreach($data as $category => $kvpList) {
			$file->fwrite("[$category]" . PHP_EOL);

			foreach(REPLACEMENT_LIST as $replacement) {
				$value = str_replace(
					"\{$replacement\}",
					getenv($replacement),
					$value
				);
			}

			foreach($kvpList as $key => $value) {
				$file->fwrite("$key=\"$value\"" . PHP_EOL);
			}
		}
		break;

	case "json":
		break;
	}
}

##