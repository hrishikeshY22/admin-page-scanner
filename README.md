# Admin Page Scanner

A robust Bash script for scanning a target URL for potential admin pages by testing a large list of common admin paths. The script uses `curl` to make HTTP requests and verifies if a page returns a 200 HTTP response code along with common admin keywords (such as "login" or "admin"). Results are logged and successful hits are saved to a separate file.

## Features

- **Parallel Scanning:** Uses `xargs` with a configurable number of concurrent processes.
- **Timeout Control:** Set the maximum time for each HTTP request.
- **Custom User-Agent:** Option to supply your own User-Agent string.
- **Delay Between Requests:** Control the delay between each request.
- **Logging:** Detailed log file (`scan_results.log`) and a separate file for successful admin pages (`admin_hits.log`).
- **Graceful Interruption:** Press CTRL+C to stop the scan gracefully.
- **Pre-Check:** Verifies that the target URL is reachable before scanning begins.

## Requirements

- **Bash** (Linux, macOS, or Windows with a compatible shell like Git Bash)
- **curl**

To install `curl` on Ubuntu/Debian:
```bash
sudo apt-get install curl
```
## Installation

```bash
git clone https://github.com/hrishikeshY22/admin-page-scanner
cd admin-page-scanner
chmod +x scan_admin.sh
```

## Usage 

Run the script with the required and optional parameters:
```bash
./scan_admin.sh -u <url> [-c concurrency] [-t timeout] [-a user_agent] [-d delay]
```

## Options 

* `-u <url>`: Target URL (must include http:// or https://)
* `-c <concurrency>`: Number of concurrent processes (default: 10)
* `-t <timeout>`: Timeout in seconds for each request (default: 5)
* `-a <user_agent>`: Custom User-Agent string (optional)
* `-d <delay>`: Delay in seconds between requests (default: 0)
* `-h`: Display the help message


