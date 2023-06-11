# PixelFlut.jl

Julia implementation of the PixelFlut protocol.

Provides functions for client and server applications.

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
