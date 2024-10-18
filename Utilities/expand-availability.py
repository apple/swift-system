#!/usr/bin/env python3

# This script can be used to automatically add/remove `@available` attributes to
# declarations in Swift sources in this package.
#
# In order for this to work, ABI-impacting declarations need to be annotated
# with special comments in the following format:
#
#     @available(/*System 0.0.2*/iOS 8, *)
#     public func greeting() -> String {
#       "Hello"
#     }
#
# (The iOS 8 availability is a dummy no-op declaration -- it only has to be
# there because `@available(*)` isn't valid syntax, and commenting out the
# entire `@available` attribute would interfere with parser tools for doc
# comments. `iOS 8` is the shortest version string that matches the minimum
# possible deployment target for Swift code, so we use that as our dummy
# availability version. `@available(iOS 8, *)` is functionally equivalent to not
# having an `@available` attribute at all.)
#
# The script adds full availability incantations to these comments. It can run
# in one of two modes:
#
# By default, `expand-availability.py` expands availability macros within the
# comments. This is useful during package development to cross-reference
# availability across `SystemPackage` and the ABI-stable `System` module that
# ships in Apple's OS releases:
#
#     @available(/*System 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
#     public func greeting() -> String {
#       "Hello"
#     }
#
# `expand-availability.py --attributes` adds actual availability declarations.
# This is used by maintainers to build ABI stable releases of System on Apple's
# platforms:
#
#     @available(/*System 0.0.2: */macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
#     public func greeting() -> String {
#       "Hello"
#     }
#
# The script recognizes all three forms of these annotations and updates them on
# every run, so we can run the script to enable/disable attributes as needed.

import os
import os.path
import fileinput
import re
import sys
import argparse

versions = {
    "System 0.0.1": "macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0",
    "System 0.0.2": "macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0",
    "System 1.1.0": "macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4",
    "System 1.2.0": "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999",
    "System 1.3.0": "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999",
    "System 1.4.0": "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999",
}

parser = argparse.ArgumentParser(description="Expand availability macros.")
parser.add_argument("--attributes", help="Add @available attributes",
                    action="store_true")
args = parser.parse_args()

def swift_sources_in(path):
    result = []
    for (dir, _, files) in os.walk(path):
        for file in files:
            extension = os.path.splitext(file)[1]
            if extension == ".swift":
                result.append(os.path.join(dir, file))
    return result

# Old-style syntax:
# /*System 0.0.2*/
# /*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
# /*System 0.0.2*/@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
old_macro_pattern = re.compile(
    r"/\*(System [^ *]+)(, @available\([^)]*\))?\*/(@available\([^)]*\))?")

# New-style comments:
# @available(/*SwiftSystem 0.0.2*/macOS 10, *)
# @available(/*SwiftSystem 0.0.2: macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0*/iOS 8, *)
# @available(/*SwiftSystem 0.0.2*/macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
#
# These do not interfere with our tools' ability to find doc comments.
macro_pattern = re.compile(
    r"@available\(/\*(System [^ *:]+)[^*/)]*\*/([^)]*)\*\)")

def available_attribute(filename, lineno, symbolic_version):
    expansion = versions[symbolic_version]
    if expansion is None:
        raise ValueError("{0}:{1}: error: Unknown System version '{0}'"
            .format(fileinput.filename(), fileinput.lineno(), symbolic_version))
    if args.attributes:
        attribute = "@available(/*{0}*/{1}, *)".format(symbolic_version, expansion)
    else:
        # Sadly `@available(*)` is not valid syntax, so we have to mention at
        # least one actual platform here.
        attribute = "@available(/*{0}: {1}*/iOS 8, *)".format(symbolic_version, expansion)
    return attribute


sources = swift_sources_in("Sources") + swift_sources_in("Tests")
for line in fileinput.input(files=sources, inplace=True):
    match = re.search(macro_pattern, line)
    if match is None:
        match = re.search(old_macro_pattern, line)
    if match:
        symbolic_version = match.group(1)
        replacement = available_attribute(
            fileinput.filename(), fileinput.lineno(), symbolic_version)
        line = line[:match.start()] + replacement + line[match.end():]
    print(line, end="")
