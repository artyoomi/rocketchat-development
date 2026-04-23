## Description

Helpers to start Rocket.Chat development container localy in locations, where
download URLs are unavailable.

## Features
Now it makes possible to proxy all connections in Rocket.Chat development container.
But you need another proxy to build container itself.

## Dependencies
- `docker==29.3.1`
- `docker-compose==5.1.3`

## Usage
To start you need to execute one script
```
./wrapper.sh
```
It will clone all dependencies and prompt you through steps.
