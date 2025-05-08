from flask import Flask, request, send_file, abort
import os

app = Flask(__name__)

@app.route("/conf")
def download_file():
    key = request.args.get('key')
    name = request.args.get('name')
    if key == os.getenv("SECRET_KEY"): 
        file_path = f"/etc/wireguard/clients/{name}.conf"
        print(f"Attempting to send file: {file_path}")  
        try:
            return send_file(file_path, as_attachment=True)
        except FileNotFoundError:
            abort(404, description="File not found")
    else:
        abort(403, description="Forbidden: Invalid key")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
