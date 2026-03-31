const loginSuccess = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login Successful - XWidget</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #f8fbff 0%, #e8f4fc 100%);
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
            background: #dcfce7;
            border: 2px solid #86efac;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }

        .icon-wrap svg {
            width: 32px;
            height: 32px;
            color: #16a34a;
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
                <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
            </svg>
        </div>
        
        <h1>Login Successful</h1>
        <p>You have been successfully authenticated.</p>
    </div>

    <p class="hint">You may close this window and return to the terminal to continue.</p>
</body>
</html>
''';
