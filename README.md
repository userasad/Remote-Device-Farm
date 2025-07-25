# ADB Lab: Remote Android Device Farm

Welcome to ADB Lab! This project provides a set of scripts to create a simple, powerful remote device lab. It allows multiple client machines (including physical PCs and VMs) to connect to, control, and debug Android devices (both physical and emulated) that are attached to a single, central server.

This is ideal for developers, QA testers, and small teams who need to share access to a limited number of Android devices without physically connecting to them.

## Features

- **Centralized Device Access**: Connect all your Android devices to one server machine.
- **Remote Control**: Use `scrcpy` to mirror and control device screens from any client.
- **Remote Flutter Debugging**: Run and debug Flutter applications on remote devices as if they were connected locally.
- **Multi-Client Support**: Multiple users can connect to the lab simultaneously, with dynamic port allocation to prevent conflicts.
- **Easy-to-Use Launcher**: A simple, menu-driven command-line interface for all operations.
- **Simple Setup**: Scripts are included to configure both the server and new clients.

## How It Works

The lab operates on a client-server model:
- **The Server**: A Windows PC where the Android devices and emulators are physically connected. It runs an ADB (Android Debug Bridge) server that listens for network connections.
- **The Clients**: Any Windows PC (physical or a VM) that runs the client scripts to connect to the server. The scripts use a combination of `netsh portproxy` and the `ADB_SERVER_SOCKET` environment variable to forward commands and data streams to the server.

## Getting Started

### Prerequisites

- **Server & Client Machines**: Windows 10 or 11.
- **Android SDK Platform-Tools**: Must be installed and in the system's PATH on both the server and all client machines. This provides `adb.exe`.
- **Scrcpy**: Must be installed and in the system's PATH on all client machines.
- **Flutter SDK**: Must be installed on any client machine that will be used for Flutter development.

### Setup Instructions

**On the Server Machine:**

1.  Clone or download this repository.
2.  Run `run_launcher.cmd`.
3.  Choose **Server Operations**.
4.  Select **(Step 1) Start ADB Server**. This will start the ADB server and configure the firewall.
5.  Select **(Step 2) Start Android Virtual Devices (AVDs)** to launch your emulators.

**On Each Client Machine:**

1.  Clone or download this repository.
2.  Run `run_launcher.cmd`.
3.  Choose **Client Operations**.
4.  Select **(Step 1 - Run Once) Configure Client for Remote ADB**. This will run as Administrator and permanently set up the required environment variable. **You must restart VS Code and any terminals after this step.**
5.  Select **(Step 2 - Run Per Session) Allocate Network Ports**. This reserves the necessary ports for `scrcpy` and Flutter for your current session.
6.  You can now use **(Step 3) Run Remote Scrcpy** or **(Step 4) Run Remote Flutter**.

## Project Structure

```
.
├── bin/                # Scripts for the server machine
│   ├── start_adb.ps1
│   └── start_avds.ps1
├── config/             # Configuration files
│   └── lab_config.json
├── tools/
│   └── client/         # Scripts for the client machines
│       ├── allocate_ports.cmd
│       ├── configure_client.cmd
│       ├── remote_flutter_run.cmd
│       └── remote_scrcpy.cmd
├── .gitignore          # Files and folders to ignore for Git
├── README.md           # This file
└── run_launcher.cmd    # The main entry point for the lab
```
