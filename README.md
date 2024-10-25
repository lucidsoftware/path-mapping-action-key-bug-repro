This repository demonstrates what I think is a bug with Bazel's experimental
[path mapping](https://github.com/bazelbuild/bazel/discussions/22658) feature.

It defines two rules, both of which explicitly support path mapping: `static_file` and `copy_file`.
`static_file` executes a single action with no inputs and a single output. `copy_file` executes a
single action with a single input and which produces a single output by copying that input.

I've also defined a transition that's used by `copy_file`. This transition doesn't actually do
anything; it only superficially changes the configuration.

With the following build graph, you'd expect that `//example:file`, the `static_file` target, would
be built once, given that it doesn't depend on the configuration and path mapping has been enabled.
```
$ bazel cquery 'kind("_file rule$", //example:*)' --output graph 2> /dev/null
digraph mygraph {
  node [shape=box];
  "//example:copied-file-with-transition (f76840c)"
  "//example:copied-file-with-transition (f76840c)" -> "//example:file (f76840c)"
  "//example:file (f76840c)"
  "//example:copied-file (c1d7d5e)"
  "//example:copied-file (c1d7d5e)" -> "//example:file (c1d7d5e)"
  "//example:file (c1d7d5e)"
}
```

On the contrary, you can see that both actions have different keys:
```
$ bazel aquery 'mnemonic("^StaticFile$", //example:*)' 2> /dev/null
action 'StaticFile example/file/output.txt'
  Mnemonic: StaticFile
  Target: //example:file
  Configuration: k8-fastbuild
  Execution platform: @platforms//host:host
  ActionKey: c9ae080d33af20a932add51ec0e6cc254236ea8a94b738504446f0d775587c06
  Inputs: []
  Outputs: [bazel-out/k8-fastbuild/bin/example/file/output.txt]
  Command Line: (exec /bin/bash \
    -c \
    'echo '\''Generating static file...'\''; echo "$1" > "$2"' \
    '' \
    'Hello, world!' \
    bazel-out/cfg/bin/example/file/output.txt)
# Configuration: c1d7d5ec98965ef297d5c260736c24f7fcb9fd5039103a0c4ab253e2b94ae32b
# Execution platform: @@platforms//host:host
  ExecutionInfo: {supports-path-mapping: 1}

action 'StaticFile example/file/output.txt'
  Mnemonic: StaticFile
  Target: //example:file
  Configuration: k8-fastbuild-ST-5307abf5ab74
  Execution platform: @platforms//host:host
  ActionKey: f7caf91c7b5ef86027a9e7626f908d6da91f4a91d21822caa36577e050fa88fe
  Inputs: []
  Outputs: [bazel-out/k8-fastbuild-ST-5307abf5ab74/bin/example/file/output.txt]
  Command Line: (exec /bin/bash \
    -c \
    'echo '\''Generating static file...'\''; echo "$1" > "$2"' \
    '' \
    'Hello, world!' \
    bazel-out/cfg/bin/example/file/output.txt)
# Configuration: f76840c7907404a39a65c1092de1b228fa4531b1346c5496a0411cd03b780c68
# Execution platform: @@platforms//host:host
  ExecutionInfo: {supports-path-mapping: 1}

```

This causes them both to be executed (notice "Generating static file..." being printed twice):
```
jpeterson@jpeterson:~/lucid/path-mapping-action-key-bug-repro$ bazel clean && bazel build //example:copied-file //example:copied-file-with-transition
INFO: Starting clean (this may take a while). Consider using --async if the clean takes more than several minutes.
INFO: Analyzed 2 targets (6 packages loaded, 13 targets configured).
INFO: From StaticFile example/file/output.txt:
Generating static file...
INFO: From StaticFile example/file/output.txt:
Generating static file...
INFO: Found 2 targets...
INFO: Elapsed time: 0.218s, Critical Path: 0.02s
INFO: 5 processes: 1 internal, 4 linux-sandbox.
INFO: Build completed successfully, 5 total actions
```
