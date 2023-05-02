<?php
session_start();
// Outputs
?>
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
            xhr.open('GET', '<?php echo __FILE__ ?>');
            xhr.onload = () => {
                resultDiv.innerHTML = xhr.responseText;
            };
            xhr.send();
        });
    </script>
    <?php //codeTorun
    /* ------- Outputting Content ------- */
    /*
    A .php file running on a server, can output both HTML and PHP code.
    There are multiple functions that can be used to output data to the browser.
    */
    // Echo - Output strings, numbers, html, etc
    echo 'Hello';
    echo 123;
    echo '<h1>Hello</h1>';

    // print - Similar to echo, but a bit slower
    print 'Hello';

    // print_r - Gives a bit more info. Can be used to print arrays
    print_r('Hello');
    print_r([1, 2, 3]);

    // var_dump - Even more info like data type and length
    var_dump('Hello');
    var_dump([1, 2, 3]);

    // Escaping characters with a backslash
    echo "Is your name O\'reilly?";

    /* ------------ Comments ------------ */

    // This is a single line comment

    /*
      * This is a multi-line comment
      *
      * It can be used to comment out a block of code
      */

    // If there is more content after the PHP, such as this file, you do need the ending tag. Otherwise you do not.
    ?>
</body>

</html>