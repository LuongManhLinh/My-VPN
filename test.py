from flask import Flask, request, send_file, abort
import os

app = Flask(__name__)

@app.route("/file")
def download_file():
    key = request.args.get('key')
    idx = request.args.get('idx')
    if key == os.getenv("SECRET_KEY"): 
        file_path = f"/etc/wireguard/clients/client{idx}.conf"  
        try:
            return send_file(file_path, as_attachment=True)
        except FileNotFoundError:
            abort(404, description="File not found")
    else:
        abort(403, description="Forbidden: Invalid key")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
