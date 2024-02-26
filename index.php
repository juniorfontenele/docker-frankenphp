<?php
error_reporting(0);

echo "WEBSERVER OK <br/>" . PHP_EOL;
echo "SERVER HOSTNAME: " . gethostname() . "<br />" . PHP_EOL;
echo "REMOTE IP: " . $_SERVER['REMOTE_ADDR'] . "<br />" . PHP_EOL;
