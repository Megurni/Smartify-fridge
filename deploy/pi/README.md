# Pi webpage on localhost and Tailscale

The Pi runs one backend on 5001, one Nginx web service on 8080, and CV as a
separate process. Its own browser opens http://localhost:8080. Other devices
join the authorized Tailscale network and open http://100.112.112.84:8080.
If the Pi's Tailscale IP changes, only the address users open changes.

The same compiled frontend works at both addresses. It requests /api/ on the
current page's origin. Nginx serves the web files and strips /api/ when forwarding
requests to http://127.0.0.1:5001/. Backend routes and CV JSON paths stay unchanged.
The browser never needs to connect directly to port 5001, and no additional
FRONTEND_ORIGIN setting is needed for this same-origin deployment.

## 1. Build the frontend on the development computer

From the frontend repository, without a SMARTIFY_API_URL override:

```sh
flutter build web --release
```

Copy the complete build/web directory and deploy/pi directory to the Pi (USB,
SCP or your usual transfer method). Flutter does not need to be installed on the
Pi to serve the generated files. Do not use flutter run as the deployed server.

## 2. Install the web service on the Pi

These commands assume Raspberry Pi OS / Debian. Run from the frontend repository
on the Pi, after placing the built files in build/web:

```sh
sudo apt update
sudo apt install nginx
sudo install -d -m 755 /var/www/smartify
sudo cp -R build/web/. /var/www/smartify/
sudo find /var/www/smartify -type d -exec chmod 755 {} +
sudo find /var/www/smartify -type f -exec chmod 644 {} +
sudo install -m 644 deploy/pi/smartify.conf /etc/nginx/sites-available/smartify
sudo ln -sfn /etc/nginx/sites-available/smartify /etc/nginx/sites-enabled/smartify
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
```

Port 8080 must be free. This configuration leaves any existing port 80 default
site in place. Later frontend updates require a fresh build and copying all its
files again; refresh the browser afterward.

## 3. Start the backend and CV on the Pi

In the backend directory, using your actual shared file path:

```sh
uv sync
CV_RESULTS_FILE="$HOME/Desktop/smartify-data/result.json" uv run backend.py
```

In a second terminal with the model's Python environment active, from the image
analysis repository (with the JSON export and watch changes installed):

```sh
python use_model.py --images "$HOME/Desktop/smartify-data/camera_photos" --watch --shelf-id 1 --result-json "$HOME/Desktop/smartify-data/result.json"
```

Use an existing backend shelf ID and install all model dependencies/weights.
Both processes use exactly the same file; Tailscale is not needed for that local
file exchange. CV must be tested for available Pi memory and inference speed.
Keep both terminal processes running; Nginx alone is enabled to start at boot.

## 4. Verify on the Pi, then on the secondary device

On the Pi:

```sh
curl http://127.0.0.1:5001/items
curl http://localhost:8080/api/items
```

Both should return the same inventory JSON. Open http://localhost:8080 in the
Pi browser for the UI, not port 5001 (whose root displays Hello, World).

On another authorized Tailscale device, open:

- http://100.112.112.84:8080/api/items to check connectivity.
- http://100.112.112.84:8080 for the same UI and database.

Allow TCP 8080 under your Tailscale access rules and any Pi firewall rules. There
is no need to set up router port forwarding or expose this site publicly.

## Direct local development without Nginx

Flutter's development server does not proxy /api/. Use an explicit backend:

```sh
flutter run -d chrome --dart-define=SMARTIFY_API_URL=http://localhost:5001
```

To target the Pi instead, replace localhost with 100.112.112.84. For a frontend
origin outside localhost, configure the backend's FRONTEND_ORIGIN to that exact
origin when bypassing Nginx. Native app defaults are unchanged.

References: [Flutter web deployment](https://docs.flutter.dev/deployment/web),
[Nginx proxy_pass](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass).
