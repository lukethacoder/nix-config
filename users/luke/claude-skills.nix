{ inputs, lib, ... }:
let
  skillsRepo = inputs.claude-skills;

  # categories within the repo to install (skips deprecated/ and in-progress/)
  categories = [ "engineering" ];

  skillsForCategory = category:
    lib.mapAttrs' (name: _:
      lib.nameValuePair ".claude/skills/${name}" {
        source = "${skillsRepo}/skills/${category}/${name}";
      }
    ) (lib.filterAttrs (_: type: type == "directory")
      (builtins.readDir "${skillsRepo}/skills/${category}"));
in
{
  home.file = lib.mkMerge (map skillsForCategory categories);
}
