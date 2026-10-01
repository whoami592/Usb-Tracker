# USB Tracker - Bash Project

**Coded by Cyber Security Engineer Mr Sabaz Ali Khan**

A lightweight Linux Bash project that monitors **USB device plug/unplug events** and stores an audit log.

## Features

- Detects USB device connection events.
- Detects USB device removal events.
- Logs timestamp, vendor, model, serial number (when exposed by the device), USB Vendor ID/Product ID, bus number, and device number.
- Uses Linux `udevadm`; no Python package is required.
- `--quiet` mode for log-only operation.
- Custom log path support.

## Tested/Designed For

Linux distributions that provide `udevadm`, including Kali Linux, Ubuntu, Debian, and many other systemd/udev-based distributions.

## Run

```bash
chmod +x usb_tracker.sh
./usb_tracker.sh
```

Use a custom log file:

```bash
./usb_tracker.sh --log ~/usb-audit.log
```

Log silently:

```bash
./usb_tracker.sh --quiet
```

Stop with:

```text
Ctrl+C
```

## View Logs

```bash
cat logs/usb_events.log
```

Or follow the log live:

```bash
tail -f logs/usb_events.log
```

## Example Log

```text
[2026-09-26 08:42:10] ACTION=ADD | Vendor=SanDisk | Model=Ultra USB 3.0 | Serial=1234567890 | VID:PID=0781:5591 | Bus=001 | Device=005
[2026-09-26 08:45:21] ACTION=REMOVE | Vendor=SanDisk | Model=Ultra USB 3.0 | Serial=1234567890 | VID:PID=0781:5591 | Bus=001 | Device=005
```

## Security / Privacy Note

Use this project only on systems you own or administer with permission. It records USB device metadata only; it does not copy, open, or exfiltrate files from connected USB storage.

## Project Structure

```text
usb-tracker-bash/
├── usb_tracker.sh
├── README.md
└── logs/
```
