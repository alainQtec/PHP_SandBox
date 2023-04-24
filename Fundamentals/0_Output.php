<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>php Output</title>
</head>

<body>
    <button id="run-php">Run the code</button>
    <div class="playground">
        <div class="card result"></div>
        <div class="card code">
            <?php
            // Get the current file path
            $file = __FILE__;

            // Get the content of the file
            $content = file_get_contents($file);

            // Get the PHP code inside the PHP tags
            preg_match('/<\?php\s\/\/codeToRun(.*?)\?>/s', $content, $matches);

            // Highlight and display the PHP code
            echo highlight_string($matches[1], true);
            ?>
        </div>
    </div>
    <script>
        const button = document.getElementById('run-php');
        const resultDiv = document.querySelector('.result');
        button.addEventListener('click', () => {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', 'path/to/this/index.php');
            xhr.onload = () => {
                resultDiv.innerHTML = xhr.responseText;
            };
            xhr.send();
        });
    </script>
    <?php //codeTorun
    echo 'This is the result of my PHP code.';
    ?>
</body>

</html>