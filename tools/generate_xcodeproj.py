#!/usr/bin/env python3
"""Generate Albo.xcodeproj from the source tree.

The project used to be produced by XcodeGen, which meant you could not open the
repo in Xcode without installing a toolchain first. This writes the same project
directly so the checkout is double-clickable. project.yml is kept as the readable
description of what this builds.

Run from anywhere:  python3 tools/generate_xcodeproj.py
"""
from __future__ import annotations

import hashlib
import os
import re
import plistlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT / "ios" / "Albo"
PROJ = IOS / "Albo.xcodeproj"

APP = "Albo"
EXT = "AlboShare"
APP_BUNDLE = "com.sourcedai.albo"
EXT_BUNDLE = "com.sourcedai.albo.share"
APP_GROUP = "group.com.sourcedai.albo"
DEPLOYMENT = "17.0"
SWIFT_VERSION = "5.10"
MARKETING_VERSION = "0.1.0"
CURRENT_PROJECT_VERSION = "1"

# Files the extension compiles: it is a separate process, so it takes the
# dependency-free pieces it needs rather than linking the whole app.
EXT_SHARED_SOURCES = [
    "Albo/Shared/ShareInbox.swift",
    "Albo/Models/Models.swift",
    "Albo/DesignSystem/AlboColor.swift",
    "Albo/DesignSystem/AlboType.swift",
    "Albo/DesignSystem/Buttons.swift",
    "Albo/DesignSystem/Haptics.swift",
]


def uid(*parts: str) -> str:
    """Deterministic 24-char hex id, so regenerating produces a stable diff."""
    return hashlib.md5("::".join(parts).encode()).hexdigest()[:24].upper()


# --------------------------------------------------------------------------
# Source discovery
# --------------------------------------------------------------------------

def swift_files(folder: str) -> list[str]:
    base = IOS / folder
    return sorted(
        str(p.relative_to(IOS)).replace(os.sep, "/")
        for p in base.rglob("*.swift")
    )


APP_SOURCES = swift_files("Albo")
EXT_SOURCES = swift_files("AlboShare") + EXT_SHARED_SOURCES

APP_RESOURCES = ["Albo/Resources/Assets.xcassets"]

# Every path that needs a PBXFileReference.
ALL_PATHS = sorted(set(
    APP_SOURCES + EXT_SOURCES + APP_RESOURCES + [
        "Albo/Resources/Info.plist",
        "Albo/Resources/Albo.entitlements",
        "Albo/Resources/Albo.xcconfig",
        "Albo/Resources/Albo.storekit",
        "AlboShare/Info.plist",
        "AlboShare/AlboShare.entitlements",
    ]
))


def file_type(path: str) -> str:
    if path.endswith(".swift"):
        return "sourcecode.swift"
    if path.endswith(".xcassets"):
        return "folder.assetcatalog"
    if path.endswith(".plist"):
        return "text.plist.xml"
    if path.endswith(".entitlements"):
        return "text.plist.entitlements"
    if path.endswith(".xcconfig"):
        return "text.xcconfig"
    if path.endswith(".storekit"):
        return "text.json"
    return "text"


# --------------------------------------------------------------------------
# Info.plist and entitlements
# --------------------------------------------------------------------------

