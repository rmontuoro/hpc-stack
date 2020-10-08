help([[
]])

local pkgName    = myModuleName()
local pkgVersion = myModuleVersion()
local pkgNameVer = myModuleFullName()

local hierA        = hierarchyA(pkgNameVer,2)
local mpiNameVer   = hierA[1]
local compNameVer  = hierA[2]
local mpiNameVerD  = mpiNameVer:gsub("/","-")
local compNameVerD = compNameVer:gsub("/","-")

conflict(pkgName)

local opt = os.getenv("HPC_OPT") or os.getenv("OPT") or "/opt/modules"

local base = pathJoin(opt,compNameVerD,mpiNameVerD,pkgName,pkgVersion)

prepend_path("CMAKE_MODULE_PATH", pathJoin(base, "share/MAPL/cmake"), ";")
prepend_path("CMAKE_PREFIX_PATH", base, ";")

setenv("MAPL_ROOT", base)
setenv("MAPL_INCLUDES", pathJoin(base,"include"))
setenv("MAPL_LIBS", pathJoin(base,"lib"))
setenv("MAPL_VERSION", pkgVersion)

whatis("Name: ".. pkgName)
whatis("Version: " .. pkgVersion)
whatis("Category: library")
whatis("Description: NASA MAPL library")
