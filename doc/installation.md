## How to install `sparkly_lite` on macOS

This guide installs `sparkly_lite` on a Mac with Apple silicon, which is the only kind of machine `sparkly_lite` currently supports. Every command and function of `sparkly_lite`, and every part of the [tutorial](tutorial.md), runs on it.

The installation produces a Python environment, the `.venv` folder, inside the `sparkly_lite` folder. Nothing is installed system-wide by the installer, and nothing outside the `sparkly_lite` folder is modified. The prerequisites in Step 1, `git` and Python, are installed separately, before the installer runs.

This guide was tested on a Mac with an M5 Pro chip running macOS 26.4, with Python 3.9.6 and git 2.50.1.

---

## Step 1: Check the prerequisites

`sparkly_lite` needs a Mac with Apple silicon, such as an M1 or later, macOS 11 or later, and Python 3.9 or later. Downloading it needs `git`. On a Mac, `git` and Python 3.9 both come with the Xcode Command Line Tools.

### The chip and the macOS version

Open Terminal (in Applications > Utilities) and execute:

```
uname -m
sw_vers -productVersion
```

You should see `arm64`, followed by a macOS version of 11 or later:

```
arm64
26.4
```

| What you see | What it means | What to do |
|---|---|---|
| `x86_64` | The Mac has an Intel processor. | `sparkly_lite` does not run on this Mac. |
| A version below 11, such as `10.15.7` | macOS is older than version 11. | Update macOS in System Settings > General > Software Update. |

### Git and Python

Execute:

```
git --version
python3 --version
```

You should see a version of git, and Python 3.9 or later:

```
git version 2.50.1 (Apple Git-155)
Python 3.9.6
```

| What you see | What it means | What to do |
|---|---|---|
| A window that asks to install the command line developer tools | The Xcode Command Line Tools, which provide `git` and `python3`, are not installed. | Click **Install** and wait for the installation to finish, which often takes a few minutes. Then execute the two commands again. |
| `xcrun: error: invalid active developer path` | The Command Line Tools are missing, which happens after some macOS updates. | Execute `xcode-select --install`, click **Install**, and execute the two commands again. |
| `Python 3.8.2`, or another version below 3.9 | The default `python3` is too old. | Download the macOS installer of Python 3.12 from [python.org](https://www.python.org/downloads/macos/) and run it. It makes `python3` Python 3.12. |

---

## Step 2: Download `sparkly_lite`

In Terminal, go to the folder where `sparkly_lite` should be installed, such as your home folder, and execute:

```
git clone https://github.com/relixa-ai/sparkly_lite.git
```

This creates the folder `sparkly_lite`, of about 50 MB, most of which is the included datasets. It contains:

```
LICENSE
README.md
data
demo.ipynb
doc
install.sh
sparkly_lite-0.1.0-cp39-abi3-macosx_11_0_arm64.whl
```

| What you see | What it means | What to do |
|---|---|---|
| `fatal: destination path 'sparkly_lite' already exists and is not an empty directory.` | A folder named `sparkly_lite` already exists here. | Run the command in another folder, or rename or remove the existing one. |

---

## Step 3: Run the installer

Go to the `sparkly_lite` folder and execute:

```
cd sparkly_lite
bash install.sh
```

This command does the following.

- **Checks the Mac** for Apple silicon, and **checks Python** for `python3` of version 3.9 or later.
- **Creates the folder `.venv`** inside the `sparkly_lite` folder, which is a Python environment separate from the system's Python.
- **Installs `sparkly_lite`** into `.venv` from the wheel file in the folder, together with its two dependencies, NumPy and PyArrow, which `pip` downloads from the Python Package Index ([pypi.org](https://pypi.org)). It also updates `pip` and `wheel` inside `.venv`. Running the installer again installs fresh copies of these packages.
- **Runs a short test**, `sparkly-lite smoke`, which performs a search on two records to check that `sparkly_lite` runs on this Mac.

You should see output like the following, with your own paths and versions. It took 7 seconds on the Mac this guide was tested on, with NumPy and PyArrow already in the cache of `pip`.

```
[1/4] checking your machine
      OK — Apple Silicon Mac (arm64, macOS 26.4)
[2/4] checking Python
      OK — Python 3.9.6 at /usr/bin/python3
[3/4] creating .venv and installing sparkly_lite (+ numpy, pyarrow)
Processing ./sparkly_lite-0.1.0-cp39-abi3-macosx_11_0_arm64.whl
...
Successfully installed numpy-2.0.2 pyarrow-21.0.0 sparkly-lite-0.1.0
      OK — installed into /Users/yourname/sparkly_lite/.venv
[4/4] smoke test
sparkly-lite: smoke test
  OK — sparkly_lite runs on this machine.

──────────────────────────────────────────────────────────────────────
 Installation complete.

 Next, turn on the environment (do this once per terminal window):

     source .venv/bin/activate

 Then run your first blocking job:

     sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet

 The tutorial is doc/tutorial.md.
──────────────────────────────────────────────────────────────────────
```

If you see `OK — sparkly_lite runs on this machine.` and `Installation complete.`, `sparkly_lite` is installed. Activate the environment and run the first part of the tutorial:

```
source .venv/bin/activate
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet
```

---

## Checking the installation

`sparkly-lite smoke` runs the test of the installer again:

```
source .venv/bin/activate
sparkly-lite smoke
```

```
sparkly-lite: smoke test
  OK — sparkly_lite runs on this machine.
```

---

## Troubleshooting

| What you see | What it means | What to do |
|---|---|---|
| `ERROR: sparkly_lite needs an Apple Silicon Mac (macOS, arm64).` | The Mac has an Intel processor. | `sparkly_lite` does not run on this Mac. |
| `ERROR: python3 was not found on your machine.` | No `python3` is installed. | Install the Command Line Tools or Python as in Step 1. |
| `ERROR: sparkly_lite needs Python 3.9 or newer.` | The default `python3` is older than 3.9. | Install Python 3.12 as in Step 1. |
| `no such file or directory: install.sh` | Terminal is not in the `sparkly_lite` folder. | Execute `cd sparkly_lite` in the folder where you ran `git clone`, then run the installer. |
| Errors that mention the network, or `Could not find a version` | A package could not be downloaded in step [3/4]. | Check the internet connection and run the installer again. Running it twice is safe. |
| `"sl_engine.dylib" cannot be opened because the developer cannot be verified` | macOS blocked a compiled file of `sparkly_lite`. This happens when an installed `sparkly_lite` folder is copied from another Mac. | Run `bash install.sh` again in the `sparkly_lite` folder, which installs fresh copies of the files. |
| `command not found: sparkly-lite` | The environment is not active in this Terminal window. | Run `source .venv/bin/activate` in the `sparkly_lite` folder. The prompt then starts with `(.venv)`. |

If your problem is not listed, contact [our team](mailto:hello@relixa.ai) and include the full output of `bash install.sh`.

---

## How to uninstall

Everything the installer created is in the `sparkly_lite` folder. To remove the Python environment, execute `rm -rf .venv` in that folder. To remove `sparkly_lite` completely, drag the `sparkly_lite` folder to the Trash.
