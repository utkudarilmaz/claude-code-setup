# Inputs: $target, $last, $base, $overrides (slurped files) and $prune (space separated top-level keys).
# Output: {settings, managed, removed}.
# Arrays and empty objects are leaves, so `*` replaces them whole.

def leafpaths:
  if type == "object" and length > 0
  then to_entries[] | .key as $k | .value | leafpaths | [$k] + .
  else []
  end;

def leaves: [leafpaths | select(length > 0)];

def reachable($doc): select(. as $p | try ($doc | getpath($p) | true) catch false);

def prune_empty_parents($paths):
  reduce $paths[] as $p (.;
    reduce range(($p | length) - 1; 0; -1) as $i (.;
      $p[:$i] as $q
      | if (try getpath($q) catch null) == {} then delpaths([$q]) else . end));

$target[0] as $t
| $last[0] as $l
| ($base[0] * $overrides[0]) as $merged
| [$merged | leaves[] as $p | select($merged | getpath($p) == null) | $p] as $nulls
| ($merged | delpaths($nulls) | prune_empty_parents($nulls)) as $managed
| [$prune | splits("[ ,]+") | select(length > 0)] as $pruneKeys
| if any($pruneKeys[]; . == "env")
  then error("PRUNE must not include env, it holds machine secrets")
  else . end
| if ($merged | has("env")) and ($merged.env | type) != "object"
  then error("env in the repo or the overrides must be an object, it holds machine secrets")
  else . end
| ($managed | leaves) as $keep
| (($l | leaves) + [$t | leaves[] | select(.[0] as $k | any($pruneKeys[]; . == $k))] + $nulls)
  as $candidates
| [$candidates | unique[]
    | select(. as $p | $keep | index([$p]) | not)
    | reachable($t)
    | select(. as $p | ($nulls | index([$p])) != null
        or ($t | getpath($p) | type != "object" or length == 0))
  ] as $removed
| {
    settings: (($t | delpaths($removed) | prune_empty_parents($removed)) * $managed),
    managed: (reduce ($managed | leaves[]) as $p ($managed; setpath($p; true))),
    removed: [$removed[] | select(. as $p | $t | getpath($p) != null) | map(tostring) | join(".")]
  }
