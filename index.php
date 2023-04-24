<?php
session_start();
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP SandBox</title>
    <link rel="preconnect" href="https://fonts.gstatic.com">
    <link href="https://fonts.googleapis.com/css2?family=SF+Pro+Text:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=SF+Pro+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="/assets/style.css" rel="stylesheet">
    <script src="/assets/script.js" defer></script>
</head>

<body>
    <h1>The PHP Sandbox</h1>
    <canvas id="particle-canvas"></canvas>
    <div class="toggle-dark-mode" onclick="toggleDarkMode()">🌙</div>
    <br>
    <hr>
    <div class="cards">
        <div class="card cardzero" onclick="cardClicked(this)">
            <h2>Fundamentals</h2>
            <p>Begin here to learn Fundamentals</p>
            <button onclick="window.location.href='./Fundamentals/fundamentals.php'">Source code</button>
        </div>
        <?php

        $projectsDir = './Practice_Projects/';

        // Get a list of files in the projects directory
        $files = scandir($projectsDir);

        // Loop through the files and generate the card divs
        foreach ($files as $file) {
            // Ignore . and .. directories
            if ($file === '.' || $file === '..') {
                continue;
            }

            // Get the project description from the Readme.md file
            $description = 'This is a sample ' . $file . ' project.';
            $readme = './Practice_Projects/' . $file . '/Readme.md';
            if (file_exists($readme)) {
                $lines = file($readme);
                $description = trim($lines[2]);
            }
            // Generate the card div
            echo '<div class="card" onclick="cardClicked(this)">
            <h2>' . ucfirst($file) . '</h2>
            <p>' . $description . '</p>' .
                '<button onclick="window.location.href=\'./Practice_Projects/' . $file . '/index.php' . '\'">Go to Project</button>
            </div>';
        }
        // Redirecting:
        // if (isset($_GET['project'])) {
        //     $project = $_GET['project'];
        //     switch ($project) {
        //         case 'project1':
        //             header('Location: project1.php');
        //             break;
        //         case 'project2':
        //             header('Location: project2.php');
        //             break;
        //         case 'project3':
        //             header('Location: project3.php');
        //             break;
        //     }
        //     exit;
        // }
        ?>

    </div>
    <hr>
</body>

</html>