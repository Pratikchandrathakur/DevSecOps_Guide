# EC2 Launch Template and User Data

## Launch Template
- Name: `ecom-launch-template`
- OS: Amazon Linux 2023 or Ubuntu 22.04
- Instance: `t3.micro` or `t3.small`
- IAM Role: least privilege for secret retrieval/logging

## User Data (Bootstrap)
```bash
#!/bin/bash
dnf update -y
dnf install -y httpd php php-mysqli git
git clone https://github.com/siddhantbhattarai/ecom-web-app.git /var/www/html/

cat <<EOF > /var/www/html/config.php
<?php
define('DB_SERVER', '${DB_ENDPOINT}');
define('DB_USERNAME', 'admin');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_DATABASE', 'ecommerce_db');
?>
EOF

echo "healthy" > /var/www/html/healthz.html
chown -R apache:apache /var/www/html
systemctl start httpd
systemctl enable httpd
```

## Important
- Replace inline placeholders with runtime retrieval from Secrets Manager/SSM
- Do not hardcode DB passwords
