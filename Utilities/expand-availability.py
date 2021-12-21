#!/usr/bin/env python3

# This script can be used to automatically add/remove `@available` attributes to
# declarations in Swift sources in this package.
#
# In order for this to work, ABI-impacting declarations need to be annotated
# with special comments in the following format:
#
#     /*System 0.0.2*/
#     public func greeting() -> String {
#       "Hello"
#     }
#
# The script adds full availability incantations to these comments. It can run
# in one of two modes:
#
# By default, `expand-availability.py` expands availability macros within the
# comments. This is useful during package development to cross-reference
# availability across `SystemPackage` and the ABI-stable `System` module that
# ships in Apple's OS releases:
#
#     /*System 0.0.2, @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)*/
#     public func greeting() -> String {
#       "Hello"
#     }
#
# `expand-availability.py --attributes` adds actual availability attributes.
# This is used by maintainers to build ABI stable releases of System on Apple's
# platforms:
#
#     /*System 0.0.2*/@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
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
    "System 1.1.0": "macOS 9999, iOS 9999, watchOS 9999, tvOS 9999",
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

macro_pattern = re.compile(
    r"/\*(System [^ *]+)(, @available\([^)]*\))?\*/(@available\([^)]*\))?")

sources = swift_sources_in("Sources") + swift_sources_in("Tests")
for line in fileinput.input(files=sources, inplace=True):
    match = re.search(macro_pattern, line)
    if match:
        system_version = match.group(1)
        expansion = versions[system_version]
        if expansion is None:
            raise ValueError("{0}:{1}: error: Unknown System version '{0}'"
                             .format(fileinput.filename(), fileinput.lineno(),
                                     system_version))
        if args.attributes:
            replacement = "/*{0}*/@available({1}, *)".format(system_version, expansion)
        else:
            replacement = "/*{0}, @available({1}, *)*/".format(system_version, expansion)
        line = line[:match.start()] + replacement + line[match.end():]
    print(line, end="")
