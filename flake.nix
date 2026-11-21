{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        treefmt-nix.flakeModule
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        {
          pkgs,
          ...
        }:
        let
          # niks3-actionは自身が固定するniks3のバージョンを前提に動作しますが、
          # nixpkgsのniks3は上流のリリースに追従するまで時間がかかるため、
          # 上流のリポジトリから直接取得します。
          # flake inputではなく`fetchTree`でコミットを固定しているのは、
          # Renovateのnixマネージャがflake inputのタグを書き換えられないためです。
          # `rev`とその後ろのタグのコメントは、
          # renovate.jsonのカスタムマネージャがniks3-actionと同時に更新します。
          # 行の形式を変える時はrenovate.jsonの正規表現も合わせてください。
          niks3-src = builtins.fetchTree {
            type = "github";
            owner = "Mic92";
            repo = "niks3";
            rev = "1d40c4a0730ad3d19bec74058606bf6b5c72daf7"; # v1.16.1
          };
          niks3-packages = import "${niks3-src}/nix/packages" { inherit pkgs; };
        in
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
            # niks3-actionは`niks3`と同じディレクトリにある`niks3-hook`を起動しますが、
            # 上流では別々のパッケージなので1つにまとめます。
            niks3 = pkgs.symlinkJoin {
              pname = "niks3";
              inherit (niks3-packages.niks3) version;
              paths = [
                niks3-packages.niks3
                niks3-packages.niks3-hook
              ];
              meta.mainProgram = "niks3";
            };
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
