# WADTools Test Ideas #

## 25-INIFile.t ##
Current tests:
- Creating an _INIFile_ object with bogus file causes _INIFile_ to die
  - There's a check in the `filename` attribute for a valid file
- Creating an _INIFile_ object with a valid file causes the _INIFile_ object
  to be returned to the caller
- Calling `read_ini_config` on the valid _INIFile_ object returns a
  _Config::Ѕtd_ object

Test ideas:
- Write tests for all methods in the _INIFile_ object

vim: filetype=markdown shiftwidth=2 tabstop=2
