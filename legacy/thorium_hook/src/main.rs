//! Astra Browser Native Rust Launcher & Engine Controller
//!
//! Boots Astra with zero overhead, serves the offline newtab interface,
//! manages isolated user profiles, and bootstraps the Astra-style vertical
//! tab strip and modern settings layer.

use std::env;
use std::fs;
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;

const PORT: u16 = 4545;

fn mime_type_for(path: &str) -> &'static str {
    if path.ends_with(".html") {
        "text/html; charset=utf-8"
    } else if path.ends_with(".js") {
        "application/javascript"
    } else if path.ends_with(".json") {
        "application/json"
    } else if path.ends_with(".css") {
        "text/css"
    } else if path.ends_with(".png") {
        "image/png"
    } else if path.ends_with(".svg") {
        "image/svg+xml"
    } else if path.ends_with(".ico") {
        "image/x-icon"
    } else if path.ends_with(".woff2") {
        "font/woff2"
    } else if path.ends_with(".woff") {
        "font/woff"
    } else if path.ends_with(".otf") {
        "font/otf"
    } else if path.ends_with(".ttf") {
        "font/ttf"
    } else if path.ends_with(".webmanifest") {
        "application/manifest+json"
    } else {
        "application/octet-stream"
    }
}

fn send_response(mut stream: TcpStream, status: &str, content_type: &str, body: &[u8]) {
    let header = format!(
        "HTTP/1.1 {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n\r\n",
        status,
        content_type,
        body.len()
    );
    let _ = stream.write_all(header.as_bytes());
    let _ = stream.write_all(body);
    let _ = stream.flush();
}

fn url_decode(s: &str) -> String {
    let mut result = String::new();
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '%' {
            let h1 = chars.next().unwrap_or('0');
            let h2 = chars.next().unwrap_or('0');
            let hex_str = format!("{}{}", h1, h2);
            if let Ok(byte) = u8::from_str_radix(&hex_str, 16) {
                result.push(byte as char);
            }
        } else if c == '+' {
            result.push(' ');
        } else {
            result.push(c);
        }
    }
    result
}

fn handle_api_setting(stream: TcpStream, raw_request: &str) {
    let home = env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let conf_dir = PathBuf::from(home).join("Library/Application Support/Astra");
    let _ = fs::create_dir_all(&conf_dir);
    let conf_path = conf_dir.join("astra_settings.json");

    if let Some(json_idx) = raw_request.find("json=") {
        let rest = &raw_request[json_idx + 5..];
        let end_idx = rest.find(|c| c == ' ' || c == '\r' || c == '\n').unwrap_or(rest.len());
        let decoded = url_decode(&rest[..end_idx]);
        let _ = fs::write(&conf_path, decoded);
    } else if let Some(key_idx) = raw_request.find("key=") {
        let rest_k = &raw_request[key_idx + 4..];
        let end_k = rest_k.find(|c| c == '&' || c == ' ' || c == '\r' || c == '\n').unwrap_or(rest_k.len());
        let key = &rest_k[..end_k];

        let mut val = "";
        if let Some(val_idx) = raw_request.find("val=") {
            let rest_v = &raw_request[val_idx + 4..];
            let end_v = rest_v.find(|c| c == '&' || c == ' ' || c == '\r' || c == '\n').unwrap_or(rest_v.len());
            val = &rest_v[..end_v];
        }

        let json_body = format!("{{\"{}\":\"{}\"}}\n", key, val);
        let _ = fs::write(&conf_path, json_body);
    }

    let resp = b"{\"ok\":true}";
    send_response(stream, "200 OK", "application/json", resp);
}

fn serve_file(stream: TcpStream, newtab_dir: &Path, rel_path: &str) {
    let clean_path = rel_path.trim_start_matches('/');
    let target_name = if clean_path.is_empty() {
        "index.html"
    } else {
        clean_path
    };

    if target_name.contains("..") {
        send_response(stream, "403 Forbidden", "text/plain", b"Forbidden");
        return;
    }

    let file_path = newtab_dir.join(target_name);
    match fs::read(&file_path) {
        Ok(data) => {
            send_response(stream, "200 OK", mime_type_for(target_name), &data);
        }
        Err(_) => {
            send_response(stream, "404 Not Found", "text/plain", b"Not Found");
        }
    }
}

