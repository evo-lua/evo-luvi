
local LuviApp = {}

function LuviApp:CreateFromFolder(base)

end

function LuviApp:CreateFromZipFile(base, zip)

end

function LuviApp:InsertPrefix(prefix)

end

function LuviApp:MakeZipApp(target)

end

function LuviApp:MergeMultipleFileSystems(bundles) end

function LuviApp:CreateMergedFileSystem(bundlePaths) end

function LuviApp:RunWithArguments(bundlePaths, mainPath, args) end


-- VFS
function LuviApp:GetFileSystemAttributes(path)

end

-- VFS
function LuviApp:ReadFile(path)

end

-- VFS
function LuviApp:ReadDirectory(path)

end


-- VFS
function LuviApp:RegisterPreloadedModule(name, path)

end

-- VFS
function LuviApp:ApplyAction(path, action, ...)

end


return LuviApp