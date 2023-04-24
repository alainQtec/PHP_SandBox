<?php
// Set the HTTP response code to 404 Not Found
http_response_code(404);
?>

<!DOCTYPE html>
<html>

<head>
    <title>Page Not Found</title>
    <style>
        body {
            font-family: sans-serif;
            background-color: #f2f2f2;
            text-align: center;
            padding-top: 50px;
        }

        h1 {
            font-size: 48px;
            margin-bottom: 20px;
        }

        p {
            font-size: 24px;
            margin-bottom: 40px;
        }

        a {
            color: #0096c7;
            text-decoration: none;
            font-size: 18px;
        }

        a:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>
    <h1>404 - Page Not Found</h1>
    <p>Sorry, the page you are looking for does not exist.</p>
    <a href="./index.php">Go back to the SandBox!</a>
</body>

</html>