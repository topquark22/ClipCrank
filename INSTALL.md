# Installing ClipCrank

ClipCrank is a Bash wrapper around `ffmpeg` and `ffprobe`. It does not require a Python runtime, ImageMagick, or a separate media-processing library.

## Requirements

ClipCrank requires:

- Bash in a POSIX-like shell environment,
- `ffmpeg` available on `PATH`,
- `ffprobe` available on `PATH`.

`ffprobe` is used for media and metadata inspection and for classifying visual input to `--add-audio`.

## Linux and Other POSIX-Like Systems

Install Bash and FFmpeg using the package manager for your operating system. Many systems already include Bash.

For example, on Debian or Ubuntu:

```sh
sudo apt update
sudo apt install bash ffmpeg
```

Verify the required executables:

```sh
bash --version
ffmpeg -version
ffprobe -version
```

Clone or download ClipCrank, then make the script executable:

```sh
chmod +x clipcrank
```

Run it from the repository directory:

```sh
./clipcrank --help
```

You may optionally place `clipcrank` in a directory on your `PATH`.

## Windows

Windows does not provide a native POSIX shell environment, so ClipCrank cannot be run directly from Command Prompt or PowerShell. The tested Windows configuration uses Cygwin to provide Bash and the Unix command-line environment while using native Windows builds of `ffmpeg` and `ffprobe`.

Other Bash-compatible Windows environments may work, but Cygwin is the Windows environment used during ClipCrank development and testing.

### 1. Install Cygwin

Install Cygwin and make sure Bash and the standard Unix command-line utilities are available.

After installation, open a Cygwin terminal and verify Bash:

```sh
bash --version
```

### 2. Install Native Windows FFmpeg

Install a native Windows build of FFmpeg that provides both:

```text
ffmpeg.exe
ffprobe.exe
```

During ClipCrank development, using native Windows FFmpeg from Cygwin proved more practical than relying on a Cygwin-specific FFmpeg package.

Add the directory containing `ffmpeg.exe` and `ffprobe.exe` to a `PATH` visible from the Cygwin shell.

Then verify from Cygwin:

```sh
which ffmpeg
which ffprobe
ffmpeg -version
ffprobe -version
```

Both programs must be callable directly by name before running ClipCrank.

### 3. Cygwin Path Compatibility

There is an important interoperability issue when a Cygwin Bash script invokes native Windows executables.

Cygwin understands POSIX paths such as:

```text
/home/user/work/ClipCrank/examples/video.mp4
```

A native Windows `ffmpeg.exe` or `ffprobe.exe` may not understand that path. This can produce a misleading error such as:

```text
No such file or directory
```

even though Cygwin itself can see and list the file.

Relative paths avoid this problem and are the recommended approach when using native Windows FFmpeg from Cygwin. For example, from the ClipCrank repository root:

```sh
./clipcrank --info examples/Big_Buck_Bunny_720_10s_1MB.webm
```

rather than passing a Cygwin absolute path such as:

```text
/home/user/work/ClipCrank/examples/Big_Buck_Bunny_720_10s_1MB.webm
```

The automated real-media tests follow the same convention and assume they are launched from the repository root.

### 4. Install ClipCrank

Clone or download the repository from within Cygwin and make the script executable:

```sh
chmod +x clipcrank
```

Verify the command:

```sh
./clipcrank --help
```

You may optionally place `clipcrank` in a directory on your Cygwin `PATH`.

## Verify the Installation

From the repository root, the committed Big Buck Bunny fixture provides a convenient installation check:

```sh
./clipcrank --info examples/Big_Buck_Bunny_720_10s_1MB.webm
```

A working installation should report technical information about the WebM file, including its VP9 video stream.

For a fuller check, run the smoke test suite:

```sh
chmod +x test/smoke-test.sh
./test/smoke-test.sh
```

The real-media tests use repository-relative paths specifically so that they also work when Cygwin invokes native Windows `ffmpeg.exe` and `ffprobe.exe`.

## Troubleshooting

If ClipCrank reports that `ffmpeg` or `ffprobe` is not installed or not on `PATH`, verify them directly in the same shell:

```sh
which ffmpeg
which ffprobe
ffmpeg -version
ffprobe -version
```

If a file exists in Cygwin but native Windows FFmpeg reports `No such file or directory`, check whether an absolute Cygwin path is being passed to the native executable. Run ClipCrank from an appropriate working directory and use a relative media path where practical.

If FFmpeg recognizes a container but cannot decode one of its streams, the installed FFmpeg build may lack the required decoder. ClipCrank relies on the codec and format support provided by the local FFmpeg installation.
