{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # niks3-actionが要求する`niks3-hook`を含む新しいniks3は安定版にはまだ無いため、
    # niks3だけはunstableから取得します。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs-unstable,
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
        {
          perSystem =
            { system, ... }:
            {
              _module.args.pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
            };
        }
      ];

      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          pkgs,
          pkgs-unstable,
          ...
        }:
        {
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              deadnix.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
              typos.enable = true;
              zizmor.enable = true;
            };
            settings.formatter = {
              action-validator = {
                command = pkgs.action-validator;
                includes = [
                  ".github/workflows/*.yml"
                  "action.yml"
                ];
              };
              editorconfig-checker = {
                command = pkgs.editorconfig-checker;
                includes = [ "*" ];
              };
              zizmor.options = [ "--pedantic" ];
            };
          };

          packages = {
            # flake.lockの管理バージョンをre-exportすることで安定した利用を促進。
            inherit (pkgs)
              nix-fast-build
              ;
            # action.ymlから参照します。
            # GitHubのリリースアセットサーバは度々ダウンするため、
            # niks3-actionにリリースアセットをダウンロードさせずにNix経由で取得します。
            inherit (pkgs-unstable)
              niks3
              ;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # treefmtで指定したプログラムの単体版。
              action-validator
              actionlint
              deadnix
              editorconfig-checker
              nixfmt
              prettier
              shellcheck
              shfmt
              statix
              typos
              zizmor

              # nixの関連ツール。
              nix-fast-build

              # GitHub関連ツール。
              gh
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://niks3-public.ncaq.net/"
      "https://ncaq.cachix.org/"
      "https://nix-community.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3-public.ncaq.net-1:e/B9GomqDchMBmx3IW/TMQDF8sjUCQzEofKhpehXl04="
      "ncaq.cachix.org-1:XF346GXI2n77SB5Yzqwhdfo7r0nFcZBaHsiiMOEljiE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
