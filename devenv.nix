{ pkgs, ... }:

{
  # Tools for working on the installer and the VM test harness.
  packages = with pkgs; [
    bash
    curl
    shellcheck
    sshpass
    # tart is macOS-only; the package is in nixpkgs but only builds on darwin.
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.tart
  ];

  enterShell = ''
    echo "macos-single-user-nix devshell"
  '';

  # Lint the installer on every devenv invocation.
  scripts.lint.exec = ''
    find . -type f \( -name '*.sh' -o -path './test/bin/*' \) \
      -not -path './.devenv/*' -not -path './.git/*' \
      -exec shellcheck {} +
  '';

  enterTest = ''
    bash test/run-vm-test.sh "$@"
  '';
}
