load(":transition.bzl", "dummy_transition")

def _static_file_impl(ctx):
    output = ctx.actions.declare_file("{}/output.txt".format(ctx.label.name))
    arguments = ctx.actions.args()
    arguments.add(ctx.attr.content)
    arguments.add(output)

    ctx.actions.run_shell(
        arguments = [arguments],
        command = "echo 'Generating static file...'; echo \"$1\" > \"$2\"",
        execution_requirements = {
            "supports-path-mapping": "1",
        },
        mnemonic = "StaticFile",
        outputs = [output],
    )

    return DefaultInfo(files = depset([output]))

static_file = rule(
    attrs = {
        "content": attr.string(mandatory = True),
    },
    implementation = _static_file_impl,
)

def _copy_file_impl(ctx):
    output = ctx.actions.declare_file("{}/{}.copy".format(ctx.label.name, ctx.file.input.basename))
    arguments = ctx.actions.args()
    arguments.add(ctx.file.input)
    arguments.add(output)

    ctx.actions.run(
        arguments = [arguments],
        executable = "cp",
        execution_requirements = {
            "supports-path-mapping": "1",
        },
        inputs = [ctx.file.input],
        mnemonic = "CopyFile",
        outputs = [output],
    )

    return DefaultInfo(files = depset([output]))

copy_file = rule(
    attrs = {
        "dummy_setting": attr.string(),
        "input": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
    },
    cfg = dummy_transition,
    implementation = _copy_file_impl,
)
