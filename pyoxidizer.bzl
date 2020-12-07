def make_dist():
    return default_python_distribution()

def make_packaging_policy(dist):
    policy = dist.make_python_packaging_policy()
    policy.resources_location = "filesystem-relative:lib"
    policy.allow_files = True
    policy.bytecode_optimize_level_zero = True
    
    #policy.include_distribution_sources = True
    #policy.include_distribution_resources = False
    #policy.include_non_distribution_sources = False
    #policy.include_test = False
    
    return policy

def make_client(dist, policy):
    python_config = dist.make_python_interpreter_config()
    python_config.filesystem_importer = True
    python_config.sys_frozen = True
    python_config.run_filename = "client.py"
    
    client = dist.to_python_executable(
        name="client",
        packaging_policy=policy,
        config=python_config,
    )
    client.add_python_resources(client.pip_install(["--only-binary=:all:", "-r", "pyoxidizer-download-requirements.txt"]))
    client.add_python_resources(client.pip_install(["--prefer-binary", "-r", "pyoxidizer-install-requirements.txt"]))
    
    if "darwin" in BUILD_TARGET_TRIPLE:
        client.add_python_resources(client.pip_install(["--platform=macosx_10_13_intel", "--only-binary=:all:", "PySide2>=5.15.0"]))
    elif "windows" in BUILD_TARGET_TRIPLE:
        client.add_python_resources(client.pip_install(["--platform=none-win_amd64", "--only-binary=:all:", "PySide2>=5.15.0"]))
    elif "linux" in BUILD_TARGET_TRIPLE:
        client.add_python_resources(client.pip_install(["--platform=manylinux1_x86_64", "--only-binary=:all:", "PySide2>=5.15.0"]))
    else:
        print("valid target not recognized in".format(BUILD_TARGET_TRIPLE))
        sys.exit(1)

    client.add_python_resources(client.read_package_root(
        path=".",
        packages=["hydrus"],
    ))
    
    return client

def make_embedded_resources(client):
    return client.to_embedded_resources()

def make_install(client, resources):
    files = FileManifest()
    files.add_python_resource(".", client)

    static_resources = glob(["./*.py", "./*.md", "./*txt", "./static/**/*", "./help/**/*"], strip_prefix="{}/".format(CWD))
    files.add_manifest(static_resources)
#    files.add_manifest(resources)

    return files

print(BUILD_TARGET_TRIPLE)
print(CWD)

# Tell PyOxidizer about the build targets defined above.
register_target("dist", make_dist)
register_target("policy", make_packaging_policy, depends=["dist"])
register_target("client", make_client, depends=["dist", "policy"])
register_target("resources", make_embedded_resources, depends=["client"], default_build_script=True)
register_target("install", make_install, depends=["client", "resources"], default=True)

resolve_targets()

# END OF COMMON USER-ADJUSTED SETTINGS.
#
# Everything below this is typically managed by PyOxidizer and doesn't need
# to be updated by people.

PYOXIDIZER_VERSION = "0.10.3"
PYOXIDIZER_COMMIT = "UNKNOWN"
