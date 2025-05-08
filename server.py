from flask import Flask, request, send_file, abort
import os

app = Flask(__name__)

@app.route("/file")
def download_file():
    key = request.args.get('key')
    conf_name = request.args.get('conf-name')
    if key == os.getenv("SECRET_KEY"): 
        file_path = f"/etc/wireguard/clients/{conf_name}.conf"  
        try:
            return send_file(file_path, as_attachment=True)
        except FileNotFoundError:
            abort(404, description="File not found")
    else:
        abort(403, description="Forbidden: Invalid key")

if __name__ == "__main__":
    # Generate a random secret key once application starts
    os.environ["SECRET_KEY"] = os.urandom(24).hex()
    print('|' + '-'*20, '-'*24, '-'*20 + '|')
    print('|' + '-'*20, os.environ["SECRET_KEY"], '-'*20 + '|')
    print('|' + '-'*20, 'Server started', '-'*20 + '|')
    print('|' + '-'*20, '-'*24, '-'*20 + '|')
    app.run(host="0.0.0.0", port=5000, debug=True)