fn handle_connection(mut stream: TcpStream, newtab_dir: &Path) {
    let mut buffer = [0u8; 4096];
    let n = match stream.read(&mut buffer) {
        Ok(bytes) if bytes > 0 => bytes,
        _ => return,
    };

    let req_str = String::from_utf8_lossy(&buffer[..n]);
    let mut lines = req_str.lines();
    let first_line = match lines.next() {
        Some(l) => l,
        None => return,
    };

    let parts: Vec<&str> = first_line.split_whitespace().collect();
    if parts.len() < 2 {
        return;
    }

    let mut path = parts[1];
    if path.starts_with("/api/setting") {
        handle_api_setting(stream, &req_str);
        return;
    }

    if let Some(q_idx) = path.find('?') {
        path = &path[..q_idx];
    }
    if let Some(f_idx) = path.find('#') {
        path = &path[..f_idx];
    }

    serve_file(stream, newtab_dir, path);
}

fn run_embedded_server(newtab_dir: PathBuf) {
    let listener = match TcpListener::bind(("127.0.0.1", PORT)) {
        Ok(l) => l,
        Err(_) => {
            // Port might already be bound by a previous instance
            return;
        }
    };

    for stream in listener.incoming() {
        if let Ok(stream) = stream {
            let dir_clone = newtab_dir.clone();
            thread::spawn(move || {
                handle_connection(stream, &dir_clone);
            });
        }
    }
}

fn main() {
    let self_exe = env::current_exe().unwrap_or_else(|_| PathBuf::from("./Astra"));
    let mac_dir = self_exe.parent().unwrap_or_else(|| Path::new("."));

    let target_bin = mac_dir.join("Astra_bin");
    let newtab_dir = mac_dir.join("../Resources/newtab").canonicalize().unwrap_or_else(|_| mac_dir.join("../Resources/newtab"));

    // Spawn the embedded HTTP server in background thread
    let srv_dir = newtab_dir.clone();
    thread::spawn(move || {
        run_embedded_server(srv_dir);
    });

    // Profile and User-Data paths
    let home = env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let user_data_arg = format!("--user-data-dir={}/Library/Application Support/Astra", home);

    // Initial URL check from CLI args
    let args: Vec<String> = env::args().collect();
    let mut initial_url = "chrome://newtab".to_string();
    let mut extra_args = Vec::new();

    for arg in args.iter().skip(1) {
        if arg.starts_with("-psn") {
            continue;
        }
        if !arg.starts_with('-') {
            initial_url = arg.clone();
        } else {
            extra_args.push(arg.clone());
        }
    }

    // Build the launch flags
    let mut cmd = Command::new(&target_bin);
    cmd.arg(&user_data_arg)
        .arg("--no-first-run")
        .arg("--no-default-browser-check")
        .arg("--disable-search-engine-choice-screen")
        .arg("--start-maximized")
        .arg("--window-size=1440,900")
        .arg("--window-position=0,0")
        .arg("--homepage=chrome://newtab")
        .arg("--disable-features=ChromeLabs,SidePanel,SidePanelPinning,LensOverlay,OmniboxTrendingZeroPrefixSuggestionsOnNTP,OmniboxZeroSuggestPrefetching,SharingHubDesktopAppMenu")
        .arg(&initial_url);

    for extra in extra_args {
        cmd.arg(extra);
    }

    // Inject Astra Cocoa/Astra native hook dylib
    let hook_dylib = mac_dir.join("../Frameworks/libastra_hook.dylib");
    if let Ok(canonical_hook) = hook_dylib.canonicalize() {
        cmd.env("DYLD_INSERT_LIBRARIES", canonical_hook.to_string_lossy().to_string());
    }

    // Execute Astra_bin replacing the current process image
    let err = cmd.exec();
    eprintln!("Failed to exec Astra_bin: {}", err);
}
