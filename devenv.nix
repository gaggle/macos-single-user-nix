{ pkgs, ... }:

{
  # Tools for working on the installer and the VM test harness.
  packages = with pkgs; [
    bash
    curl
    shellcheck
    sshpass
    expect
    (bats.withLibraries (p: [ p.bats-assert p.bats-support ]))
    # tart is macOS-only; the package is in nixpkgs but only builds on darwin.
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.tart
  ];

  enterShell = ''
    echo "macos-single-user-nix devshell"
    echo "  commands: lint, test-unit, test-vm"
  '';

  # Lint the installer on every devenv invocation.
  scripts.lint.exec = ''
    find . -type f \( -name '*.sh' -o -path './test/bin/*' \) \
      -not -path './.devenv/*' -not -path './.git/*' \
      -not -path './test/unit/.bats_deps/*' \
      -exec shellcheck {} +
  '';

  scripts.test-unit.exec = ''
    bats test/unit/
  '';

  scripts.test-vm.exec = ''
    exec "$DEVENV_ROOT/test/bin/nix-test-vm" "$@"
  '';

  enterTest = ''
    test-unit
    lint
  '';
}
