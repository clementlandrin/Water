import haxe.io.Eof;
import haxe.io.Path;
import sys.FileSystem;
import haxe.Json;

class CommitChecker {

    static var extToScan : Array<String> = ["prefab", "l3d", "fx", "cdb"];
    static var ignoreList = [
        "environment/resource/res/data.cdb"
    ];
    static var extOfDependencies : Array<String> = ["fbx", "jpg", "png", "fx", "prefab", "wav"];

    // Return all paths in a JSON that has an valid extension (in extOfDependencies)
    static function recGetFiles(json : Dynamic) : Array<String> {
        var paths : Array<String> = [];
        var fields = Reflect.fields(json);
        for (f in fields) {
            var elt : Dynamic = Reflect.field(json, f);

            function parseJSONObject(o) {
                var rec = recGetFiles(o);
                for (r in rec) {
                    if (paths.indexOf(r) == -1) {
                        paths.push(r);
                    }
                }
            }

            if (Std.isOfType(elt, Array)) {
                var array : Array<Dynamic> = elt;
                for (e in array) {
                    parseJSONObject(e);
                }
            } else if (Std.isOfType(elt, String)) {
                var value : String = elt;
                for (ext in extOfDependencies) {
                    var indexExt = value.toLowerCase().lastIndexOf("." + ext);
                    if (indexExt != -1 && indexExt == value.length - ext.length - 1) {
                        paths.push(value);
                        break;
                    }
                }
            } else {
                parseJSONObject(elt);
            }
        }
        return paths;
    }

    static function isIgnored(f: String) {
        for(i in ignoreList) {
            if(f.indexOf(i) >= 0) return true;
        }
        return false;
    }


    static function main() {
        var args = Sys.args();

        var listOfFilesCommit = sys.io.File.read(args[0], false);
        // get working root path : second line of svn info
        var resFolder = Sys.programPath();
        resFolder = resFolder.substring(0, resFolder.indexOf("\\tools")) + "\\res";

        var hasErrors = false;
        var filesToCheckIfCommit : Array<String> = [];
        var filesCommitted : Array<String> = [];

        // parsing "svn status" command
        var svnStatusUnknown : Array<String> = [];
        var svnStatusAdded : Array<String> = [];
        var svnStatusDeleted : Array<String> = [];
        var svnRes = new sys.io.Process("svn status " + resFolder).stdout;
        var line = null;
        try {
            while ( (line = svnRes.readLine()) != null ) {
                var lineSplitted = line.split(" ");
                if (lineSplitted[0] == "A") {
                    svnStatusAdded.push(lineSplitted[lineSplitted.length-1]);
                } else if (lineSplitted[0] == "D") {
                    svnStatusDeleted.push(lineSplitted[lineSplitted.length-1]);
                } else if (lineSplitted[0] != "M") {
                    svnStatusUnknown.push(lineSplitted[lineSplitted.length-1]);
                }
            }
        } catch (e : Eof) {

        }

        var errFile = sys.io.File.write(Path.directory(Sys.programPath()) + "/error.log");

        function writeError(str: String) {
            errFile.writeString(str);
            Sys.stderr().writeString(str);
        }

        try {
            var filepath = null;
            while ( (filepath = listOfFilesCommit.readLine()) != null ) {

                if (svnStatusDeleted.indexOf(FileSystem.fullPath(filepath)) != -1) {
                    continue;
                }
                var normPath = filepath.toLowerCase().split("\\").join("/");
                writeError(normPath);
                if(isIgnored(normPath)) continue;

                filesCommitted.push(filepath.substring(resFolder.length+1));

                var fileToScan = false;
                for (ext in extToScan) {
                    var indexExt = normPath.lastIndexOf("." + ext);
                    if (indexExt != -1 && indexExt == filepath.length - ext.length - 1) {
                        fileToScan = true;
                        break;
                    }
                }
                if (!fileToScan) {
                    continue;
                }

                try {
                    var json : Dynamic = Json.parse(sys.io.File.getContent(filepath));
                    var dependencies = recGetFiles(json);

                    for (file in dependencies) {
                        var resPath = FileSystem.fullPath(resFolder + '\\' + file);

                        if (FileSystem.exists(resPath)) {
                            if (svnStatusUnknown.indexOf(resPath) != -1) {
                                writeError(file + " is not added.\n");
                                hasErrors = true;
                            } else {
                                if (svnStatusAdded.indexOf(resPath) != -1) {
                                    filesToCheckIfCommit.push(file); // added but not necessarily include in this commit
                                } else {
                                    function parentIsUnknown(path : String) : Bool {
                                        var parent = path.substring(0, path.lastIndexOf("\\"));
                                        if (parent == resFolder) {
                                            return false;
                                        }
                                        if (svnStatusUnknown.indexOf(parent) != -1) {
                                            return true;
                                        }
                                        return parentIsUnknown(parent);
                                    }
                                    if (parentIsUnknown(resPath)) {
                                        writeError(file + " is not added.\n");
                                        hasErrors = true;
                                    }
                                }
                            }
                        } else {

                            writeError('$resPath does not exist (referenced by ${Path.withoutDirectory(filepath)})\n');
                            hasErrors = true;
                        }
                    }
                } catch (e : Dynamic) {
                    if (FileSystem.exists(filepath)) {
                        writeError("Error while parsing " + filepath + "\n");
                        hasErrors = true;
                    }
                }

            }
        } catch (e : Dynamic) {
            // end of file
        }

        for (f in filesToCheckIfCommit) {
            if (filesCommitted.indexOf(f) == -1) {
                writeError(f + " is not commited.\n");
                hasErrors = true;
            }
        }

        errFile.close();

        if (hasErrors) {
            Sys.exit(1);
        }
    }
}