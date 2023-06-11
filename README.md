# PixelFlut.jl

Julia implementation of the pixelflut protocol.

Provides functions for client and server applications.

A pixelflut server is provided as `PixelFlut.Server`.

A viewer client is provided as `PixelFlut.Viewer`.
This client connects to a pixelflut server and copies it's contents into a framebuffer.

## Usage

Server example:
```bash
julia -t 8 -e "using PixelFlut; PixelFlut.run(PixelFlut.Server((512, 512))"
```
Vary thread count and canvas size as needed.

Viewer example:
```bash
julia -t 8 -e "using PixelFlut; PixelFlut.run(PixelFlut.Viewer(\"127.0.0.1\", 1337))"
```
Adapt as needed.

# PixelFlut Protocol

- `HELP\n`: Show a help message
- `SIZE\n` Return `(width, height)` of canvas
- `PX {x} {y}\n`: Return `RRGGBB` of pixel at `(x, y)` as `PX {x} {y} {RRGGBB}\n`
- `PX {x} {y} RRGGBB\n`: Set pixel at `(x, y)` to `RRGGBB`
- `PX {x} {y} RRGGBBAA\n`: Set pixel at `(x, y)` to `RRGGBBAA`

# Usage

Connect to server and send the respective command.
For example the following sets the pixel at `(1, 2)` to red:

```bash
echo "PX 1 2 FF0000\n" | netcat 127.0.0.1 1337
```
