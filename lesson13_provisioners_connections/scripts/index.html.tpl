<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenTofu Provisioners Lab</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }

        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 800px;
            width: 100%;
            padding: 40px;
        }

        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
            text-align: center;
        }

        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 1.2em;
        }

        .badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin: 5px;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }

        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }

        .info-card h3 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 1.1em;
        }

        .info-card p {
            color: #333;
            word-break: break-all;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }

        .status {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: center;
            font-weight: bold;
        }

        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #eee;
            color: #666;
        }

        .feature-list {
            margin: 20px 0;
            padding-left: 20px;
        }

        .feature-list li {
            margin: 10px 0;
            color: #333;
        }

        .emoji {
            font-size: 1.5em;
            margin-right: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 OpenTofu Provisioners Lab</h1>
        <p class="subtitle">EC2 Instance Configured via Provisioners</p>

        <div class="status">
            ✅ Instance Successfully Deployed & Configured!
        </div>

        <div class="info-grid">
            <div class="info-card">
                <h3>📦 Instance ID</h3>
                <p>${instance_id}</p>
            </div>

            <div class="info-card">
                <h3>💻 Instance Type</h3>
                <p>${instance_type}</p>
            </div>

            <div class="info-card">
                <h3>🌍 Public IP</h3>
                <p>${public_ip}</p>
            </div>

            <div class="info-card">
                <h3>🔒 Private IP</h3>
                <p>${private_ip}</p>
            </div>

            <div class="info-card">
                <h3>🗺️ Region</h3>
                <p>${region}</p>
            </div>

            <div class="info-card">
                <h3>🏷️ Environment</h3>
                <p>${environment}</p>
            </div>

            <div class="info-card">
                <h3>🎲 Random Suffix</h3>
                <p>${random_suffix}</p>
            </div>

            <div class="info-card">
                <h3>⏰ Deployed At</h3>
                <p id="timestamp"></p>
            </div>
        </div>

        <h2 style="color: #667eea; margin: 30px 0 20px 0;">Provisioners Demonstrated</h2>
        <ul class="feature-list">
            <li><span class="emoji">📝</span><strong>local-exec:</strong> Created local inventory and SSH config</li>
            <li><span class="emoji">🔧</span><strong>remote-exec:</strong> Installed and configured Apache HTTPD</li>
            <li><span class="emoji">📁</span><strong>file:</strong> Uploaded this HTML page and configuration files</li>
            <li><span class="emoji">🔐</span><strong>connection:</strong> SSH connection with key-based authentication</li>
            <li><span class="emoji">⚠️</span><strong>error handling:</strong> on_failure and when parameters in action</li>
        </ul>

        <h2 style="color: #667eea; margin: 30px 0 20px 0;">What Was Configured</h2>
        <ul class="feature-list">
            <li><span class="emoji">✅</span>System packages updated via user_data</li>
            <li><span class="emoji">✅</span>Apache HTTPD installed via remote-exec</li>
            <li><span class="emoji">✅</span>Custom web page uploaded via file provisioner</li>
            <li><span class="emoji">✅</span>Service started and enabled</li>
            <li><span class="emoji">✅</span>Local inventory files created</li>
            <li><span class="emoji">✅</span>SSH configuration generated</li>
        </ul>

        <div class="footer">
            <p><strong>OpenTofu Lesson 13</strong></p>
            <p>Provisioners & Connections Lab</p>
            <p style="margin-top: 10px; font-size: 0.9em;">
                <span class="badge">Infrastructure as Code</span>
                <span class="badge">DevOps</span>
                <span class="badge">AWS</span>
            </p>
        </div>
    </div>

    <script>
        // Display current timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();

        // Add smooth fade-in animation
        document.querySelector('.container').style.opacity = '0';
        setTimeout(() => {
            document.querySelector('.container').style.transition = 'opacity 0.5s';
            document.querySelector('.container').style.opacity = '1';
        }, 100);
    </script>
</body>
</html>
