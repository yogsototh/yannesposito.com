# Setting up Nix for her.esy.fun

This project uses Nix flakes for a fully reproducible development environment. All dependencies (pandoc, imagemagick, Haskell, etc.) are precisely pinned to specific versions.

## Why Nix?

- **Reproducible**: Same environment on any machine
- **Sustainable**: 15-20 year lifespan
- **No dependency hell**: All tools and versions locked
- **Zero cloud accounts**: Completely local and open source

## Installing Nix

### macOS and Linux

Install Nix using the Determinate Systems installer (recommended):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

This installer:
- Enables flakes by default
- Sets up the Nix daemon properly
- Works on macOS (including Apple Silicon)
- Includes automatic uninstaller

### Verification

After installation, verify Nix is working:

```bash
nix --version
```

You should see output like:
```
nix (Nix) 2.XX.X
```

## Using the Development Environment

### Enter the development shell

```bash
cd /path/to/her.esy.fun
nix develop
```

The first time you run this, Nix will download all dependencies. This may take a few minutes but only happens once. Subsequent runs are instant.

### Build the site

Once in the Nix shell:

```bash
make          # Build entire site
make serve    # Serve locally on http://localhost:3077
make watch    # Watch for changes and rebuild automatically
make help     # Show all available commands
```

### What's included?

The Nix environment provides:

- **Build tools**: make, pandoc, minify, html-xml-utils
- **Image processing**: imagemagick, libwebp (cwebp)
- **Haskell**: GHC 9.6.5 with protolude, turtle, ansi-terminal
- **Shell tools**: zsh, perl
- **Development**: fswatch, entr, direnv, tmux
- **Serving**: lighttpd, http-server
- **Deployment**: rsync
- **Utilities**: git, ripgrep

## Updating Dependencies

The `flake.lock` file pins all dependencies to specific versions. To update:

```bash
# Update all inputs to latest versions
nix flake update

# Update specific input only
nix flake update nixpkgs
```

## Troubleshooting

### Command not found

If you get "command not found" errors, make sure you're inside the Nix shell:

```bash
nix develop
```

### Flake evaluation errors

If you get flake-related errors, ensure experimental features are enabled:

```bash
# Check your Nix config
cat ~/.config/nix/nix.conf
```

Should contain:
```
experimental-features = nix-command flakes
```

The Determinate Systems installer sets this automatically.

### Disk space

Nix stores all packages in `/nix/store`. To free up space:

```bash
# Remove old unused packages
nix-collect-garbage

# More aggressive cleanup (removes old generations)
nix-collect-garbage -d
```

## Reproducibility Guarantee

This setup guarantees that:

1. **Same versions everywhere**: `flake.lock` ensures everyone uses identical tool versions
2. **Works offline**: Once downloaded, no internet needed
3. **No global pollution**: Dependencies don't affect your system
4. **Easy cleanup**: Just delete `/nix` to remove everything

## Learn More

- [Nix Flakes Manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- [Nix Package Search](https://search.nixos.org/packages)
- [Determinate Systems Nix Installer](https://github.com/DeterminateSystems/nix-installer)
