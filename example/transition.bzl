def _dummy_transition_impl(settings, attr):
    return {} if attr.dummy_setting == "" else {
        "//example:dummy-setting": attr.dummy_setting
    }

dummy_transition = transition(
    implementation = _dummy_transition_impl,
    inputs = [],
    outputs = ["//example:dummy-setting"],
)
