// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import atpkg

extension ExternalDependency {
    var shouldInclude: Bool {
        
        guard let includes = self.ifIncluding else { return true }
        for tag in includes {
            if cliIncludes(string: "\(self.package.name).\(tag)") { return true }
        }
        return false
    }
}

///determine if the user passed --include foo
private func cliIncludes(string: String) -> Bool {
    for (x,arg) in CommandLine.arguments.enumerated() {
        if arg == "--include" {
            if CommandLine.arguments[x+1] == string {
                return true
            }
        }
    }
    return false
}