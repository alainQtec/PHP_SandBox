<?php
// Define the download URL for the latest version of WordPress
$wpDownloadLink = "https://wordpress.org/latest.zip";

// Define the installation directory
$installDir = __DIR__;

// Define the name of the temporary zip file
$tmpZipFile = $installDir . "/tmpWP.zip";

// Remove the existing WordPress directory if it already exists
if (is_dir($installDir . '/wordpress/')) {
    if (!@rmdir($installDir . '/wordpress')) {
        die('Failed to remove the existing WordPress directory');
    }
}

// Download the latest version of WordPress
if (!@copy($wpDownloadLink, $tmpZipFile)) {
    $errors = error_get_last();
    echo "COPY ERROR: " . $errors['type'];
    echo "<br />\n" . $errors['message'];
} else {
    // Extract the downloaded WordPress zip file to the installation directory
    $zip = new ZipArchive;
    if ($zip->open($tmpZipFile) === TRUE) {
        $zip->extractTo($installDir);
        $zip->close();

        // Remove the temporary zip file
        @unlink($tmpZipFile);

        // Move all the files from the WordPress directory to the installation directory
        $source = $installDir . '/wordpress/';
        $destination = $installDir . '/';
        $files = array_diff(scandir($source), array('.', '..'));
        foreach ($files as $file) {
            if (!rename($source . $file, $destination . $file)) {
                die('Failed to move the WordPress files');
            }
        }

        // Remove the WordPress directory
        if (!@rmdir($installDir . '/wordpress')) {
            die('Failed to remove the WordPress directory');
        }

        // Remove this installer file
        @unlink(__FILE__);

        // Redirect to the WordPress setup page
        header('Location: ./wp-admin/setup-config.php');
        exit;
    } else {
        echo "ZipArchive ERROR..";
    }
}