def write_plists() -> None:
    app_info = {
        "CFBundleDisplayName": "Albo",
        "CFBundleName": "$(PRODUCT_NAME)",
        "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
        "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
        "CFBundleExecutable": "$(EXECUTABLE_NAME)",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
        "CFBundleInfoDictionaryVersion": "6.0",
        "SUPABASE_URL": "$(SUPABASE_URL)",
        "SUPABASE_ANON_KEY": "$(SUPABASE_ANON_KEY)",
        "ITSAppUsesNonExemptEncryption": False,
        "UILaunchScreen": {"UIColorName": "LaunchBackground"},
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
        "UIApplicationSceneManifest": {"UIApplicationSupportsMultipleScenes": False},
        "CFBundleURLTypes": [
            {"CFBundleURLName": APP_BUNDLE, "CFBundleURLSchemes": ["albo"]}
        ],
        "NSUserTrackingUsageDescription":
            "This allows Albo to provide you with a more personalised experience and "
            "measure the effectiveness of our campaigns.",
        "NSPhotoLibraryUsageDescription":
            "Albo needs photo access to add profile pictures, review photos and screenshot imports.",
        "NSCameraUsageDescription":
            "Albo needs camera access to take profile pictures and scan QR codes.",
        "NSLocationWhenInUseUsageDescription":
            "Albo uses your location to show places near you and calculate distances to saved locations.",
        "NSLocationAlwaysAndWhenInUseUsageDescription":
            "Albo uses your location in the background to remind you when you're near a saved place.",
        "NSCalendarsWriteOnlyAccessUsageDescription":
            "Albo needs calendar access to add events to your calendar.",
        "NSContactsUsageDescription":
            "Albo uses your contacts to help you find friends on Albo.",
    }

    ext_info = {
        "CFBundleDisplayName": "Albo",
        "CFBundleName": "$(PRODUCT_NAME)",
        "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
        "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
        "CFBundleExecutable": "$(EXECUTABLE_NAME)",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
        "CFBundleInfoDictionaryVersion": "6.0",
        "NSExtension": {
            "NSExtensionPointIdentifier": "com.apple.share-services",
            "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ShareViewController",
            "NSExtensionAttributes": {
                "NSExtensionActivationRule": {
                    "NSExtensionActivationSupportsWebURLWithMaxCount": 1,
                    "NSExtensionActivationSupportsWebPageWithMaxCount": 1,
                    "NSExtensionActivationSupportsText": True,
                    "NSExtensionActivationSupportsImageWithMaxCount": 10,
                }
            },
        },
    }

    app_ent = {
        "com.apple.developer.applesignin": ["Default"],
        "com.apple.security.application-groups": [APP_GROUP],
    }
    ext_ent = {"com.apple.security.application-groups": [APP_GROUP]}

    for path, data in [
        ("Albo/Resources/Info.plist", app_info),
        ("Albo/Resources/Albo.entitlements", app_ent),
        ("AlboShare/Info.plist", ext_info),
        ("AlboShare/AlboShare.entitlements", ext_ent),
    ]:
        target = IOS / path
        target.parent.mkdir(parents=True, exist_ok=True)
        with open(target, "wb") as fh:
            plistlib.dump(data, fh, sort_keys=True)


# --------------------------------------------------------------------------
# pbxproj
# --------------------------------------------------------------------------

def build_settings(target: str, config: str) -> dict:
    common = {
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": CURRENT_PROJECT_VERSION,
        "GENERATE_INFOPLIST_FILE": "NO",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT,
        "MARKETING_VERSION": MARKETING_VERSION,
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": SWIFT_VERSION,
        "TARGETED_DEVICE_FAMILY": "1",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
    }
    if target == APP:
        common.update({
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES",
            "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES":
                "AppIcon-Browse AppIcon-King AppIcon-Reads AppIcon-Cooks AppIcon-News",
            "CODE_SIGN_ENTITLEMENTS": "Albo/Resources/Albo.entitlements",
            "INFOPLIST_FILE": "Albo/Resources/Info.plist",
            "INFOPLIST_KEY_UIUserInterfaceStyle": "Automatic",
            "PRODUCT_BUNDLE_IDENTIFIER": APP_BUNDLE,
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks",
        })
    else:
        common.update({
            "CODE_SIGN_ENTITLEMENTS": "AlboShare/AlboShare.entitlements",
            "INFOPLIST_FILE": "AlboShare/Info.plist",
            "PRODUCT_BUNDLE_IDENTIFIER": EXT_BUNDLE,
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SKIP_INSTALL": "YES",
            "LD_RUNPATH_SEARCH_PATHS":
                "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks",
        })
    if config == "Debug":
        common["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"
        common["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"
    else:
        common["SWIFT_OPTIMIZATION_LEVEL"] = "-O"
    return common


def project_settings(config: str) -> dict:
    s = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT,
        "MTL_FAST_MATH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_STRICT_CONCURRENCY": "minimal",
        "SWIFT_VERSION": SWIFT_VERSION,
        "MARKETING_VERSION": MARKETING_VERSION,
        "CURRENT_PROJECT_VERSION": CURRENT_PROJECT_VERSION,
    }
    if config == "Debug":
        s.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_TESTABILITY": "YES",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "ONLY_ACTIVE_ARCH": "YES",
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        })
    else:
        s.update({
            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
            "ENABLE_NS_ASSERTIONS": "NO",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "VALIDATE_PRODUCT": "YES",
        })
    return s


