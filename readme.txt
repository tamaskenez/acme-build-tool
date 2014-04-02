You can set the environment variable ACME_ROOT to this directory to use these features:
- Copy the file acme.config.default.cmake to this directory,
  rename it to acme.config.cmake and modify it to change global settings
- if the ACME_AUTO_UPDATE is true (see acme.config.[default.]cmake)
  the entire acme installation will be update on every cmake config