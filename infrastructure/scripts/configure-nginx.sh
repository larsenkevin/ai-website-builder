#!/bin/bash
set -e

# NGINX Configuration Script for AI Website Builder
# This script installs and configures NGINX as a static web server
# Requirements: 1.4, 29.1, 29.2, 29.3, 29.5

echo "=========================================="
echo "NGINX Configuration for AI Website Builder"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Install NGINX
echo "Installing NGINX..."
apt-get update
apt-get install -y nginx

# Create web root directory if it doesn't exist
echo "Creating web root directory..."
mkdir -p /var/www/html
chown -R www-data:www-data /var/www/html
chmod 755 /var/www/html

# Create a simple 404 error page
echo "Creating 404 error page..."
cat > /var/www/html/404.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Page Not Found</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 {
            font-size: 6rem;
            margin: 0;
            font-weight: 700;
        }
        h2 {
            font-size: 2rem;
            margin: 1rem 0;
            font-weight: 400;
        }
        p {
            font-size: 1.2rem;
            margin: 1rem 0 2rem;
            opacity: 0.9;
        }
        a {
            display: inline-block;
            padding: 0.75rem 2rem;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            transition: transform 0.2s;
        }
        a:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>404</h1>
        <h2>Page Not Found</h2>
        <p>The page you're looking for doesn't exist or has been moved.</p>
        <a href="/">Go Home</a>
    </div>
</body>
</html>
EOF

chown www-data:www-data /var/www/html/404.html
chmod 644 /var/www/html/404.html

# Create a test index page if one doesn't exist
if [ ! -f /var/www/html/index.html ]; then
    echo "Creating test index page..."
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Website Builder - Test Page</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 2rem;
        }
        
        .container {
            background: white;
            border-radius: 10px;
            padding: 3rem;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        
        h1 {
            color: #667eea;
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        
        .status {
            background: #10b981;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 5px;
            display: inline-block;
            margin-bottom: 1.5rem;
            font-weight: 600;
        }
        
        .info {
            background: #f3f4f6;
            padding: 1.5rem;
            border-radius: 5px;
            margin: 1.5rem 0;
        }
        
        .info h2 {
            color: #667eea;
            font-size: 1.2rem;
            margin-bottom: 0.5rem;
        }
        
        .info ul {
            list-style: none;
            padding-left: 0;
        }
        
        .info li {
            padding: 0.5rem 0;
            border-bottom: 1px solid #e5e7eb;
        }
        
        .info li:last-child {
            border-bottom: none;
        }
        
        .info li strong {
            color: #667eea;
            display: inline-block;
            width: 150px;
        }
        
        .next-steps {
            margin-top: 2rem;
        }
        
        .next-steps h2 {
            color: #667eea;
            margin-bottom: 1rem;
        }
        
        .next-steps ol {
            padding-left: 1.5rem;
        }
        
        .next-steps li {
            margin-bottom: 0.5rem;
        }
        
        .footer {
            margin-top: 2rem;
            padding-top: 1rem;
            border-top: 2px solid #e5e7eb;
            text-align: center;
            color: #6b7280;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 NGINX is Working!</h1>
        <div class="status">✓ Configuration Successful</div>
        
        <p>Your NGINX web server has been successfully configured for the AI Website Builder.</p>
        
        <div class="info">
            <h2>Configuration Details</h2>
            <ul>
                <li><strong>Web Root:</strong> /var/www/html</li>
                <li><strong>Gzip:</strong> Enabled</li>
                <li><strong>Cache Headers:</strong> Configured</li>
                <li><strong>404 Page:</strong> Custom</li>
                <li><strong>Security Headers:</strong> Enabled</li>
            </ul>
        </div>
        
        <div class="info">
            <h2>Features Enabled</h2>
            <ul>
                <li>✓ Gzip compression for text content</li>
                <li>✓ Cache headers for static assets (1 year)</li>
                <li>✓ Cache headers for HTML (1 hour)</li>
                <li>✓ Custom 404 error page</li>
                <li>✓ Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)</li>
                <li>✓ Hidden file protection</li>
                <li>✓ Config file protection</li>
            </ul>
        </div>
        
        <div class="next-steps">
            <h2>Next Steps</h2>
            <ol>
                <li>Set up UFW firewall rules (Task 1.3)</li>
                <li>Configure Tailscale VPN integration (Task 1.4)</li>
                <li>Set up Let's Encrypt SSL automation (Task 1.5)</li>
                <li>Create systemd service files (Task 1.6)</li>
            </ol>
        </div>
        
        <div class="footer">
            <p>AI Website Builder | NGINX Configuration Test Page</p>
            <p>This page can be replaced with your generated website content</p>
        </div>
    </div>
</body>
</html>
EOF
    
    chown www-data:www-data /var/www/html/index.html
    chmod 644 /var/www/html/index.html
    echo "Test index page created at /var/www/html/index.html"
else
    echo "Index page already exists, skipping test page creation"
fi

# Create NGINX configuration for static site
echo "Creating NGINX server configuration..."
cat > /etc/nginx/sites-available/website-builder << 'EOF'
# AI Website Builder - Static Site Configuration
# Serves generated HTML files from /var/www/html

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    root /var/www/html;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        application/atom+xml
        image/svg+xml;
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|webp|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # HTML files - shorter cache
    location ~* \.(html)$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }
    
    # Main location block
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Custom 404 error page
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to config files (if accidentally placed in web root)
    location ~* \.(json|conf|config)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Remove default NGINX site
echo "Configuring NGINX sites..."
rm -f /etc/nginx/sites-enabled/default

# Enable the website-builder site
ln -sf /etc/nginx/sites-available/website-builder /etc/nginx/sites-enabled/

# Test NGINX configuration
echo "Testing NGINX configuration..."
nginx -t

# Restart NGINX to apply changes
echo "Restarting NGINX..."
systemctl restart nginx

# Enable NGINX to start on boot
echo "Enabling NGINX service..."
systemctl enable nginx

# Check NGINX status
echo ""
echo "NGINX Status:"
systemctl status nginx --no-pager

echo ""
echo "=========================================="
echo "NGINX Configuration Complete!"
echo "=========================================="
echo ""
echo "NGINX is now configured to:"
echo "  - Serve static files from /var/www/html"
echo "  - Use gzip compression for text content"
echo "  - Cache static assets with appropriate headers"
echo "  - Serve custom 404 error page"
echo "  - Block access to hidden and config files"
echo ""
echo "Test your configuration:"
echo "  - Visit http://<server-ip>/ to see the test page"
echo "  - Visit http://<server-ip>/nonexistent to see the 404 page"
echo "  - Check gzip: curl -H 'Accept-Encoding: gzip' -I http://<server-ip>/"
echo ""
echo "Next steps:"
echo "  1. Set up UFW firewall rules (Task 1.3)"
echo "  2. Configure Tailscale VPN (Task 1.4)"
echo "  3. Set up Let's Encrypt SSL (Task 1.5)"
echo ""
