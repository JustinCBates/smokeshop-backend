<?php
/**
 * Simple proxy to forward all requests to Node.js app on port 3000
 * This bridges Apache (HTTPS) to the Node.js server (HTTP)
 */

// Disable output buffering to stream responses
if (ob_get_level()) ob_end_clean();

// Target Node.js server
$nodeUrl = 'http://127.0.0.1:3000';

// Get request details
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['REQUEST_URI'];
$url = $nodeUrl . $path;

// Initialize cURL
$ch = curl_init($url);

// Set cURL options
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, false);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

// Forward request headers
$headers = array();
foreach (getallheaders() as $name => $value) {
    if (strtolower($name) !== 'host') {
        $headers[] = "$name: $value";
    }
}
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

// Forward request body for POST/PUT/PATCH
if (in_array($method, ['POST', 'PUT', 'PATCH', 'DELETE'])) {
    $body = file_get_contents('php://input');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
}

// Write response headers
curl_setopt($ch, CURLOPT_HEADERFUNCTION, function($curl, $header) {
    $len = strlen($header);
    $header = explode(':', $header, 2);
    if (count($header) >= 2) {
        $name = trim($header[0]);
        if (strtolower($name) !== 'transfer-encoding') {
            header($name . ': ' . trim($header[1]));
        }
    }
    return $len;
});

// Execute and output response
curl_exec($ch);

// Get HTTP status code and set it
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
http_response_code($httpCode);

curl_close($ch);
