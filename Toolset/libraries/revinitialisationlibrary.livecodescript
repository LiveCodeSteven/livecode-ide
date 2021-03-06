﻿script "revinitialisationlibrary"
// A array that stores whether a library is loaded
// sLoadedLibraries["library name"] = true
local sLoadedLibraries

command revInternal__LoadLibrary pLibrary
   // Create the path to the library file. Assumption is made that the directory, file and stack name are all the same.
   //set the itemdel to "/"
   
   -- SN-2015-02-20: Linux uses case-sensitive filenames, so we
   --  follow the lower-case naming of the library names
   put toLower(pLibrary) into pLibrary
   
   if sLoadedLibraries[pLibrary] is not empty then
      return "Library" && pLibrary && "already loaded as" && sLoadedLibraries[pLibrary]
   end if
   
   // AL-2015-02-20: [[ IDE Restructure ]] Look for libraries in the correct locations.
   set the itemDelimiter to "."
   if the environment begins with "development" then
      local tLibraryPath, tLibSuffix
      
      if not revEnvironmentIsInstalled() then
         -- look for libraries in parent repository
         if there is a file (revEnvironmentRepositoryPath() & "/ide-support/" & pLibrary & ".livecodescript") then
            put revEnvironmentRepositoryPath() & "/ide-support/" & pLibrary & ".livecodescript" into tLibraryPath
         else 
            put the last item of pLibrary into tLibSuffix
            if there is a file (revEnvironmentRepositoryPath() & "/extensions/script-libraries/" & tLibSuffix & slash & tLibSuffix & ".livecodescript") then
               put revEnvironmentRepositoryPath() & "/extensions/script-libraries/" & tLibSuffix & slash & tLibSuffix & ".livecodescript" into tLibraryPath
            end if
         end if
      end if
      
      if tLibraryPath is empty then
         if there is a file (revEnvironmentToolsetPath() & "/libraries/" & pLibrary & ".livecodescript") then 
            put revEnvironmentToolsetPath() & "/libraries/" & pLibrary & ".livecodescript" into tLibraryPath
         else
            put the last item of pLibrary into tLibSuffix
            if there is a file (revEnvironmentToolsetPath() & "/libraries/" & tLibSuffix & slash & tLibSuffix & ".livecodescript") then
               put revEnvironmentToolsetPath() & "/libraries/" & tLibSuffix & slash & tLibSuffix & ".livecodescript" into tLibraryPath
            end if
         end if
      end if
      set the itemDelimiter to comma
      
      if tLibraryPath is empty then
         answer "no file for library" && pLibrary
      end if
      
      try
         // Get its name
         local tStackName
         put the name of stack tLibraryPath into tStackName
         send "revLoadLibrary" to stack tStackName
         put tStackName into sLoadedLibraries[pLibrary]
         return true
      catch tError
         answer "Error while loading stack:" && tLibraryPath
      end try
      
   else
      try
         send "revLoadLibrary" to stack pLibrary
      catch tError
         write ("Error" && tError && "while loading stack:" && pLibrary) to stderr
      end try
   end if
end revInternal__LoadLibrary

command revInternal__LoadIfLibrary pLibrary
   try
      if the revAvailableHandlers of stack pLibrary contains "revLoadLibrary" then
         send "revLoadLibrary" to stack pLibrary
         local tStackName
         put the name of stack pLibrary into tStackName
         put tStackName into sLoadedLibraries[pLibrary]
         return true
      end if
   end try
   delete stack pLibrary
   return false
end revInternal__LoadIfLibrary

command revInternal__UnloadLibrary pLibraryName
   // Check if the library is loaded
   if sLoadedLibraries[pLibraryName] is empty then
      return "Library not loaded"
   end if
   
   local tStackName
   put sLoadedLibraries[pLibraryName] into tStackName
   if there is not a stack tStackName then return "library not loaded"
   
   try
      // Request the library shuts down
      send "revUnloadLibrary" to stack tStackName
      
      delete variable sLoadedLibraries[pLibraryName]
      
      return true
   catch tError
      return "Error while unloading library. Library" && pLibraryName && "did not complete the reVUnloadLibrary request"
   end try
end revInternal__UnloadLibrary

function revInternal__ListLoadedLibraries
   local tLibs
   put the keys of sLoadedLibraries into tLibs
   sort tLibs
   return tLibs
end revInternal__ListLoadedLibraries

command revInternal__SetAppIcon pAppIcon
   global gRevAppIcon
   set the paintCompression to "png" -- match the engine
   put pAppIcon into gRevAppIcon
end revInternal__SetAppIcon

command revInternal__SetSmallAppIcon pSmallAppIcon
   global gRevSmallAppIcon
   set the paintCompression to "png" -- match the engine
   put pSmallAppIcon into gRevSmallAppIcon
end revInternal__SetSmallAppIcon
