const loginFailed = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Failed - XWidget</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #fdf8f8 0%, #fceaea 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            padding: 40px;
        }

        .brand {
            font-size: 13px;
            font-weight: 600;
            color: #1e40af;
            letter-spacing: 0.5px;
            margin-bottom: auto;
        }

        .content {
            text-align: center;
            padding: 20px 0;
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
        }

        .icon-wrap {
            width: 72px;
            height: 72px;
            background: #fee2e2;
            border: 2px solid #fca5a5;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }

        .icon-wrap svg {
            width: 32px;
            height: 32px;
            color: #dc2626;
        }

        h1 {
            font-size: 22px;
            font-weight: 600;
            color: #0f172a;
            margin-bottom: 8px;
        }

        p {
            font-size: 15px;
            color: #64748b;
            line-height: 1.6;
        }

        .error-details {
            background: #fff;
            border: 1px solid #fecaca;
            border-radius: 8px;
            padding: 16px;
            margin-top: 24px;
            text-align: left;
        }

        .error-details-header {
            font-size: 11px;
            font-weight: 600;
            color: #991b1b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }

        .error-code {
            font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
            font-size: 13px;
            color: #7f1d1d;
            background: #fef2f2;
            padding: 10px 12px;
            border-radius: 6px;
            word-break: break-all;
            line-height: 1.5;
        }

        .hint {
            font-size: 13px;
            color: #334155;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="brand">XWIDGET CLOUD</div>
    
    <div class="content">
        <div class="icon-wrap">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
        </div>
        
        <h1>Login Failed</h1>
        <p>We couldn't complete authentication.</p>

        <div class="error-details">
            <div class="error-details-header">Error Details</div>
            <div id="error-code" class="error-code">
                <!-- Replace this content dynamically -->
                invalid_grant: The authorization code has expired or has already been used.
            </div>
        </div>
    </div>

    <p class="hint">Please close this window and try again from your terminal.</p>

    <script>
        const params = new URLSearchParams(window.location.search);
        const error = params.get('error') || 'Authentication failed';
        const message = params.get('message') || '';
        document.getElementById('error-code').textContent = message ? `\${error}: \${message}` : error;
    </script>
</body>
</html>
''';
