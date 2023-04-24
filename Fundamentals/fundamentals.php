<?php
session_start();
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP fundamentals</title>
    <link rel="preconnect" href="https://fonts.gstatic.com">
    <link href="https://fonts.googleapis.com/css2?family=SF+Pro+Text:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=SF+Pro+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="../assets/style.css" rel="stylesheet">
    <script src="../assets/script.js" defer></script>
</head>

<body>
    <div class="toggle-dark-mode" onclick="toggleDarkMode()">🌙</div>
    <br>
    <hr>
    <div class="cards">
        <?php
        // Get a list of files in the projects directory
        $files = scandir('.');

        // Loop through the files and generate the card divs
        foreach ($files as $file) {
            // Ignore . and .. directories
            if ($file === '.' || $file === '..') {
                continue;
            }

            // Get the project description from the Readme.md file
            $description = 'This is a sample ' . $file . ' project.';
            echo '<div class="card" onclick="cardClicked(this)">
            <h2>' . ucfirst($file) . '</h2>
            <p>' . $description . '</p>' .
                '<button onclick="window.location.href=\'./' . $file . '\'">View Source</button>
        </div>';
        }
        ?>
    </div>
    <script>
        function cardClicked(card) {
            card.classList.add('card-clicked');
            setTimeout(() => {
                card.classList.remove('card-clicked');
            }, 200);
        }

        function toggleDarkMode() {
            const body = document.querySelector('body');
            body.classList.toggle('dark-mode');
        }
    </script>
    <hr>
</body>

</html>