# An unquoted value in an OpenStep plist may only be a bare word. Anything with
# $(...), a leading dash, or a space has to be quoted or Xcode refuses the file.
BARE = re.compile(r"^[A-Za-z0-9_./]+$")


def quote(value: str) -> str:
    return value if BARE.match(value) else '"' + value.replace('"', '\\"') + '"'


def fmt_settings(settings: dict, indent: str) -> str:
    return "\n".join(f"{indent}{k} = {quote(settings[k])};" for k in sorted(settings))


def group_tree() -> tuple[dict, dict]:
    """Build the folder group hierarchy from ALL_PATHS. Returns (groups, child_map)."""
    groups: dict[str, list[str]] = {}   # dir path -> list of child names
    for path in ALL_PATHS:
        parts = path.split("/")
        for i in range(len(parts)):
            parent = "/".join(parts[:i])
            child = parts[i]
            groups.setdefault(parent, [])
            if child not in groups[parent]:
                groups[parent].append(child)
    return groups, {}


def generate_pbxproj() -> str:
    groups, _ = group_tree()

    file_ref = {p: uid("fileref", p) for p in ALL_PATHS}
    # Build files are per (target, path) so a shared file can belong to both targets.
    app_build = {p: uid("build", APP, p) for p in APP_SOURCES + APP_RESOURCES}
    ext_build = {p: uid("build", EXT, p) for p in EXT_SOURCES}

    ids = {
        "project": uid("project"),
        "main_group": uid("group", ""),
        "products_group": uid("group", "Products"),
        "frameworks_group": uid("group", "Frameworks"),
        "app_target": uid("target", APP),
        "ext_target": uid("target", EXT),
        "app_product": uid("product", APP),
        "ext_product": uid("product", EXT),
        "app_sources": uid("phase", APP, "sources"),
        "app_resources": uid("phase", APP, "resources"),
        "app_frameworks": uid("phase", APP, "frameworks"),
        "app_embed": uid("phase", APP, "embed"),
        "ext_sources": uid("phase", EXT, "sources"),
        "ext_frameworks": uid("phase", EXT, "frameworks"),
        "proj_conf_list": uid("conflist", "project"),
        "app_conf_list": uid("conflist", APP),
        "ext_conf_list": uid("conflist", EXT),
        "pkg_ref": uid("pkgref", "supabase"),
        "pkg_product": uid("pkgproduct", "Supabase"),
        "pkg_build": uid("build", APP, "Supabase.framework"),
        "dep": uid("dep", EXT),
        "proxy": uid("proxy", EXT),
        "embed_appex": uid("build", "embed", EXT),
    }
    for cfg in ("Debug", "Release"):
        ids[f"proj_{cfg}"] = uid("conf", "project", cfg)
        ids[f"app_{cfg}"] = uid("conf", APP, cfg)
        ids[f"ext_{cfg}"] = uid("conf", EXT, cfg)

    L: list[str] = []
    add = L.append

    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {")
    add("\t};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")
    add("")

    # ---- PBXBuildFile
    add("/* Begin PBXBuildFile section */")
    for p in APP_SOURCES:
        n = p.split("/")[-1]
        add(f"\t\t{app_build[p]} /* {n} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref[p]} /* {n} */; }};")
    for p in APP_RESOURCES:
        n = p.split("/")[-1]
        add(f"\t\t{app_build[p]} /* {n} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref[p]} /* {n} */; }};")
    for p in EXT_SOURCES:
        n = p.split("/")[-1]
        add(f"\t\t{ext_build[p]} /* {n} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref[p]} /* {n} */; }};")
    add(f"\t\t{ids['pkg_build']} /* Supabase in Frameworks */ = {{isa = PBXBuildFile; productRef = {ids['pkg_product']} /* Supabase */; }};")
    add(f"\t\t{ids['embed_appex']} /* {EXT}.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {ids['ext_product']} /* {EXT}.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};")
    add("/* End PBXBuildFile section */")
    add("")

    # ---- PBXContainerItemProxy
    add("/* Begin PBXContainerItemProxy section */")
    add(f"\t\t{ids['proxy']} /* PBXContainerItemProxy */ = {{")
    add("\t\t\tisa = PBXContainerItemProxy;")
    add(f"\t\t\tcontainerPortal = {ids['project']} /* Project object */;")
    add("\t\t\tproxyType = 1;")
    add(f"\t\t\tremoteGlobalIDString = {ids['ext_target']};")
    add(f"\t\t\tremoteInfo = {EXT};")
    add("\t\t};")
    add("/* End PBXContainerItemProxy section */")
    add("")

    # ---- PBXCopyFilesBuildPhase (embed the appex)
    add("/* Begin PBXCopyFilesBuildPhase section */")
    add(f"\t\t{ids['app_embed']} /* Embed Foundation Extensions */ = {{")
    add("\t\t\tisa = PBXCopyFilesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add('\t\t\tdstPath = "";')
    add("\t\t\tdstSubfolderSpec = 13;")
    add("\t\t\tfiles = (")
    add(f"\t\t\t\t{ids['embed_appex']} /* {EXT}.appex in Embed Foundation Extensions */,")
    add("\t\t\t);")
    add('\t\t\tname = "Embed Foundation Extensions";')
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXCopyFilesBuildPhase section */")
    add("")

    # ---- PBXFileReference
    add("/* Begin PBXFileReference section */")
    for p in ALL_PATHS:
        n = p.split("/")[-1]
        add(f'\t\t{file_ref[p]} /* {n} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type(p)}; path = {n}; sourceTree = "<group>"; }};')
    add(f'\t\t{ids["app_product"]} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    add(f'\t\t{ids["ext_product"]} /* {EXT}.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = {EXT}.appex; sourceTree = BUILT_PRODUCTS_DIR; }};')
    add("/* End PBXFileReference section */")
    add("")

    # ---- PBXFrameworksBuildPhase
    add("/* Begin PBXFrameworksBuildPhase section */")
    add(f"\t\t{ids['app_frameworks']} /* Frameworks */ = {{")
    add("\t\t\tisa = PBXFrameworksBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add(f"\t\t\t\t{ids['pkg_build']} /* Supabase in Frameworks */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add(f"\t\t{ids['ext_frameworks']} /* Frameworks */ = {{")
    add("\t\t\tisa = PBXFrameworksBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXFrameworksBuildPhase section */")
    add("")

    # ---- PBXGroup
    add("/* Begin PBXGroup section */")

    def group_id(path: str) -> str:
        return uid("group", path)

    def emit_group(path: str) -> None:
        children = groups.get(path, [])
        name = path.split("/")[-1] if path else ""
        gid = ids["main_group"] if path == "" else group_id(path)
        label = "" if path == "" else f" /* {name} */"
        add(f"\t\t{gid}{label} = {{")
        add("\t\t\tisa = PBXGroup;")
        add("\t\t\tchildren = (")
        # Folders first, then files, both alphabetical - matches how Xcode shows them.
        subdirs = [c for c in children if (path + "/" + c if path else c) in groups]
        files = [c for c in children if (path + "/" + c if path else c) not in groups]
        for c in sorted(subdirs):
            child_path = f"{path}/{c}" if path else c
            add(f"\t\t\t\t{group_id(child_path)} /* {c} */,")
        for c in sorted(files):
            child_path = f"{path}/{c}" if path else c
            add(f"\t\t\t\t{file_ref[child_path]} /* {c} */,")
        if path == "":
            add(f"\t\t\t\t{ids['products_group']} /* Products */,")
        add("\t\t\t);")
        if path != "":
            add(f"\t\t\tpath = {name};")
        add('\t\t\tsourceTree = "<group>";')
        add("\t\t};")
        for c in sorted(subdirs):
            emit_group(f"{path}/{c}" if path else c)

    emit_group("")
    add(f"\t\t{ids['products_group']} /* Products */ = {{")
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add(f"\t\t\t\t{ids['app_product']} /* {APP}.app */,")
    add(f"\t\t\t\t{ids['ext_product']} /* {EXT}.appex */,")
    add("\t\t\t);")
    add("\t\t\tname = Products;")
    add('\t\t\tsourceTree = "<group>";')
    add("\t\t};")
    add("/* End PBXGroup section */")
    add("")
    return "\n".join(L), ids, file_ref, app_build, ext_build


def generate_rest(ids, file_ref, app_build, ext_build) -> str:
    L: list[str] = []
    add = L.append

    # ---- PBXNativeTarget
    add("/* Begin PBXNativeTarget section */")
    add(f"\t\t{ids['app_target']} /* {APP} */ = {{")
    add("\t\t\tisa = PBXNativeTarget;")
    add(f"\t\t\tbuildConfigurationList = {ids['app_conf_list']} /* Build configuration list for PBXNativeTarget \"{APP}\" */;")
    add("\t\t\tbuildPhases = (")
    add(f"\t\t\t\t{ids['app_sources']} /* Sources */,")
    add(f"\t\t\t\t{ids['app_frameworks']} /* Frameworks */,")
    add(f"\t\t\t\t{ids['app_resources']} /* Resources */,")
    add(f"\t\t\t\t{ids['app_embed']} /* Embed Foundation Extensions */,")
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add(f"\t\t\t\t{ids['dep']} /* PBXTargetDependency */,")
    add("\t\t\t);")
    add(f"\t\t\tname = {APP};")
    add("\t\t\tpackageProductDependencies = (")
    add(f"\t\t\t\t{ids['pkg_product']} /* Supabase */,")
    add("\t\t\t);")
    add(f"\t\t\tproductName = {APP};")
    add(f"\t\t\tproductReference = {ids['app_product']} /* {APP}.app */;")
    add('\t\t\tproductType = "com.apple.product-type.application";')
    add("\t\t};")
    add(f"\t\t{ids['ext_target']} /* {EXT} */ = {{")
    add("\t\t\tisa = PBXNativeTarget;")
    add(f"\t\t\tbuildConfigurationList = {ids['ext_conf_list']} /* Build configuration list for PBXNativeTarget \"{EXT}\" */;")
    add("\t\t\tbuildPhases = (")
    add(f"\t\t\t\t{ids['ext_sources']} /* Sources */,")
    add(f"\t\t\t\t{ids['ext_frameworks']} /* Frameworks */,")
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add("\t\t\t);")
    add(f"\t\t\tname = {EXT};")
    add(f"\t\t\tproductName = {EXT};")
    add(f"\t\t\tproductReference = {ids['ext_product']} /* {EXT}.appex */;")
    add('\t\t\tproductType = "com.apple.product-type.app-extension";')
    add("\t\t};")
    add("/* End PBXNativeTarget section */")
    add("")

    # ---- PBXProject
    add("/* Begin PBXProject section */")
    add(f"\t\t{ids['project']} /* Project object */ = {{")
    add("\t\t\tisa = PBXProject;")
    add("\t\t\tattributes = {")
    add("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    add("\t\t\t\tLastSwiftUpdateCheck = 1600;")
    add("\t\t\t\tLastUpgradeCheck = 1600;")
    add("\t\t\t\tTargetAttributes = {")
    add(f"\t\t\t\t\t{ids['app_target']} = {{")
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    add("\t\t\t\t\t};")
    add(f"\t\t\t\t\t{ids['ext_target']} = {{")
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    add("\t\t\t\t\t};")
    add("\t\t\t\t};")
    add("\t\t\t};")
    add(f"\t\t\tbuildConfigurationList = {ids['proj_conf_list']} /* Build configuration list for PBXProject \"{APP}\" */;")
    add("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    add("\t\t\tdevelopmentRegion = en;")
    add("\t\t\thasScannedForEncodings = 0;")
    add("\t\t\tknownRegions = (")
    add("\t\t\t\ten,")
    add("\t\t\t\tBase,")
    add("\t\t\t);")
    add(f"\t\t\tmainGroup = {ids['main_group']};")
    add("\t\t\tpackageReferences = (")
    add(f"\t\t\t\t{ids['pkg_ref']} /* XCRemoteSwiftPackageReference \"supabase-swift\" */,")
    add("\t\t\t);")
    add(f"\t\t\tproductRefGroup = {ids['products_group']} /* Products */;")
    add('\t\t\tprojectDirPath = "";')
    add('\t\t\tprojectRoot = "";')
    add("\t\t\ttargets = (")
    add(f"\t\t\t\t{ids['app_target']} /* {APP} */,")
    add(f"\t\t\t\t{ids['ext_target']} /* {EXT} */,")
    add("\t\t\t);")
    add("\t\t};")
    add("/* End PBXProject section */")
    add("")

    # ---- PBXResourcesBuildPhase
    add("/* Begin PBXResourcesBuildPhase section */")
    add(f"\t\t{ids['app_resources']} /* Resources */ = {{")
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for p in APP_RESOURCES:
        add(f"\t\t\t\t{app_build[p]} /* {p.split('/')[-1]} in Resources */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXResourcesBuildPhase section */")
    add("")

    # ---- PBXSourcesBuildPhase
    add("/* Begin PBXSourcesBuildPhase section */")
    add(f"\t\t{ids['app_sources']} /* Sources */ = {{")
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for p in APP_SOURCES:
        add(f"\t\t\t\t{app_build[p]} /* {p.split('/')[-1]} in Sources */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add(f"\t\t{ids['ext_sources']} /* Sources */ = {{")
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for p in EXT_SOURCES:
        add(f"\t\t\t\t{ext_build[p]} /* {p.split('/')[-1]} in Sources */,")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXSourcesBuildPhase section */")
    add("")

    # ---- PBXTargetDependency
    add("/* Begin PBXTargetDependency section */")
    add(f"\t\t{ids['dep']} /* PBXTargetDependency */ = {{")
    add("\t\t\tisa = PBXTargetDependency;")
    add(f"\t\t\ttarget = {ids['ext_target']} /* {EXT} */;")
    add(f"\t\t\ttargetProxy = {ids['proxy']} /* PBXContainerItemProxy */;")
    add("\t\t};")
    add("/* End PBXTargetDependency section */")
    add("")

    # ---- XCBuildConfiguration
    xcconfig_ref = file_ref["Albo/Resources/Albo.xcconfig"]
    add("/* Begin XCBuildConfiguration section */")
    for cfg in ("Debug", "Release"):
        add(f"\t\t{ids[f'proj_{cfg}']} /* {cfg} */ = {{")
        add("\t\t\tisa = XCBuildConfiguration;")
        add(f"\t\t\tbaseConfigurationReference = {xcconfig_ref} /* Albo.xcconfig */;")
        add("\t\t\tbuildSettings = {")
        add(fmt_settings(project_settings(cfg), "\t\t\t\t"))
        add("\t\t\t};")
        add(f"\t\t\tname = {cfg};")
        add("\t\t};")
    for target, key in ((APP, "app"), (EXT, "ext")):
        for cfg in ("Debug", "Release"):
            add(f"\t\t{ids[f'{key}_{cfg}']} /* {cfg} */ = {{")
            add("\t\t\tisa = XCBuildConfiguration;")
            add("\t\t\tbuildSettings = {")
            add(fmt_settings(build_settings(target, cfg), "\t\t\t\t"))
            add("\t\t\t};")
            add(f"\t\t\tname = {cfg};")
            add("\t\t};")
    add("/* End XCBuildConfiguration section */")
    add("")

    # ---- XCConfigurationList
    add("/* Begin XCConfigurationList section */")
    for label, key, owner in (
        (f'PBXProject "{APP}"', "proj", None),
        (f'PBXNativeTarget "{APP}"', "app", APP),
        (f'PBXNativeTarget "{EXT}"', "ext", EXT),
    ):
        add(f"\t\t{ids[f'{key}_conf_list']} /* Build configuration list for {label} */ = {{")
        add("\t\t\tisa = XCConfigurationList;")
        add("\t\t\tbuildConfigurations = (")
        add(f"\t\t\t\t{ids[f'{key}_Debug']} /* Debug */,")
        add(f"\t\t\t\t{ids[f'{key}_Release']} /* Release */,")
        add("\t\t\t);")
        add("\t\t\tdefaultConfigurationIsVisible = 0;")
        add("\t\t\tdefaultConfigurationName = Release;")
        add("\t\t};")
    add("/* End XCConfigurationList section */")
    add("")

    # ---- Swift package
    add("/* Begin XCRemoteSwiftPackageReference section */")
    add(f'\t\t{ids["pkg_ref"]} /* XCRemoteSwiftPackageReference "supabase-swift" */ = {{')
    add("\t\t\tisa = XCRemoteSwiftPackageReference;")
    add('\t\t\trepositoryURL = "https://github.com/supabase/supabase-swift";')
    add("\t\t\trequirement = {")
    add("\t\t\t\tkind = upToNextMajorVersion;")
    add("\t\t\t\tminimumVersion = 2.20.0;")
    add("\t\t\t};")
    add("\t\t};")
    add("/* End XCRemoteSwiftPackageReference section */")
    add("")
    add("/* Begin XCSwiftPackageProductDependency section */")
    add(f"\t\t{ids['pkg_product']} /* Supabase */ = {{")
    add("\t\t\tisa = XCSwiftPackageProductDependency;")
    add(f'\t\t\tpackage = {ids["pkg_ref"]} /* XCRemoteSwiftPackageReference "supabase-swift" */;')
    add("\t\t\tproductName = Supabase;")
    add("\t\t};")
    add("/* End XCSwiftPackageProductDependency section */")
    add("\t};")
    add(f"\trootObject = {ids['project']} /* Project object */;")
    add("}")
    add("")
    return "\n".join(L)


SCHEME = """<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{blueprint}"
               BuildableName = "{buildable}"
               BlueprintName = "{target}"
               ReferencedContainer = "container:Albo.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">{storekit}
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{blueprint}"
            BuildableName = "{buildable}"
            BlueprintName = "{target}"
            ReferencedContainer = "container:Albo.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{blueprint}"
            BuildableName = "{buildable}"
            BlueprintName = "{target}"
            ReferencedContainer = "container:Albo.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

STOREKIT_BLOCK = """
      <StoreKitConfigurationFileReference
         identifier = "../../../Albo/Resources/Albo.storekit">
      </StoreKitConfigurationFileReference>"""

WORKSPACE = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

WORKSPACE_SETTINGS = {
    "IDEDidComputeMac32BitWarning": True,
}


def main() -> None:
    write_plists()

    body, ids, file_ref, app_build, ext_build = generate_pbxproj()
    text = body + "\n" + generate_rest(ids, file_ref, app_build, ext_build)

    if PROJ.exists():
        shutil.rmtree(PROJ)
    (PROJ / "project.xcworkspace" / "xcshareddata").mkdir(parents=True, exist_ok=True)
    (PROJ / "xcshareddata" / "xcschemes").mkdir(parents=True, exist_ok=True)

    (PROJ / "project.pbxproj").write_text(text, encoding="utf-8")
    (PROJ / "project.xcworkspace" / "contents.xcworkspacedata").write_text(WORKSPACE, encoding="utf-8")
    with open(PROJ / "project.xcworkspace" / "xcshareddata" / "IDEWorkspaceChecks.plist", "wb") as fh:
        plistlib.dump(WORKSPACE_SETTINGS, fh)

    for target, blueprint, buildable, storekit in (
        (APP, ids["app_target"], f"{APP}.app", STOREKIT_BLOCK),
        (EXT, ids["ext_target"], f"{EXT}.appex", ""),
    ):
        scheme = SCHEME.format(
            blueprint=blueprint, buildable=buildable, target=target, storekit=storekit
        )
        (PROJ / "xcshareddata" / "xcschemes" / f"{target}.xcscheme").write_text(scheme, encoding="utf-8")

    print(f"Wrote {PROJ.relative_to(ROOT)}")
    print(f"  app sources: {len(APP_SOURCES)}  extension sources: {len(EXT_SOURCES)}")


if __name__ == "__main__":
    main()
