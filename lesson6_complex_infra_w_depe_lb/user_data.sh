#!/bin/bash
# This script runs on instance launch
# Variables are templated from OpenTofu

set -e

# Update system (Amazon Linux 2023)
dnf update -y

# Install Apache and PHP (Amazon Linux 2023)
dnf install -y httpd php php-mysqlnd

# For Ubuntu, use these commands instead:
# apt-get update
# apt-get upgrade -y
# apt-get install -y apache2 php php-mysql

# Configure database connection
cat > /var/www/html/config.php <<'EOF'
<?php
define('DB_HOST', '${db_endpoint}');
define('DB_NAME', '${db_name}');
define('DB_USER', '${db_username}');
define('DB_PASS', '${db_password}');
?>
EOF

# Create simple index page
cat > /var/www/html/index.php <<'EOF'
<?php
require_once 'config.php';
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "<h1>Web Application</h1>";
echo "<p>Database connection successful!</p>";
echo "<p>Server: " . gethostname() . "</p>";
$conn->close();
?>
EOF

# Start Apache (httpd on Amazon Linux, apache2 on Ubuntu)
systemctl restart httpd
systemctl enable httpd

# For Ubuntu, use these commands instead:
# systemctl restart apache2
# systemctl enable apache2