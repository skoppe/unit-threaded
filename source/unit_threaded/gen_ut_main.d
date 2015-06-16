#!/usr/bin/rdmd

/**
 * Implements a program to search a list of directories
 * for all .d files, then writes a D program to run all
 * unit tests in those files using unit_threaded.
 *
 * The resulting program has a few command-line arguments,
 * the most important of which is -f to select the name
 * of the output file. Use -h to obtain help.
 */

import std.stdio;
import std.array : replace, array, join;
import std.conv : to;
import std.algorithm : map;

int main(string[] args)
{
    const options = getOptions(args);
    if (options.help || options.showVersion)
        return 0;

    writeFile(options, findModuleNames(options.dirs));

    return 0;
}

private struct Options
{
    bool verbose;
    string fileName;
    string[] dirs;
    bool help;
    bool showVersion;
}

private Options getOptions(string[] args)
{
    import std.getopt;

    Options options;
    auto getOptRes = getopt(
        args, "verbose|v", "Verbose mode.", &options.verbose,
        "file|f", "The filename to write. Will use a temporary if not set.", &options.fileName,
        "version", "Show version.", &options.showVersion,
    );

    if (getOptRes.helpWanted)
    {
        defaultGetoptPrinter("Usage: gen_ut_main [options] [test1] [test2]...", getOptRes.options);
        options.help = true;
        return options;
    }

    if (options.showVersion)
    {
        writeln("gen_ut_main version v0.2.5");
        return options;
    }

    if (options.fileName)
    {
        import std.file : exists, remove;

        if (exists(options.fileName))
            remove(options.fileName);
    }
    else
    {
        options.fileName = createFileName(); //random filename
    }

    options.dirs = args.length <= 1 ? ["tests"] : args[1 .. $];

    if (options.verbose)
    {
        writeln(__FILE__, ": finding all test cases in ", options.dirs);
    }

    return options;
}

private string createFileName()
{
    import std.random;
    import std.ascii : letters, digits;
    import std.path : buildPath, tempDir;

    immutable nameLength = uniform(10, 20);
    immutable alphanums = letters ~ digits;
    auto fileName = "" ~ letters[uniform(0, letters.length)];

    foreach (i; 0 .. nameLength)
    {
        fileName ~= alphanums[uniform(0, alphanums.length)];
    }

    return buildPath(tempDir(), fileName ~ ".d");
}

auto findModuleEntries(in string[] dirs)
{
    import std.exception : enforce;
    import std.file : DirEntry, dirEntries, isDir, SpanMode;
    import std.path : buildNormalizedPath;

    DirEntry[] modules;
    foreach (dir; dirs)
    {
        enforce(isDir(dir), dir ~ " is not a directory name");
        auto entries = dirEntries(dir, "*.d", SpanMode.depth);
        auto normalised = entries.map!(a => DirEntry(buildNormalizedPath(a.name)));
        modules ~= normalised.array;
    }

    return modules;
}

auto findModuleNames(in string[] dirs)
{
    import std.path : dirSeparator;

    //cut off extension
    return findModuleEntries(dirs).
        map!(a => replace(a.name[0 .. $ - 2], dirSeparator, ".")).
        array;
}

private auto writeFile(in Options options, in string[] modules)
{
    writeln("Writing to unit test main file ", options.fileName);
    writeln("Do not forget to use -unittest when executing ", options.fileName);

    auto wfile = File(options.fileName, "w");
    wfile.writeln("//Automatically generated by ",
        "unit_threaded.gen_ut_main, do not edit by hand");
    wfile.writeln("import std.stdio;");
    wfile.writeln("import unit_threaded;");

    wfile.writeln("");
    wfile.writeln("int main(string[] args)");
    wfile.writeln("{");
    wfile.writeln(`    writeln("\nAutomatically generated file ` ~
                  options.fileName.replace("\\", "\\\\") ~ `");`);
    wfile.writeln("    writeln(`Running unit tests from dirs " ~ options.dirs.to!string ~ "`);");

    immutable indent = "                          ";
    wfile.writeln("    return args.runTests!(\n" ~
                  modules.map!(a => indent ~ `"` ~ a ~ `"`).join(",\n") ~
                  "\n" ~ indent ~ ");");
    wfile.writeln("}");
    wfile.close();
}
